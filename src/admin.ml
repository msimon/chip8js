{server{

  let session = Eliom_reference.eref ~persistent:"admin" ~scope:Eliom_common.default_session_scope false

  let is_connected =
    server_function Json.t<unit> (
      fun _ ->
        Eliom_reference.get session
    )

  let sign_in =
    server_function Json.t<string> (
      fun pwd ->
        if pwd = (Config.get "admin-password") then
          lwt _ = Eliom_reference.set session true in
          Lwt.return_true
        else
          Lwt.return_false
    )

}}


{client{

  open Eliom_content
  open Html5
  open D

  module DM = Dom_manip

  let container = div ~a:[ a_class ["admin"; "container" ]] []

  let connected_dom =
    div ~a:[ a_class [ "admin"; "connected" ]] [
      p [
        pcdata "hello admin"
      ]
    ]

  let not_connected_dom =
    let admin_password = input ~input_type:`Text () in
    let sign_in () =
      match DM.get_opt_value admin_password with
        | Some pwd ->
          Lwt.async (
            fun _ ->
              lwt logged = %sign_in pwd in
              if logged then Manip.replaceAllChild container [ connected_dom ]
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
    Manip.appendToBody container;

    Lwt.async (
      fun _ ->
        lwt is_connected = %is_connected () in

        let dom =
          if is_connected then connected_dom
          else not_connected_dom
        in

        Manip.replaceAllChild container [ dom ];
        Lwt.return_unit
    )
}}
