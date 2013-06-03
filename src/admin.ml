{server{
  let is_connected =
    server_function Json.t<unit> (
      fun _ ->
        (* todo check in eliom reg *)
        Lwt.return false
    )

  let sign_in =
    server_function Json.t<string> (
      fun pwd ->
        Lwt.return true
    )

}}


{client{

  open Eliom_content
  open Html5
  open D

  module DM = Dom_manip

  let connected_dom =
    div ~a:[ a_class [ "admin"; "connected" ]] [

    ]

  let not_connected_dom =
    let admin_password = input ~input_type:`Text () in
    let sign_in () =
      match DM.get_opt_value admin_password with
        | Some pwd ->
          Lwt.async (
            fun _ ->
              lwt logged = %sign_in pwd in
              if logged then Manip.appendToBody connected_dom
              else ();
              Lwt.return_unit
          )
        | None -> ()
    in

    div ~a:[ a_class [ "admin"; "not_connected" ]] [
      admin_password ;
      button ~button_type:`Button ~a:[ a_onclick (fun _ -> sign_in (); false)] [
        pcdata "Submit"
      ]
    ]

  let init () =
    Lwt.async (
      fun _ ->
        lwt is_connected = %is_connected () in

        let dom =
          if is_connected then connected_dom
          else not_connected_dom
        in

        Manip.appendToBody dom;
        Lwt.return_unit
    )
}}
