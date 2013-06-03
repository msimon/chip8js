open Eliom_content
open Html5.F

module Chip8 =
  Eliom_registration.App (struct
    let application_name = "chip8"
  end)

let html_v =
  html
    (head (title (pcdata "Chip8 Emu")) [
       meta ~a:([a_charset "utf-8"; a_content "text/html"; a_http_equiv "Content-Type"]) () ;
       meta ~a:([a_name "Description"; a_content "Chip8 Emulator written in ocaml"]) () ;
       meta ~a:([a_property "og:type"; a_content "website"]) () ;
       meta ~a:([a_property "og:url"; a_content ("http://www.chip8.com")]) () ;
       meta ~a:([a_property "og:title"; a_content "Chip8 Emulator written in ocaml"]) () ;
       meta ~a:([a_property "og:site_name"; a_content "www.ochip8.com"]) () ;

       link ~rel:[ `Stylesheet ] ~href:(uri_of_string (fun () -> "/chip8.css")) ();
     ])
    (body [])

let main_handler _ _ =
  let _ : unit client_value = {{
  Eliom_client.onload (
    fun _ ->
      Main_client.init ()
  )
  }} in

  Lwt.return html_v

let admin_handler _ _ =
  let _ : unit client_value = {{
  Eliom_client.onload (
    fun _ ->
      Admin.init ()
  )
  }} in

  Lwt.return html_v

let _ =
  Chip8.register_service ~path:[ "" ]
    ~get_params:Eliom_parameter.unit
    main_handler

let _ =
  Chip8.register_service ~path:[ "admin" ]
    ~get_params:Eliom_parameter.unit
    admin_handler
