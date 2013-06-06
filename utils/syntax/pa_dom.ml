open Camlp4
open Pa_deriving_common
open Utils

module Id : Sig.Id =
struct
  let name = "pa_dom"
  let version = "0.1"
end

module Description : Defs.ClassDescription = struct
  let classname = "Dom_ext"
  let runtimename = "Ext_dom"
  let default_module = None
  let alpha = None
  let allow_private = false
  let predefs = [
    ["int"], ["Ext_dom";"int"];
    ["int32"], ["Ext_dom";"int32"];
    ["Int32";"t"], ["Ext_dom";"int32"];
    ["int64"], ["Ext_dom";"int64"];
    ["Int64";"t"], ["Ext_dom";"int64"];
    ["bool"], ["Ext_dom";"bool"];
    ["float"], ["Ext_dom";"float"];
    ["string"], ["Ext_dom";"string"];
    ["list"], ["Ext_dom";"list"];
    ["array"],["Ext_dom";"array"];
    ["option"], ["Ext_dom";"option"];
  ]

  let depends = []
end

module Builder(Loc : Defs.Loc) = struct

  module Helpers = Base.AstHelpers(Loc)
  module Generator = Base.Generator(Loc)(Description)

  open Loc
  open Camlp4.PreCast
  open Description

  let generator = (object(self)

  inherit Generator.generator

    method proxy () =
      None, [
        <:ident< to_dom >>;
      ]

    method record ?eq ctxt tname params constraints (fields : Pa_deriving_common.Type.field list) =
      let to_dom =
        let l =
          List.map (
            fun (name,ty,_) ->
              <:expr<
                let v = $self#call_poly_expr ctxt ty "to_default"$ () in
                (div [
                  span [ pcdata ($`str:name$ ^ " :")];
                  v.Ext_dom.node ;
                ], ($`str:name$, v.Ext_dom.value_))
              >>,
              <:expr<
                let v = $self#call_poly_expr ctxt ty "to_dom"$ t.$lid:name$ in
                (div [
                  span [ pcdata ($`str:name$ ^ " :")];
                  v.Ext_dom.node ;
                ], ($`str:name$, v.Ext_dom.value_))
              >>
          ) fields
        in

        let to_default, to_dom = List.split l in

        <:str_item<
          value to_default () =
            let dom_list = $Helpers.expr_list to_default$ in
            do {{
              Ext_dom.node = div ~a:[ a_class [$`str:tname$]] (List.map (fun (d,_) -> d) dom_list);
              Ext_dom.value_ = `Record (List.map (fun (_,v) -> v) dom_list);
            }};

          value to_dom t =
            let dom_list = $Helpers.expr_list to_dom$ in
            do {{
              Ext_dom.node = div ~a:[ a_class [$`str:tname$]] (List.map (fun (d,_) -> d) dom_list);
              Ext_dom.value_ = `Record (List.map (fun (_,v) -> v) dom_list);
            }};
        >>
      in

      let save =
        let l =
          List.map (
            fun (name,ty,_) ->
              let expr =
                <:expr<
                  let v = List.assoc $`str:name$ value_list in
                  $self#call_poly_expr ctxt ty "save"$ v
                >>
              in
              name,expr
          ) fields
        in

        <:str_item@here<
          value save dom_ext =
            match dom_ext with
             [ `Record value_list ->
                 $Helpers.record_expr l$
               | _ -> raise Ext_dom.Wrong_dom_value
             ]
        >>
      in

      [
        to_dom ;
        save ;
      ]


    method tuple ctxt tys =
      let ntys = List.length tys in
      let ids,tpatt,texpr = Helpers.tuple ntys in

      let to_dom =
        let l =
          List.map (
            fun (ty,id) ->
              <:expr@here<
                $self#call_expr ctxt ty "to_default"$ ()
              >>,
              <:expr@here<
                (* $lid:id$ variable are define by the $tpatt$ below, They are normal type *)
                $self#call_expr ctxt ty "to_dom"$ $lid:id$
              >>
          ) (List.zip tys ids)
        in

        let to_default, to_dom = List.split l in

        <:str_item@here<
          value to_default () =
            (* $tpatt$ will be something like (id1,id2,id3...), so here id are value name of a subset of t*)
            let dom_list = $Helpers.expr_list to_default$ in
            do {{
              Ext_dom.node = div (List.map (fun d -> d.Ext_dom.node) dom_list) ;
              Ext_dom.value_ = `List (List.map (fun d -> d.Ext_dom.value_) dom_list) ;
            }};

          value to_dom t =
            (* $tpatt$ will be something like (id1,id2,id3...), so here id are value name of a subset of t*)
            let $tpatt$ = t in
            let dom_list = $Helpers.expr_list to_dom$ in
            do {{
              Ext_dom.node = div (List.map (fun d -> d.Ext_dom.node) dom_list) ;
              Ext_dom.value_ = `List (List.map (fun d -> d.Ext_dom.value_) dom_list) ;
            }};
        >>
      in

      let save =
        let l =
          List.map (
            fun (ty,id) ->
              <:expr@here<
                (* $lid:id$ variable are define by the $tpatt$ below, They are normal type *)
                $self#call_expr ctxt ty "save"$ $lid:id$
              >>
          ) (List.zip tys ids)
        in

        <:str_item@here<
          value save dom_ext =
            match dom_ext with
             [ `List $Helpers.patt_list (List.map (fun x -> <:patt<$lid:x$>>) ids)$ ->
                 $Helpers.tuple_expr l$
               | _ -> raise Ext_dom.Wrong_dom_value
             ]
        >>
      in

      [
        to_dom;
        save;
      ]


method sum ?eq ctxt tname params constraints summands =
  assert false

method variant ctxt tname params constraints (_, tags) =

  let to_dom =
    let l =
      List.mapn ~init:1 (
        fun t i ->
          match t with
            | Type.Tag (name, []) ->
              let opt =
                <:expr@here<
                  option ~a:[
                    a_value $`str:name$
                  ] (pcdata $`str:name$)
                >>
              in
              opt,(None,(None,None))
            | Type.Tag (name, tys) ->
              let ntys = List.length tys in
              let ids,tpatt,texpr = Helpers.tuple ntys in

              let l = List.map (
                  fun (ty,id) ->
                    let lid = id ^ "_" ^ (string_of_int i) in
                    (<:binding<
                       $lid:lid$ = $self#call_expr ctxt ty "to_default"$ ()
                     >>,
                     <:expr< $lid:lid$ >>)
                ) (List.zip tys ids)
              in

              let l,lids = List.split l in
              let bindings = Some (Ast.biAnd_of_list l) in

              let opt =
                <:expr@here<
                  option ~a:[
                    a_value $`str:name$
                  ] (pcdata $`str:name$)
                >>
              in

              let node =
                Some
                <:expr@here<
                  ($`str:name$, (List.map (fun d -> d.Ext_dom.node) $Helpers.expr_list lids$))
                >>
              in

              let dom_value =
                Some
                <:expr@here<
                  ($`str:name$, `List (List.map (fun d -> d.Ext_dom.value_) $Helpers.expr_list lids$))
                >>
              in
              opt,(bindings,(node,dom_value))
            | Type.Extends _ ->
              assert false
      ) tags
    in

    let options, node_info = List.split l in
    let bindings,nodes = List.split node_info in
    let nodes,dom_value = List.split nodes in

    let nodes =
      List.fold_left (
        fun acc i ->
          match i with
            | None -> acc
            | Some e -> e::acc
      ) [] nodes
    in

    let dom_value =
      List.fold_left (
        fun acc i ->
          match i with
            | None -> acc
            | Some e -> e::acc
      ) [] dom_value
    in

    let bindings =
      List.fold_left (
        fun acc i ->
          match i with
            | None -> acc
            | Some e -> e::acc
      ) [] bindings
    in

    <:str_item@here<
      value to_default () =
        let updatable_div = div [] in
        let $Ast.biAnd_of_list bindings$ in
        let nodes_list = $Helpers.expr_list nodes$ in

        let rec sel = lazy (Raw.select ~a:[ a_onchange (fun _ -> do { on_change (); True})  ] $Helpers.expr_list options$)
        and on_change () =
          let sel = Lazy.force sel in
          let v = Dom_manip.get_value_select sel in

          try
            let l = List.assoc v nodes_list in
            Manip.replaceAllChild updatable_div l
          with [ Not_found ->
            Manip.removeAllChild updatable_div
          ]
        in

        let sel = Lazy.force sel in

        do {{
           Ext_dom.node = div ~a:[ a_class ["select_element"]] [
               (sel :> Eliom_content_core.Html5.elt Html5_types.div_content_fun);
               updatable_div ;
             ] ;
           Ext_dom.value_ = `Select (sel,$Helpers.expr_list dom_value$);
        }};


      (* Use t to set default value *)
      value to_dom t =
        let updatable_div = div [] in
        let $Ast.biAnd_of_list bindings$ in
        let nodes_list = $Helpers.expr_list nodes$ in

        let rec sel = lazy (Raw.select ~a:[ a_onchange (fun _ -> do { on_change (); True})  ] $Helpers.expr_list options$)
        and on_change () =
          let sel = Lazy.force sel in
          let v = Dom_manip.get_value_select sel in

          try
            let l = List.assoc v nodes_list in
            Manip.replaceAllChild updatable_div l
          with [ Not_found ->
            Manip.removeAllChild updatable_div
          ]
        in

        let sel = Lazy.force sel in

        do {{
           Ext_dom.node = div ~a:[ a_class ["select_element"]] [
               (sel :> Eliom_content_core.Html5.elt Html5_types.div_content_fun);
               updatable_div ;
             ] ;
           Ext_dom.value_ = `Select (sel,$Helpers.expr_list dom_value$);
        }};

    >>
  in

  let save =
    let mcs =
      List.fold_left (
        fun acc t ->
          match t with
            | Type.Tag (name, []) ->
              <:match_case@here<
                $`str:name$ ->
                  `$uid:name$
              >>::acc
            | Type.Tag (name, tys) ->
              let ntys = List.length tys in
              let ids,tpatt,texpr = Helpers.tuple ntys in

              let l =
                List.map (
                  fun (ty,id) ->
                    <:expr@here< $self#call_expr ctxt ty "save"$ $lid:id$ >>
                ) (List.zip tys ids)
              in

              <:match_case@here<
                $`str:name$ ->
                  match List.assoc $`str:name$ nodes with [
                    `List $Helpers.patt_list (List.map (fun x -> <:patt<$lid:x$>>) ids)$ ->
                      `$uid:name$  $Helpers.tuple_expr l$
                    | _ -> raise Ext_dom.Wrong_dom_value
                  ]
              >>::acc
            | Type.Extends _ ->
              assert false
      ) [ <:match_case@here< _ -> raise Ext_dom.Empty_value >> ] tags
    in

    <:str_item@here<
      value save =
        fun [
         `Select (sel, nodes) ->
           match Dom_manip.get_value_select sel with [
             $list:mcs$
           ]
        | _ -> raise Ext_dom.Wrong_dom_value
      ]
    >>
  in

  [
    to_dom ;
    save ;
  ]


end :> Generator.generator)

let generate = Generator.generate generator
let generate_sigs = Generator.generate_sigs generator

end

module Dom_ext = Base.Register(Description)(Builder)
