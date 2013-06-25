module Set_ =
struct
  type t = string
  let compare s1 s2 = compare s1 s2
end

module Cache = Set.Make(Set_)

let cache = ref Cache.empty
let network = ref Cache.empty
let fallback = ref Cache.empty
let version_nb = ref 0

let read_file path =
  let rec read ~current ic =
    let l = input_line ic in

    match l with
      | "CACHE MANIFEST" -> read ~current:`Cache ic
      | "CACHE:" -> read ~current:`Cache ic
      | "NETWORK:" -> read ~current:`Network ic
      | "FALLBACK:" -> read ~current:`Fallback ic
      | _ ->
        begin match Str.string_match (Str.regexp "^#ver: \\([0-9]+\\)") l 0 with
          | true ->
            let str = Str.matched_group 1 l in
            version_nb := (int_of_string str) + 1;
          | false ->
            begin match current with
              | `Cache -> cache := Cache.add l !cache
              | `Network -> network := Cache.add l !network
              | `Fallback -> fallback := Cache.add l !fallback
            end;
        end;
        read ~current ic
  in

  let ic = open_in path in
  try read ~current:`Cache ic
  with End_of_file -> close_in ic; ()

let write_file path =
  let cache_list = [ (`Cache, !cache) ; (`Network, !network) ; (`Fallback, !fallback) ] in

  let oc = open_out_gen [ Open_creat; Open_trunc; Open_wronly ] 777 path in
  output_string oc "CACHE MANIFEST\n" ;
  output_string oc (Printf.sprintf "#ver: %d\n" !version_nb);

  List.iter (
    fun (t,set) ->
      if Cache.cardinal set > 0 then begin
        begin match t with
          | `Cache -> output_string oc "CACHE:\n"
          | `Network -> output_string oc "NETWORK:\n"
          | `Fallback -> output_string oc "FALLBACK:\n"
        end;
        Cache.iter (
          fun e ->
            output_string oc e;
            output_char oc '\n';
        ) set
      end
  ) cache_list;

  flush oc;
  close_out oc

(* For now only get images *)
let implem () =
  let rec read_dir ~prefix ~t dh =
    try
      let s = Unix.readdir dh in
      if s <> "." && s <> ".." then begin
        let s = prefix ^ s in
        begin match t with
          | `Cache -> cache := Cache.add s !cache
          | `Network -> network := Cache.add s !network
          | `Fallback -> fallback := Cache.add s !fallback
        end;
      end;
      read_dir ~prefix ~t dh
    with End_of_file -> ()
  in

  let dh = Unix.opendir "public/img/game_img" in
  read_dir ~prefix:"/img/game_img/" ~t:`Cache dh;

  ()

let _ =
  read_file Sys.argv.(1);
  implem () ;
  write_file Sys.argv.(1)
