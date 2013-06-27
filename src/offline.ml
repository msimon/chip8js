{client{

  let online_status,update_online_status = Dom_react.S.create true
  let manifest_is_old,invalidate_manifest = Dom_react.E.create ()

  let _ =
    Lwt.async_exception_hook := (
      fun exn ->
        Debug.log "Lwt async error : %s" (Printexc.to_string exn);
        (*
          When the server restart, without changing the manifest, 'incorrect value' is raised.
        *)
        match exn with
          | Failure "unwrap_value: incorrect value" ->
            invalidate_manifest () ;
          | _ -> ()
    )

  let init () =
    if Js.Optdef.test ((Js.Unsafe.coerce Dom_html.window)##applicationCache) then
      ignore(Dom_events.listen (Dom_html.window##applicationCache)
          Dom_events.Typ.updateready (
          fun _ _ ->
            Dom_html.window##applicationCache##swapCache ();
            Dom_html.window##location##reload () ;
            true
        ))

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

    let _ =
      Dom_react.E.iter (
        fun _ ->
          update_online_status false
      ) manifest_is_old
    in

    update_online_status (Js.to_bool Dom_html.window##navigator##onLine)

}}
