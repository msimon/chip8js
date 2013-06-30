{server{

  let check_connexion =
    server_function Json.t<unit> (
      fun _ -> Lwt.return_unit
    )

}}

{client{

  open Eliom_client

  let online_status,update_online_status = Dom_react.S.create true

  let check_time = ref 1.

  let check_connexion () =
    check_time := !check_time *. 2.;
    Lwt.async (
      fun _ ->
        Debug.log "Cheking connexion in %f" !check_time ;
        lwt _ = Lwt_js.sleep !check_time in
        lwt _ = %check_connexion () in
        update_online_status true;
        Lwt.return_unit
    )


  let _ =
    Lwt.async_exception_hook := (
      fun exn ->
        Debug.log "Lwt async error : %s" (Printexc.to_string exn);
        (*
          When the server restart, without changing the manifest, 'incorrect value' is raised.
        *)

        match exn with
          | Failure "unwrap_value: incorrect value" ->
            update_online_status false
          | e when Printexc.to_string e  = "Eliom_request.Failed_request(0)" ->
            update_online_status false;
            check_connexion ()
          | _ -> ()
    )

  let _ =
    if Js.Optdef.test ((Js.Unsafe.coerce Dom_html.window)##applicationCache) then
      ignore(Dom_events.listen (Dom_html.window##applicationCache)
          Dom_events.Typ.updateready (
          fun _ _ ->
            Dom_html.window##applicationCache##swapCache ();
            Dom_html.window##location##reload () ;
            true
        ))

  let init () =
    let _ =
      Dom_events.listen Dom_html.window
        Dom_events.Typ.online (
        fun _ _ ->
          update_online_status true;
          true
      )
    in

    let _ =
      Dom_events.listen Dom_html.window
        Dom_events.Typ.offline (
        fun _ _ ->
          update_online_status false;
          true
      )
    in

    update_online_status (Js.to_bool Dom_html.window##navigator##onLine)

}}
