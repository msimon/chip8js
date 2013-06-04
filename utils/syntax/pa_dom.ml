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
                div [
                  span [ pcdata ($`str:name$ ^ " :")];
                  $self#call_poly_expr ctxt ty "to_default"$ ()
                ]
              >>,
              <:expr<
                div [
                  span [ pcdata ($`str:name$ ^ " :")];
                  $self#call_poly_expr ctxt ty "to_dom"$ t.$lid:name$
                ]
              >>
          ) fields
        in

        let to_default, to_dom = List.split l in

        <:str_item<
          value to_default () =
            let dom_list = $Helpers.expr_list to_default$ in
            do { div ~a:[ a_class [$`str:tname$]] dom_list };

          value to_dom t =
            let dom_list = $Helpers.expr_list to_dom$ in
            do { div ~a:[ a_class [$`str:tname$]] dom_list };
        >>
      in

      [
        to_dom ;
      ]


    method tuple ctxt tys =
      let ntys = List.length tys in
      let ids,tpatt,texpr = Helpers.tuple ntys in

      let to_dom =
        let l =
          List.map (
            fun (ty,id) ->
              <:expr<
                (* $lid:id$ variable are define by the $tpatt$ below, They are normal type *)
                $self#call_expr ctxt ty "to_default"$ ()
              >>,
              <:expr<
                (* $lid:id$ variable are define by the $tpatt$ below, They are normal type *)
                $self#call_expr ctxt ty "to_dom"$ $lid:id$
              >>
          ) (List.zip tys ids)
        in

        let to_default, to_dom = List.split l in

        <:str_item@here<
          value to_default () =
            (* $tpatt$ will be something like (id1,id2,id3...), so here id are value name of a subset of t*)
            do { div ($Helpers.expr_list to_default$) };

          value to_dom t =
            (* $tpatt$ will be something like (id1,id2,id3...), so here id are value name of a subset of t*)
            let $tpatt$ = t in
            do { div ($Helpers.expr_list to_dom$) }
        >>
      in

      [
        to_dom;
      ]


method sum ?eq ctxt tname params constraints summands =
  assert false

method variant ctxt tname params constraints (_, tags) =
  assert false

end :> Generator.generator)

let generate = Generator.generate generator
let generate_sigs = Generator.generate_sigs generator

end

module Dom_ext = Base.Register(Description)(Builder)
