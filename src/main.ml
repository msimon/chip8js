open Eliom_content
open Html5.F

module Chip8 =
  Eliom_registration.App (struct
    let application_name = "chip8"
  end)

let site_prefix = ""

let html_v cl =
  html ~a:[ a_manifest (uri_of_string (fun () -> "/cache.manifest")) ]
    (head
       (title (pcdata "OChip8")) [
       meta ~a:([a_charset "utf-8"; a_content "text/html"; a_http_equiv "Content-Type"]) () ;
       meta ~a:([a_name "Description"; a_content "Chip8 Emulator written in ocaml"]) () ;
       meta ~a:([a_property "og:type"; a_content "website"]) () ;
       meta ~a:([a_property "og:url"; a_content ("http://www.chip8.com")]) () ;
       meta ~a:([a_property "og:title"; a_content "Chip8 Emulator written in ocaml"]) () ;
       meta ~a:([a_property "og:site_name"; a_content "www.ochip8.com"]) () ;

       link ~rel:[ `Stylesheet ] ~href:(uri_of_string (fun () -> site_prefix ^ "/bootstrap.min.css")) ();
       link ~rel:[ `Stylesheet ] ~href:(uri_of_string (fun () -> site_prefix ^ "/chip8.css")) ();
     ])
    (body ~a:[ a_class [cl]] [])

let main_handler _ _ =
  let _ : unit client_value = {{
  Eliom_client.onload (
    fun _ ->
      Main_client.init ("about", %Service.about)
  )
}} in

Lwt.return (html_v "main")

let admin_handler _ _ =
  let _ : unit client_value = {{
  Eliom_client.onload (
    fun _ ->
      Admin.init ()
  )
}} in

Lwt.return (html_v "admin")

let about_handler _ _ =
  let _ : unit client_value = {{
  Eliom_client.onload (
    fun _ ->
      About.init ("home", %Service.main)
  )
}} in

Lwt.return (html_v "main")

let _ =
  Chip8.register Service.main main_handler;
  Chip8.register Service.admin admin_handler;
  Chip8.register Service.about about_handler
