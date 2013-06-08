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
        <:ident< to_default >>;
        <:ident< to_dom >>;
        <:ident< save >>;
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
                ], ($`str:name$, v))
              >>,
              <:expr<
                let v = $self#call_poly_expr ctxt ty "to_dom"$ t.$lid:name$ in
                (div [
                  span [ pcdata ($`str:name$ ^ " :")];
                  v.Ext_dom.node ;
                ], ($`str:name$, v))
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
          match dom_ext.Ext_dom.value_ with
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
              Ext_dom.value_ = `List dom_list ;
            }};

          value to_dom t =
            (* $tpatt$ will be something like (id1,id2,id3...), so here id are value name of a subset of t*)
            let $tpatt$ = t in
            let dom_list = $Helpers.expr_list to_dom$ in
            do {{
              Ext_dom.node = div (List.map (fun d -> d.Ext_dom.node) dom_list) ;
              Ext_dom.value_ = `List dom_list ;
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
            match dom_ext.Ext_dom.value_ with
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
    (*
       We need to create binding (and not calling the function to_dom twice, once for node, once for value_) for each tys because
       we are saving a value of type Html5.div_content_fun in Ext_dom.value_.
       If we were directly calling the function twice, we would be unable to fetch any value, since the 'dom' display and the 'dom'
       from which we are taking the value will differ
    *)

    let opt_default =
      <:expr@here<
        option (pcdata "")
      >>
    in
    let _,options,mcs,bindings,dom_values =
      List.fold_left (
        fun (i,opts,mcs,binds,doms) t ->
          match t with
            | Type.Tag (name, []) ->
              let opt =
                <:expr@here<
                  option ~a:[
                    a_value $`str:name$
                  ] (pcdata $`str:name$)
                >>
              in
              let mc =
                <:match_case@here<
                  `$uid:name$ ->
                   Dom_manip.select_index sel $`int:i$
                >>
              in

              ((i + 1),opt::opts,mc::mcs,binds,doms)
            | Type.Tag (name, tys) ->
              let ntys = List.length tys in
              let ids,tpatt,texpr = Helpers.tuple ntys in

              let binds_default,bindings,lids = List.fold_left (
                  fun (binds_def,binds,lids) (ty,id) ->
                    let lid = id ^ "_" ^ (string_of_int i) in
                    (<:binding<
                        $lid:lid$ = lazy ($self#call_expr ctxt ty "to_default"$ ())
                     >>::binds_def,
                     <:binding<
                       $lid:lid$ =
                        (* type t is define in to_dom call*)
                        lazy (
                        match t with [
                           `$uid:name$ $tpatt$ ->
                              $self#call_expr ctxt ty "to_dom"$ $lid:id$
                          | _ -> $self#call_expr ctxt ty "to_default"$ ()
                        ])
                     >>::binds,
                     <:expr< $lid:lid$ >>::lids)
                ) ([],[],[]) (List.zip tys ids)
              in

              let mc =
                <:match_case@here<
                  `$uid:name$ _ ->
                    Dom_manip.select_index sel $`int:i$
                >>
              in

              let bind_default = (Ast.biAnd_of_list binds_default) in
              let bind = (Ast.biAnd_of_list bindings) in

              let opt =
                <:expr@here<
                  option ~a:[
                    a_value $`str:name$
                  ] (pcdata $`str:name$)
                >>
              in

              (* let node = *)
              (*   <:expr@here< *)
              (*     ($`str:name$, (List.map (fun d -> d.Ext_dom.node) $Helpers.expr_list lids$)) *)
              (*   >> *)
              (* in *)

              let dom_value =
                <:expr@here<
                  ($`str:name$, $Helpers.expr_list lids$)
                >>
              in
              ((i + 1),opt::opts,mc::mcs,(bind_default,bind)::binds,dom_value::doms)
            | Type.Extends _ ->
              assert false
      ) (1,[opt_default],[],[],[]) tags
    in

    let binds_def,bindings = List.split bindings in

    <:str_item@here<
      value to_default () =
        let updatable_div = div [] in
        let $Ast.biAnd_of_list binds_def$ in
        let nodes_list = $Helpers.expr_list dom_values$ in

        let rec sel = lazy (Raw.select ~a:[ a_onchange (fun _ -> do { on_change (); True})  ] $Helpers.expr_list (List.rev options)$)
        and on_change () =
          let sel = Lazy.force sel in
          let v = Dom_manip.get_value_select sel in

          try
            let l =
              List.map (
                fun e ->
                  let e = Lazy.force e in
                  e.Ext_dom.node
              ) (List.assoc v nodes_list)
            in
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
           Ext_dom.value_ = `Select (sel,$Helpers.expr_list dom_values$);
        }};

      value to_dom t =
        let updatable_div = div [] in
        let $Ast.biAnd_of_list bindings$ in
        let nodes_list = $Helpers.expr_list dom_values$ in

        let rec sel = lazy (Raw.select ~a:[ a_onchange (fun _ -> do { on_change (); True})  ] $Helpers.expr_list (List.rev options)$)
        and on_change () =
          let sel = Lazy.force sel in
          let v = Dom_manip.get_value_select sel in

          try
            let l =
              List.map (
                fun e ->
                  let e = Lazy.force e in
                  e.Ext_dom.node
              ) (List.assoc v nodes_list)
            in
            Manip.replaceAllChild updatable_div l
          with [ Not_found ->
            Manip.removeAllChild updatable_div
          ]
        in

        let sel = Lazy.force sel in

        do {
          match t with [
            $list:mcs$
          ];
          (* SelectedIndex doesn't trigger onchange... *)
          on_change ();
          {
           Ext_dom.node = div ~a:[ a_class ["select_element"]] [
               (sel :> Eliom_content_core.Html5.elt Html5_types.div_content_fun);
               updatable_div ;
             ] ;
           Ext_dom.value_ = `Select (sel,$Helpers.expr_list dom_values$);
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
                    <:expr@here< $self#call_expr ctxt ty "save"$ (Lazy.force $lid:id$) >>
                ) (List.zip tys ids)
              in

              <:match_case@here<
                $`str:name$ ->
                  match List.assoc $`str:name$ nodes with [
                    $Helpers.patt_list (List.map (fun x -> <:patt<$lid:x$>>) ids)$ ->
                      `$uid:name$  $Helpers.tuple_expr l$
                    | _ -> raise Ext_dom.Wrong_dom_value
                  ]
              >>::acc
            | Type.Extends _ ->
              assert false
      ) [ <:match_case@here< _ -> raise Ext_dom.Empty_value >> ] tags
    in

    <:str_item@here<
      value save d =
        match d.Ext_dom.value_ with
          [
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
