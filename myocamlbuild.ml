open Ocamlbuild_plugin
open Command

let read_lines file =
  let chan = open_in file in
  let rec aux l =
    try
      let s=input_line chan in
      if s="" then aux l
      else aux (s::l)
    with End_of_file -> l in
  aux []

let type_mli_file = ref []

let _ =
  let derive_file_list ext =
    rule ("my derive "^" "^ext)
      ~dep:("%(name)"-.-ext)
      ~prod:("%(name)_%(suffix:<*> and not <*_*>)"-.-ext)
      (fun env build ->
	      let name = env "%(name)" in
	      let l = read_lines (name-.-ext) in
	      let init = List.fold_left (fun acc pkg ->
            let aux acc pkg =
              let dir = Pathname.normalize (Filename.dirname pkg) in
	            let dir = if dir="" then dir else dir^"/" in
              let dir =
                if dir = "src/type_mli/" then begin
                  type_mli_file := Filename.basename pkg::!type_mli_file;
                  "src/"
                end else dir
              in
	            let x = dir^(env "%(suffix)")^"/"^(Filename.basename pkg)^"\n" in
              if List.mem x acc then acc else x::acc
            in
            aux acc pkg) [] l
        in
        Echo (init,(env ("%(name)_%(suffix)"-.-ext)))
      )
  in
  List.iter derive_file_list [ "mlpack" ]

let copy_with_header src prod =
  let dir = Filename.dirname prod in
  let mkdir = Cmd (Sh ("mkdir -p " ^ dir)) in
  let contents = Pathname.read src in
  let header = "# 1 \""^src^"\"\n" in
  (* Printf.printf "copy %s -> %s\n" src prod; *)
  Seq [mkdir;Echo ([header;contents],prod)]

let copy_rule_with_header ?(deps=[]) src prod =
  let name = Printf.sprintf "%s -> %s" src prod in
  (* Printf.printf "copy %s -> %s\n" src prod; *)
  rule name ~deps:(src::deps) ~prod
    (fun env _ ->
      let prod = env prod in
      let src = env src in
      copy_with_header src prod)


(**** .TYPE_MLI ****)

let infer_interface ml type_mli env build =
  let ml = env ml and mli = env type_mli in
  let tags = tags_of_pathname ml++"ocaml" in
  Ocamlbuild_pack.Ocaml_compiler.prepare_compile build ml;
  Cmd(S[!Options.ocamlc; Ocamlbuild_pack.Ocaml_utils.ocaml_ppflags tags; Ocamlbuild_pack.Ocaml_utils.ocaml_include_flags ml; A"-i";
        T(tags++"infer_interface"); P ml; Sh ">"; Px mli])

let derive_infer_interface =
  rule ("derive infer_interface: type_mli")
    ~deps:["src/%(name).ml"]
    ~prod:("src/type_mli/%(name: <*> and not <*.*>).type_mli")
    (fun env build ->
      ignore(build [[env ("src/type_mli/%(name).ml.depends")]]);
      Seq [
        Cmd(S[Sh "mkdir"; P "-p"; P "src/type_mli" ]);
	      infer_interface
	        (* (env ("src/type_mli/%(name).ml")) (\* We find the type from the original file *\) *)
	        (env ("src/type_mli/%(name).ml")) (* We take the env from the server *)
	        (env ("src/type_mli/%(name).type_mli"))
	        env
 	        build
      ]
    )

(**** Server/Client compilation ****)

let add_cmd ml = [ A"-ppopt"; A"-type"; A"-ppopt"; P ("src/type_mli/"^ml-.-"type_mli") ]

let ocamlc_c extra tags arg out =
  let tags = tags++"ocaml"++"byte" in
  Cmd (S ([!Options.ocamlc; A"-c"; T(tags++"compile");
           Ocamlbuild_pack.Ocaml_utils.ocaml_ppflags tags;
	         Ocamlbuild_pack.Ocaml_utils.ocaml_include_flags arg]
	        @ extra
	        @ [A"-o"; Px out; P arg]))

let add_dependency tags ml =
  [[ "src/type_mli/"^ml-.-"type_mli" ]]

let compilation ml env build =
  let ml = env ml in
  let filename = try Filename.basename (Filename.chop_extension ml) with _ -> ml in
  let tags = tags_of_pathname ml in

  let extra =
    if List.mem filename !type_mli_file then begin
      ignore (build (add_dependency tags filename));
      add_cmd filename
    end else []
  in

  let cmo = Pathname.update_extensions "cmo" ml in
  ignore (build [[ml-.-"depends"]]);
  Ocamlbuild_pack.Ocaml_compiler.prepare_compile build ml;
  ocamlc_c extra tags ml cmo

let _ =
  rule "ocaml server modified: ml -> cmo & cmi"
    ~deps:["src/server/%.ml"]
    ~prods:["src/server/%.cmo"; "src/server/%.cmi"]
    (compilation "src/server/%.ml")


let _ =
  rule "ocaml client modified: ml -> cmo & cmi"
    ~deps:["src/client/%.ml"]
    ~prods:["src/client/%.cmo"; "src/client/%.cmi"]
    (compilation "src/client/%.ml")


(* Deps *)
let ocamldep_command' tags =
  let tags' = tags++"ocaml"++"ocamldep" in
  S [!Options.ocamldep; T tags'; Ocamlbuild_pack.Ocaml_utils.ocaml_ppflags (tags++"pp:dep"); A "-modules"]

let ocamldep_command extra tags arg out =
  Cmd(S([ocamldep_command' tags; P arg]
	      @ extra
	      @ [Sh ">"; Px out]))

let dep ml env build =
  let ml = env ml in
  let filename = try Filename.basename (Filename.chop_extension ml) with _ -> ml in
  let tags = tags_of_pathname ml in

  let extra,tags =
    if List.mem filename !type_mli_file then add_cmd filename, tags
    else [],tags
  in

  let ml_depends = Pathname.update_extensions "ml.depends" ml in

  ocamldep_command extra tags ml ml_depends

let _ =
  rule "ocaml server modified: ml -. depends"
    ~dep:"src/server/%.ml"
    ~prod:"src/server/%.ml.depends"
    (dep "src/server/%.ml")

let _ =
  rule "ocaml client modified: ml -. depends"
    ~dep:"src/client/%.ml"
    ~prod:"src/client/%.ml.depends"
    (dep "src/client/%.ml")


(**** JS COMPILATION ****)
let _ =
  rule "js_of_ocaml"
    ~deps:["%_client.cmo";"public/js_dummy.js"]
    ~prod:"%.js"
    (fun env _ ->
	    Cmd (S [Sh"js_of_eliom"; P (env"%_client.cmo"); A"-jsopt";P"public/js_dummy.js"; A"-o"; P(env"%.js")])
    )


let _ = Options.use_ocamlfind := true
let _ = Options.make_links := false

let _ =
  dispatch begin function
    | After_rules ->

      copy_rule_with_header "src/%(name).ml" "src/server/%(name:<*>).ml" ;
      copy_rule_with_header "src/%(name).ml" "src/client/%(name:<*>).ml" ;
      copy_rule_with_header "src/%(name).ml" "src/type_mli/%(name:<*>).ml" ;

      flag [ "ocaml"; "infer_interface"; "thread" ] (S [ A "-thread" ]);

      ()

    | _ -> ()
  end
