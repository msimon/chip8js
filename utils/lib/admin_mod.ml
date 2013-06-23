{client{

  exception Wrong_dom_value

  (* empty value is to handle correclty option for list and array
     When a value is missing from a list or an array, we don't want it to be set at None.
     We delete the value that generate a error, and keep the rest of the list/array
  *)
  exception Empty_value

  open Eliom_content
  open Html5
  open D

  type 'a dom_value = [
    | `Input of Html5_types.input Eliom_content.Html5.D.elt
    | `Textarea of Html5_types.textarea Eliom_content.Html5.D.elt
    | `Select of Html5_types.select Eliom_content.Html5.D.elt * ((string * ('a dom_ext Lazy.t) list) list)
    | `List of 'a dom_ext list
    | `Record of (string * 'a dom_ext) list
  ]

  and ('a) dom_ext = {
    node : 'a Eliom_content.Html5.D.elt ;
    mutable value_ : 'a dom_value ;
    error : Html5_types.p Eliom_content.Html5.D.elt option;
  }

  let node d = d.node
  let value d = d.value_

  module type Admin_mod = sig
    type a
    val to_default : ?v:a -> unit -> [ Html5_types.div_content_fun ] dom_ext
    val to_dom : a -> [ Html5_types.div_content_fun ] dom_ext

    val save : [ Html5_types.div_content_fun ] dom_ext -> a
  end

  module Default(D : Admin_mod) : Admin_mod with type a = D.a = struct
    include D
  end

  let handle_exception error_dom t v f =
    try
      f v
    with exn ->
      begin match error_dom with
        | Some error_dom ->
          let error = Printf.sprintf "Expected value of type %s but '%s' was given" t (match v with | Some v -> v | None -> "") in
          Manip.SetCss.display error_dom "block" ;
          Manip.replaceAllChild error_dom [ pcdata error ]
        | None -> ()
      end;
      raise exn

  module Admin_mod_int = Default(struct
      type a = int

      let to_default ?v () =
        let v =
          match v with
            | Some v ->
              a_value (string_of_int v)
            | None ->
              a_value ""
        in

        let error = p ~a:[ a_class ["error"]; a_style "display:none"] [ ] in
        let d = input ~a:[ v ] ~input_type:`Text () in
        {
          node = div ~a:[ a_class ["dom_ext_int"] ] [ error; d ] ;
          value_ = `Input d;
          error = Some error;
        }

      let to_dom i =
        to_default ~v:i ()

      let save d =
        match d.value_ with
          | `Input i ->
            let v = Dom_manip.get_opt_value i in
            handle_exception d.error "int" v (
              function
                | Some i -> int_of_string i
                | None -> raise Empty_value
            )
          | _ -> raise Wrong_dom_value

    end)


  module Admin_mod_int32 = Default(struct
      type a = int32

      let to_default ?v () =
        let v =
          match v with
            | Some v ->
              a_value (Int32.to_string v)
            | None ->
              a_value ""
        in

        let error = p ~a:[ a_class ["error"]; a_style "display:none"] [ ] in
        let d = input ~a:[ v ] ~input_type:`Text () in
        {
          node = div ~a:[ a_class ["dom_ext_int"; "dom_ext_int32"] ] [ error; d ] ;
          value_ = `Input d;
          error = Some error ;
        }

      let to_dom i =
        to_default ~v:i ()

      let save d =
        match d.value_ with
          | `Input i ->
            let v = Dom_manip.get_opt_value i in
            handle_exception d.error "int32" v (
              function
                | Some i -> Int32.of_string i
                | None -> raise Empty_value
            )
          | _ -> raise Wrong_dom_value

    end)

  module Admin_mod_int64 = Default(struct
      type a = int64

      let to_default ?v () =
        let v =
          match v with
            | Some v ->
              a_value (Int64.to_string v)
            | None ->
              a_value ""
        in

        let error = p ~a:[ a_class ["error"]; a_style "display:none"] [ ] in
        let d = input ~a:[ v ] ~input_type:`Text () in
        {
          node = div ~a:[ a_class ["dom_ext_int"; "dom_ext_int64"] ] [ error; d ] ;
          value_ = `Input d;
          error = Some error ;
        }

      let to_dom i =
        Firebug.console##debug (Js.string "lol");
        to_default ~v:i ()

      let save d =
        match d.value_ with
        | `Input i ->
          let v = Dom_manip.get_opt_value i in
          handle_exception d.error "int64" v (
            function
              | Some i -> Int64.of_string i
              | None -> raise Empty_value
          )
        | _ -> raise Wrong_dom_value

    end)

  module Admin_mod_bool = Default(struct
      type a = bool

      let to_default ?v () =
        let sel =
          Raw.select [
            option (pcdata "");
            option ~a:[ a_value "true" ] (pcdata "true");
            option ~a:[ a_value "false" ] (pcdata "false");
          ]
        in

        begin
          match v with
            | Some v ->
              if v then Dom_manip.select_index sel 1
              else Dom_manip.select_index sel 2
            | None -> ()
        end;

        {
          node = div ~a:[ a_class ["dom_ext_bool"]] [ sel ];
          value_ = `Select (sel, []);
          error = None;
        }

      let to_dom b =
        to_default ~v:b ()

      let save d =
        match d.value_ with
          | `Select (sel, []) ->
            begin
              match Dom_manip.get_value_select sel with
                | "true" -> true
                | "false" -> false
                | _ -> raise Empty_value
            end
          | _ -> raise Wrong_dom_value
    end)

  module Admin_mod_float = Default(struct
      type a = float

      let to_default ?v () =
        let v =
          match v with
            | Some v ->
              a_value (string_of_float v)
            | None ->
              a_value ""
        in

        let error = p ~a:[ a_class ["error"]; a_style "display:none"] [ ] in
        let d = input ~a:[ v ] ~input_type:`Text () in
        {
          node = div ~a:[ a_class ["dom_ext_float"] ] [ error; d ] ;
          value_ = `Input d;
          error = Some error ;
        }

      let to_dom f =
        to_default ~v:f ()

      let save d =
        match d.value_ with
          | `Input f ->
            let v = Dom_manip.get_opt_value f in
            handle_exception d.error "float" v (
              function
                | Some i -> float_of_string i
                | None -> raise Empty_value
            )
          | _ -> raise Wrong_dom_value

    end)

  module Admin_mod_string = Default(struct
      type a = string

      let to_default ?v () =
        let v =
          match v with
            | Some v -> v
            | None -> ""
        in

        let error = p ~a:[ a_class ["error"]; a_style "display:none"] [ ] in
        let d = Raw.textarea (pcdata v) in
        {
          node = div ~a:[ a_class ["dom_ext_string"] ] [ error; d ] ;
          value_ = `Textarea d;
          error = Some error ;
        }

      let to_dom s =
        to_default ~v:s ()

      let save d =
        match d.value_ with
          | `Textarea s ->
            let v = Dom_manip.get_opt_value_textarea s in
            handle_exception d.error "string" v (
              function
                | Some i -> i
                | None -> raise Empty_value
            )
          | _ -> raise Wrong_dom_value
    end)


  let display_list (type s) (module A : Admin_mod with type a = s) () =
    let nodes = div ~a:[ a_class ["dom_ext_list_elems"]] [] in
    let node = div ~a:[ a_class ["dom_ext_list"]] [ nodes ] in

    let v =
      {
        node ;
        value_ = `List [];
        error = None;
      }
    in

    let add_single_node ?d () =
      let d = match d with
        | Some d -> A.to_dom d
        | None -> A.to_default ()
      in
      v.value_ <-
        begin match v.value_ with
          | `List l -> `List (l @ [ d ])
          | _ -> assert false
        end;

      let single_node = div ~a:[ a_class ["dom_ext_list_elem"]] [ d.node ] in
      let btn =
        button ~a:[ a_onclick (fun _ ->
                      Manip.removeChild nodes single_node;
                      v.value_ <-
                        begin match v.value_ with
                          | `List l -> `List (List.filter (fun d2 -> d <> d2) l)
                          | _ -> assert false
                        end;
                      false
                    ); a_class [ "btn"; "btn-warning"]
                  ] ~button_type:`Button [ pcdata "delete" ]
      in
      Manip.appendChild single_node btn ;
      Manip.appendChild nodes single_node ;
    in

    let add_btn = button ~a:[ a_onclick (fun _ -> add_single_node (); false); a_class [ "btn"; "btn-info" ]] ~button_type:`Button [ pcdata "add" ] in
    Manip.appendChild node add_btn ;

    v,add_single_node



  module Admin_mod_list (A : Admin_mod) = Default(struct
      type a = A.a list

      let to_default ?v () =
        let v,add_single_node = display_list (module A) () in
        add_single_node () ;
        v

      let to_dom l =
        let v,add_single_node = display_list (module A) () in
        List.iter (
          fun el ->
            add_single_node ~d:el ()
        ) l;

        v

      let save d =
        match d.value_ with
          | `List l ->
            List.fold_left (
              fun acc e ->
                try (A.save e::acc)
                with Empty_value ->
                  acc
            ) [] (List.rev l)
          | _ -> raise Wrong_dom_value
    end)


  module Admin_mod_array (A : Admin_mod) = Default(struct
      type a = A.a array

      let to_default ?v () =
        let v,add_single_node = display_list (module A) () in
        add_single_node () ;
        v

      let to_dom a =
        let v,add_single_node = display_list (module A) () in

        Array.iter (
          fun el ->
            add_single_node ~d:el ()
        ) a;

        v

      let save d =
        match d.value_ with
          | `List l ->
            let l =
              List.fold_left (
                fun acc e ->
                  try (A.save e::acc)
                  with Empty_value ->
                    acc
              ) [] (List.rev l)
            in
            Array.of_list l
          | _ -> raise Wrong_dom_value

    end)


  module Admin_mod_option (A : Admin_mod) = Default(struct
      type a = A.a option

      let to_default ?v () =
        let d = A.to_default () in
        let node = div ~a:[ a_class ["dom_ext_option"]] [ d.node ] in
        {
          d with
            node;
        }

      let to_dom o =
        match o with
          | Some s ->
            let d = A.to_dom s in
            let node = div ~a:[ a_class ["dom_ext_option"]] [ d.node ] in
            {
              d with
                node;
            }
          | None -> to_default ()

      let save o =
        try
          Some (A.save o)
        with Empty_value ->
          None
    end)

}}
