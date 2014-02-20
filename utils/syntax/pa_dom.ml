open Camlp4
open Pa_deriving_common
open Utils

module Id : Sig.Id =
struct
  let name = "pa_dom"
  let version = "0.1"
end

module Description : Defs.ClassDescription = struct
  let classname = "Admin_mod"
  let runtimename = "Admin_mod"
  let default_module = None
  let alpha = None
  let allow_private = false
  let predefs = [
    ["int"], ["Admin_mod";"int"];
    ["int32"], ["Admin_mod";"int32"];
    ["Int32";"t"], ["Admin_mod";"int32"];
    ["int64"], ["Admin_mod";"int64"];
    ["Int64";"t"], ["Admin_mod";"int64"];
    ["bool"], ["Admin_mod";"bool"];
    ["float"], ["Admin_mod";"float"];
    ["string"], ["Admin_mod";"string"];
    ["list"], ["Admin_mod";"list"];
    ["array"],["Admin_mod";"array"];
    ["option"], ["Admin_mod";"option"];
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
                  v.Admin_mod.node ;
                ], ($`str:name$, v))
              >>,
              <:expr<
                let v = $self#call_poly_expr ctxt ty "to_dom"$ t.$lid:name$ in
                (div [
                  span [ pcdata ($`str:name$ ^ " :")];
                  v.Admin_mod.node ;
                ], ($`str:name$, v))
              >>
          ) fields
        in

        let to_default, to_dom = List.split l in

        <:str_item<
          value to_default ?v () =
            let dom_list = $Helpers.expr_list to_default$ in
            do {{
              Admin_mod.node = div ~a:[ a_class [ "dom_ext_" ^ $`str:tname$; "dom_ext_record"]] (List.map (fun (d,_) -> d) dom_list);
              Admin_mod.value_ = `Record (List.map (fun (_,v) -> v) dom_list);
              Admin_mod.error = None ;
            }};

          value to_dom t =
            let dom_list = $Helpers.expr_list to_dom$ in
            do {{
              Admin_mod.node = div ~a:[ a_class [ "dom_ext_" ^ $`str:tname$; "dom_ext_record"]] (List.map (fun (d,_) -> d) dom_list);
              Admin_mod.value_ = `Record (List.map (fun (_,v) -> v) dom_list);
              Admin_mod.error = None ;
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
          match dom_ext.Admin_mod.value_ with
             [ `Record value_list ->
                 $Helpers.record_expr l$
               | _ -> raise Admin_mod.Wrong_dom_value
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
          value to_default ?v () =
            (* $tpatt$ will be something like (id1,id2,id3...), so here id are value name of a subset of t*)
            let dom_list = $Helpers.expr_list to_default$ in
            do {{
              Admin_mod.node = div ~a:[a_class [ "dom_ext_tuple" ]] (List.map (fun d -> d.Admin_mod.node) dom_list) ;
              Admin_mod.value_ = `List dom_list ;
              Admin_mod.error = None ;
            }};

          value to_dom t =
            (* $tpatt$ will be something like (id1,id2,id3...), so here id are value name of a subset of t*)
            let $tpatt$ = t in
            let dom_list = $Helpers.expr_list to_dom$ in
            do {{
              Admin_mod.node = div ~a:[ a_class ["dom_ext_tuple"]] (List.map (fun d -> d.Admin_mod.node) dom_list) ;
              Admin_mod.value_ = `List dom_list ;
              Admin_mod.error = None ;
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
            match dom_ext.Admin_mod.value_ with
             [ `List $Helpers.patt_list (List.map (fun x -> <:patt<$lid:x$>>) ids)$ ->
                 $Helpers.tuple_expr l$
               | _ -> raise Admin_mod.Wrong_dom_value
             ]
        >>
      in

      [
        to_dom;
        save;
      ]


     method sum_to_dom: 'c. Generator.context -> ('a -> 'b -> 'c -> 'd) -> 'c list -> Camlp4.PreCast.Ast.str_item = fun ctxt mc tags ->
       let no_expr (i,opts,mcs,binds,doms) ~is_sum name =
         let opt =
           <:expr@here<
             option ~a:[
               a_value $`str:name$
             ] (pcdata $`str:name$)
           >>
         in
         let mc =
           if is_sum then
             <:match_case@here<
               $uid:name$ ->
                 Dom_manip.select_index sel $`int:i$
             >>
           else
           <:match_case@here<
             `$uid:name$ ->
                Dom_manip.select_index sel $`int:i$
           >>
         in

         ((i + 1),opt::opts,mc::mcs,binds,doms)
       in

       let with_expr (i,opts,mcs,binds,doms) ~is_sum name tys =
         let ntys = List.length tys in
         let ids,tpatt,texpr = Helpers.tuple ntys in

         let binds_default,bindings,lids = List.fold_left (
             fun (binds_def,binds,lids) (ty,id) ->
               let lid = id ^ "_" ^ (string_of_int i) in
               (<:binding<
                   $lid:lid$ = lazy ($self#call_expr ctxt ty "to_default"$ ())
                >>::binds_def,
                (if is_sum then
                    <:binding<
                      $lid:lid$ =
                      (* type t is define in to_dom call*)
                      lazy (
                        match t with [
                          $uid:name$ $tpatt$ ->
                            $self#call_expr ctxt ty "to_dom"$ $lid:id$
                        | _ -> $self#call_expr ctxt ty "to_default"$ ()
                      ])
                    >>
                  else
                    <:binding<
                      $lid:lid$ =
                       (* type t is define in to_dom call*)
                       lazy (
                       match t with [
                          `$uid:name$ $tpatt$ ->
                             $self#call_expr ctxt ty "to_dom"$ $lid:id$
                      | _ -> $self#call_expr ctxt ty "to_default"$ ()
                      ])
                    >>
                )::binds,
                <:expr< $lid:lid$ >>::lids)
           ) ([],[],[]) (List.zip tys ids)
         in

         let mc =
           if is_sum then
             <:match_case@here<
               $uid:name$ _ ->
                 Dom_manip.select_index sel $`int:i$
              >>
           else
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

         let dom_value =
           <:expr@here<
             ($`str:name$, $Helpers.expr_list lids$)
           >>
         in
         ((i + 1),opt::opts,mc::mcs,(bind_default,bind)::binds,dom_value::doms)
       in

       let to_dom =
    (*
       We need to create binding (and not calling the function to_dom twice, once for node, once for value_) for each tys because
       we are saving a value of type Html5.div_content_fun in Admin_mod.value_.
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
             fun acc t ->
               mc (no_expr acc) (with_expr acc) t
           ) (1,[opt_default],[],[],[]) tags
         in

         let to_dom binds match_select =
           <:expr@here<
             let updatable_div = div [] in
             let $Ast.biAnd_of_list binds$ in
             let nodes_list = $Helpers.expr_list dom_values$ in

             let rec sel = lazy (Raw.select $Helpers.expr_list (List.rev options)$)
             and on_change () =
                 let sel = Lazy.force sel in
                 let v = Dom_manip.get_value_select sel in

                 try
                   let l =
                     List.map (
                       fun e ->
                         let e = Lazy.force e in
                         e.Admin_mod.node
                     ) (List.assoc v nodes_list)
                   in
                   Manip.replaceAllChild updatable_div l
                 with [ Not_found ->
                        Manip.removeAllChild updatable_div
                      ]
             in

             let sel = Lazy.force sel in

             do {
               $match_select$;

               {
                 Admin_mod.node = div ~a:[ a_class ["dom_ext_sum"]] [
                     (sel :> Eliom_content_core.Html5.elt Html5_types.div_content_fun);
                     updatable_div ;
                   ] ;
                 Admin_mod.value_ = `Select (sel,$Helpers.expr_list dom_values$);
                 Admin_mod.error = None ;
               }
             }
               >>
          in

          let binds_def,bindings = List.split bindings in

          <:str_item@here<
            value to_default ?v () =
             $to_dom binds_def (<:expr<>>)$;

            value to_dom t =
              $to_dom bindings (
                <:expr@here<
                  match t with [
                    $list:mcs$
                  ];
                    (* SelectedIndex doesn't trigger onchange... *)
                    on_change ()
                    >>
              )$;
          >>
       in

        to_dom


method save_of_sum : 'c. Generator.context -> ('e -> 'f -> 'c -> 'g) -> 'c list -> Camlp4.PreCast.Ast.str_item = fun ctxt mc tags ->
  let save =
    let no_expr acc ~is_sum name =
      if is_sum then
        <:match_case@here<
          $`str:name$ ->
            $uid:name$
        >>::acc
      else
        <:match_case@here<
          $`str:name$ ->
            `$uid:name$
         >>::acc
    in

    let with_expr acc ~is_sum name tys =
      let ntys = List.length tys in
      let ids,tpatt,texpr = Helpers.tuple ntys in

      let l =
        List.map (
          fun (ty,id) ->
            <:expr@here< $self#call_expr ctxt ty "save"$ (Lazy.force $lid:id$) >>
        ) (List.zip tys ids)
      in

      if is_sum then
        <:match_case@here<
          $`str:name$ ->
          match List.assoc $`str:name$ nodes with [
            $Helpers.patt_list (List.map (fun x -> <:patt<$lid:x$>>) ids)$ ->
              $uid:name$  $Helpers.tuple_expr l$
            | _ -> raise Admin_mod.Wrong_dom_value
          ]
        >>::acc
      else
        <:match_case@here<
          $`str:name$ ->
            match List.assoc $`str:name$ nodes with [
              $Helpers.patt_list (List.map (fun x -> <:patt<$lid:x$>>) ids)$ ->
                `$uid:name$  $Helpers.tuple_expr l$
              | _ -> raise Admin_mod.Wrong_dom_value
          ]
        >>::acc
    in

    let mcs =
      List.fold_left (
        fun acc t ->
          mc (no_expr acc) (with_expr acc) t
      ) [ <:match_case@here< _ -> raise Admin_mod.Empty_value >> ] tags
    in

    <:str_item@here<
      value save d =
      match d.Admin_mod.value_ with
        [
         `Select (sel, nodes) ->
            match Dom_manip.get_value_select sel with [
              $list:mcs$
            ]
            | _ -> raise Admin_mod.Wrong_dom_value
        ]
     >>
  in

  save



method sum ?eq ctxt tname params constraints summands =
  let mc no_expr with_expr =
    function
      | (name, []) -> no_expr ~is_sum:true name
      | (name,tys) -> with_expr ~is_sum:true name tys
  in

  let to_dom = self#sum_to_dom ctxt mc summands in
  let save = self#save_of_sum ctxt mc summands in

  [
    to_dom ;
    save ;
  ]


method variant ctxt tname params constraints (_, tags) =

  let mc no_expr with_expr =
    function
      | Type.Tag (name, []) -> no_expr ~is_sum:false name
      | Type.Tag (name,tys) -> with_expr ~is_sum:false name tys
      | Type.Extends _ -> assert false
  in

  let to_dom = self#sum_to_dom ctxt mc tags in
  let save = self#save_of_sum ctxt mc tags in

  [
    to_dom ;
    save ;
  ]


end :> Generator.generator)

let generate = Generator.generate generator
let generate_sigs = Generator.generate_sigs generator

end

module Admin_mod = Base.Register(Description)(Builder)
