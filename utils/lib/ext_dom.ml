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
    | `Select of Html5_types.select Eliom_content.Html5.D.elt * ((string * ('a dom_ext Lazy.t) list) list)
    | `List of 'a dom_ext list
    | `Record of (string * 'a dom_ext) list
  ]

  and ('a) dom_ext = {
    node : 'a Eliom_content.Html5.D.elt ;
    mutable value_ : 'a dom_value
  }

  let node d = d.node
  let value d = d.value_

  module type Dom_ext = sig
    type a
    val to_default : unit -> [ Html5_types.div_content_fun ] dom_ext
    val to_dom : a -> [ Html5_types.div_content_fun ] dom_ext

    val save : [ Html5_types.div_content_fun ] dom_ext -> a
  end

  module Default(D : Dom_ext) : Dom_ext with type a = D.a = struct
    include D
  end

  module Dom_ext_int = Default(struct
      type a = int

      let to_default () =
        let d = input ~input_type:`Text () in
        {
          node = d ;
          value_ = `Input d
        }

      let to_dom i =
        let d = input ~input_type:`Text ~a:[ a_value (string_of_int i) ] () in
        {
          node = d ;
          value_ = `Input d
        }

      let save d =
        match d.value_ with
          | `Input i ->
            let v = Dom_manip.get_opt_value i in
            begin match v with
              | Some i -> int_of_string i
              | None -> raise Empty_value
            end;
          | _ -> raise Wrong_dom_value

    end)


  module Dom_ext_int32 = Default(struct
      type a = int32

      let to_default () =
        let d = input ~input_type:`Text () in
        {
          node = d ;
          value_ = `Input d
        }

      let to_dom i =
        let d = input ~input_type:`Text ~a:[ a_value (Int32.to_string i) ] () in
        {
          node = d ;
          value_ = `Input d
        }

      let save d =
        match d.value_ with
          | `Input i ->
            let v = Dom_manip.get_opt_value i in
            begin match v with
              | Some i -> Int32.of_string i
              | None -> raise Empty_value
            end;
          | _ -> raise Wrong_dom_value

    end)

  module Dom_ext_int64 = Default(struct
      type a = int64

      let to_default () =
        let d = input ~input_type:`Text () in
        {
          node = d ;
          value_ = `Input d
        }

      let to_dom i =
        let d = input ~input_type:`Text ~a:[ a_value (Int64.to_string i) ] () in
        {
          node = d ;
          value_ = `Input d
        }

      let save d =
        match d.value_ with
        | `Input i ->
          let v = Dom_manip.get_opt_value i in
          begin match v with
            | Some i -> Int64.of_string i
            | None -> raise Empty_value
          end;
        | _ -> raise Wrong_dom_value

    end)

  module Dom_ext_bool = Default(struct
      type a = bool

      let to_default () =
        assert false

      let to_dom b =
        assert false

      let save _ =
        assert false
    end)

  module Dom_ext_float = Default(struct
      type a = float

      let to_default () =
        let d = input ~input_type:`Text () in
        {
          node = d ;
          value_ = `Input d
        }

      let to_dom f =
        let d = input ~input_type:`Text ~a:[ a_value (string_of_float f) ] () in
        {
          node = d ;
          value_ = `Input d
        }

      let save d =
        match d.value_ with
        | `Input f ->
          let v = Dom_manip.get_opt_value f in
          begin match v with
            | Some f -> float_of_string f
            | None -> raise Empty_value
          end;
        | _ -> raise Wrong_dom_value

    end)

  module Dom_ext_string = Default(struct
      type a = string

      let to_default () =
        let d = input ~input_type:`Text () in
        {
          node = d ;
          value_ = `Input d
        }

      let to_dom s =
        let d = input ~input_type:`Text ~a:[ a_value s ] () in
        {
          node = d ;
          value_ = `Input d
        }

      let save d =
        match d.value_ with
        | `Input s ->
          let v = Dom_manip.get_opt_value s in
          begin match v with
            | Some v -> v
            | None -> raise Empty_value
          end;
        | _ -> raise Wrong_dom_value

    end)


  let display_list (type s) (module A : Dom_ext with type a = s) () =
    let nodes = div ~a:[ a_class ["nodes"]] [] in
    let node = div ~a:[ a_class ["dom_ext_list"]] [ nodes ] in

    let v =
      {
        node ;
        value_ = `List []
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

      let single_node = div ~a:[ a_class ["node"]] [ d.node ] in
      let btn =
        button ~a:[ a_onclick (fun _ ->
                      Manip.removeChild nodes single_node;
                      v.value_ <-
                        begin match v.value_ with
                          | `List l -> `List (List.filter (fun d2 -> d <> d2) l)
                          | _ -> assert false
                        end;
                      false
                    )
                  ] ~button_type:`Button [ pcdata "deleted" ]
      in
      Manip.appendChild single_node btn ;
      Manip.appendChild nodes single_node ;
    in

    let add_btn = button ~a:[ a_onclick (fun _ -> add_single_node (); false)] ~button_type:`Button [ pcdata "add" ] in
    Manip.appendChild node add_btn ;

    v,add_single_node



  module Dom_ext_list (A : Dom_ext) = Default(struct
      type a = A.a list

      let to_default () =
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
            let l =
              List.fold_left (
                fun acc e ->
                  try
                    A.save e::acc
                  with _ ->
                    acc
              ) [] l
            in

            if List.length l = 0 then raise Empty_value;

            l
          | _ -> raise Wrong_dom_value
    end)


  module Dom_ext_array (A : Dom_ext) = Default(struct
      type a = A.a array

      let to_default () =
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
                  try
                    A.save e::acc
                  with _ ->
                    acc
              ) [] l
            in

            if List.length l = 0 then raise Empty_value;

            Array.of_list l
          | _ -> raise Wrong_dom_value

    end)


  module Dom_ext_option (A : Dom_ext) = Default(struct
      type a = A.a option

      let to_default () =
        A.to_default ()

      let to_dom o =
        match o with
          | Some s -> A.to_dom s
          | None -> A.to_default ()

      let save o =
        try
          Some (A.save o)
        with _ ->
          None
    end)

}}
