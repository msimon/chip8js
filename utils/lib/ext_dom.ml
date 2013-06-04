{client{

  open Eliom_content
  open Html5
  open D

  (* type 'a dom = [ *)
  (*   | `Input of ([> Html5_types.div_content_fun ] as 'a) Eliom_content.Html5.D.elt *)
  (*   | `List of dom *)
  (* ] *)

  (* type 'a dom_ext = { *)
  (*   node : ([> Html5_types.div_content_fun ] as 'a) Eliom_content.Html5.D.elt ; *)
  (*   value : 'a dom *)
  (* } *)

  module type Dom_ext = sig
    type a
    val to_default : unit -> ([> Html5_types.div_content_fun ] as 'a) Eliom_content.Html5.D.elt
    val to_dom : a -> ([> Html5_types.div_content_fun ] as 'a) Eliom_content.Html5.D.elt
  end

  module Default(D : Dom_ext) : Dom_ext with type a = D.a = struct
    include D
  end

  module Dom_ext_int = Default(struct
      type a = int

      let to_default () =
        input ~input_type:`Text ()

      let to_dom i =
        input ~input_type:`Text ~a:[ a_value (string_of_int i) ] ()
    end)


  module Dom_ext_int32 = Default(struct
      type a = int32

      let to_default () =
        input ~input_type:`Text ()

      let to_dom i =
        input ~input_type:`Text ~a:[ a_value (Int32.to_string i) ] ()

    end)

  module Dom_ext_int64 = Default(struct
      type a = int64

      let to_default () =
        input ~input_type:`Text ()

      let to_dom i =
        input ~input_type:`Text ~a:[ a_value (Int64.to_string i) ] ()

    end)

  module Dom_ext_bool = Default(struct
      type a = bool

      let to_default () =
        assert false

      let to_dom b =
        assert false

    end)

  module Dom_ext_float = Default(struct
      type a = float

      let to_default () =
        input ~input_type:`Text ()

      let to_dom f =
        input ~input_type:`Text ~a:[ a_value (string_of_float f) ] ()

    end)

  module Dom_ext_string = Default(struct
      type a = string

      let to_default () =
        input ~input_type:`Text ()

      let to_dom s =
        input ~input_type:`Text ~a:[ a_value s ] ()

    end)

  module Dom_ext_list (A : Dom_ext) = Default(struct
      type a = A.a list

      let to_default () =
        div [ A.to_default () ]

      let to_dom l =
        let l = List.map (
            fun el ->
              A.to_dom el
          ) l
        in

        div l
    end)


  module Dom_ext_array (A : Dom_ext) = Default(struct
      type a = A.a array

      let to_default () =
        div [ A.to_default () ]

      let to_dom a =
        let l =
          Array.fold_left (
            fun acc el ->
              (A.to_dom el)::acc
          ) [] a
        in

        div (List.rev l)
    end)


  module Dom_ext_option (A : Dom_ext) = Default(struct
      type a = A.a option

      let to_default () =
        A.to_default ()

      let to_dom o =
        match o with
          | Some s -> A.to_dom s
          | None -> A.to_default ()

    end)

}}
