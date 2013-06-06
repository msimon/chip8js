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

  type dom_value = [
    | `Input of Html5_types.input Eliom_content.Html5.D.elt
    | `Select of Html5_types.select Eliom_content.Html5.D.elt * ((string * dom_value) list)
    | `List of dom_value list
    | `Record of (string * dom_value) list
  ]

  type ('a) dom_ext = {
    node : ([> Html5_types.div_content_fun ] as 'a) Eliom_content.Html5.D.elt ;
    value_ : dom_value
  }

  let node d = d.node
  let value d = d.value_

  module type Dom_ext = sig
    type a
    val to_default : unit -> ('a) dom_ext
    val to_dom : a -> ('a) dom_ext

    val save : dom_value -> a
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

      let save = function
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

      let save = function
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

      let save = function
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

      let save = function
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

      let save = function
        | `Input s ->
          let v = Dom_manip.get_opt_value s in
          begin match v with
            | Some v -> v
            | None -> raise Empty_value
          end;
        | _ -> raise Wrong_dom_value

    end)

  module Dom_ext_list (A : Dom_ext) = Default(struct
      type a = A.a list

      let to_default () =
        let d = A.to_default () in
        {
          node = div [ d.node ] ;
          value_ = `List [ d.value_ ]
        }

      let to_dom l =
        let l = List.map (
            fun el ->
              A.to_dom el
          ) l
        in

        {
          node = div (List.map (fun e -> e.node) l) ;
          value_ = `List (List.map (fun e -> e.value_) l) ;
        }

      let save =
        function
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
        let d = A.to_default () in
        {
          node = div [ d.node ] ;
          value_ = `List [ d.value_ ]
        }

      let to_dom a =
        let l =
          Array.fold_left (
            fun acc el ->
              (A.to_dom el)::acc
          ) [] a
        in

        let l = List.rev l in

        {
          node = div (List.map (fun e -> e.node) l) ;
          value_ = `List (List.map (fun e -> e.value_) l) ;
        }

      let save =
        function
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
