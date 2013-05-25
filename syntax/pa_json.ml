open Camlp4

module Id : Sig.Id =
struct
  let name = "pa_json"
  let version = "0.1"
end


module Make (Syntax : Sig.Camlp4Syntax) =
struct
  open Sig
  include Syntax

  let helper_type_declaration = Gram.Entry.mk "helper_type_declaration"
  let helper_label_declaration = Gram.Entry.mk "helper_label_declaration"

  EXTEND Gram

  helper_type_declaration:
      [
        LEFTA
        [
            (type_name, _) = type_ident_and_parameters; "=" ;
            "{"; labels = LIST1 helper_label_declaration SEP ";" ; "}" ->
            (type_name, labels)
          ]
      ];

    helper_label_declaration:
      [[
        label = a_LIDENT; KEYWORD ":" ; t = ctyp ->
        (label,t)
      ]];


    str_item: FIRST
        [
          [ KEYWORD "type"; KEYWORD "."; "json";  (type_name,labels) = helper_type_declaration ->
            let tdl = Ast.TyDcl (_loc, type_name, [],
                <:ctyp< { $list:List.map (fun (name, ty) -> <:ctyp< $lid:name$ : $ty$ >>) labels$ } >>, []) in
            <:str_item@here<

              type $tdl$;

                module $uid:("Json_" ^ type_name ^ "s")$ =
                struct
                  value of_file str =
                    Printf.printf $str:"of_file Json_" ^ type_name ^ "s -> %s\n%!"$ str;

                  value to_file str =
                    Printf.printf $str:"to_file Json_" ^ type_name ^ "s -> %s\n%!"$ str;
                end
            >>
          ]
        ] ;
  END
end

module M = Register.OCamlSyntaxExtension(Id)(Make)
