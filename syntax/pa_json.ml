open Camlp4

module Id : Sig.Id =
struct
  let name = "pa_json"
  let version = "0.1"
end


module Make (Syntax : Sig.Camlp4Syntax) =
struct
  open Camlp4.PreCast
  include Syntax

  open Pa_deriving_common.Type

  EXTEND Gram
  str_item:
        [
          [ KEYWORD "type"; KEYWORD "."; "yjson"; tdl_raw = type_declaration ->

            let typs_raw = Pa_deriving_common.Base.display_errors _loc Pa_deriving_common.Type.Translate.decls tdl_raw in

            let modules_item =
              List.map (
                fun t ->
                  let (name,params,rhs,constr,deriving_insrt) = t in
                  match rhs with
                    | `Fresh (exp_opt,Record fields,priv) ->
                      let l =
                        List.map (
                          fun (name,(_, expr), _) ->
                            let type_,json_type =
                              match expr with
                                | `Constr (["int"], []) ->
                                  <:expr< Yjson.fetch_int $`str:name$ json >>,
                                  <:expr< Some (Yjson.to_int obj.$lid:name$) >>
                                | `Constr (["float"], []) ->
                                  <:expr< Yjson.fetch_float $`str:name$ json >>,
                                  <:expr< Some (Yjson.to_float obj.$lid:name$) >>
                                | `Constr (["string"], []) ->
                                  <:expr< Yjson.fetch_string $`str:name$ json >>,
                                  <:expr< Some (Yjson.to_string obj.$lid:name$) >>
                                | `Constr (["bool"], []) ->
                                  <:expr< Yjson.fetch_bool $`str:name$ json >>,
                                  <:expr< Some (Yjson.to_bool obj.$lid:name$) >>
                                | `Constr (["option"], expr) -> begin
                                    match expr with
                                      | [`Constr (["int"], [])] ->
                                        <:expr< Yjson.fetch_int_opt $lid:name$ json >>,
                                        <:expr<
                                          match obj.$`str:name$ with
                                            [ Some i -> Some (Yjson.to_int i)
                                            | None -> None ]
                                        >>
                                      | [`Constr (["float"], [])] ->
                                        <:expr< Yjson.fetch_float_opt $lid:name$ json >>,
                                        <:expr<
                                          match obj.$`str:name$ with
                                            [ Some f -> Some (Yjson.to_float f)
                                            | None -> None ]
                                        >>
                                      | [`Constr (["string"], [])] ->
                                        <:expr< Yjson.fetch_string_opt $lid:name$ json >>,
                                        <:expr<
                                          match obj.$`str:name$ with
                                            [ Some s -> Some (Yjson.to_string s)
                                            | None -> None ]
                                        >>
                                      | [`Constr (["bool"], [])] ->
                                        <:expr< Yjson.fetch_bool_opt $lid:name$ json >>,
                                        <:expr<
                                          match obj.$`str:name$ with
                                            [ Some b -> Some (Yjson.to_bool b)
                                            | None -> None ]
                                        >>
                                      | _ -> assert false
                                  end
                                | _ -> assert false
                            in

                            let from_json =
                              <:rec_binding<
                                $lid:name$ = $type_$
                              >>
                            in
                            let to_json =
                              <:expr< $tup: Ast.exCom_of_list [
                                <:expr< $`str:name$ >>;
                                  json_type
                              ]$>>
                            in
                            (from_json,to_json)
                        ) fields
                      in

                      let to_record,to_json = List.split l in

                      <:str_item<
                        module $uid:("Json_" ^ name ^ "s")$ =
                        struct
                          value of_file file_name =
                            let json = Yjson.from_file file_name in
                            do {{
                              $list:to_record$
                            }};

                           value to_file obj file_name =
                             let json = Yjson.to_json_opt
                               $List.fold_left (
                                   fun acc j ->
                                     <:expr<[ $j$::$acc$ ]>>
                                 ) (<:expr< [] >>) to_json$
                             in
                             do { Yjson.to_file json file_name };

                        end
                      >>

                    | _ -> assert false
              ) typs_raw
            in

            let module Help = Pa_deriving_common.Base.AstHelpers (struct let _loc = _loc end) in
            let tdl = List.map Help.Untranslate.decl typs_raw in

            Ast.stSem_of_list ((<:str_item< type $list:tdl$>>)::modules_item)
          ]
        ];

  END
end

module M = Register.OCamlSyntaxExtension(Id)(Make)
