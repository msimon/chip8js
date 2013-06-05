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

  let sign_out =
    server_function Json.t<unit> (
      fun _ ->
        lwt _ = Eliom_reference.set session false in
        Lwt.return_false
    )

  let fetch_games =
    server_function Json.t<unit> (
      fun _ ->
        let l = Hashtbl.fold (
            fun _ g acc ->
              g::acc
          ) Chip8_game.games_htbl []
        in

        Lwt.return l
    )

  let edit_game =
    server_function Json.t<((string option) * Chip8_game.game)> (
      fun (old_name,g) ->
        match_lwt Eliom_reference.get session with
          | true ->
            begin match old_name with
              | Some on ->
                Hashtbl.remove Chip8_game.games_htbl on;
                Hashtbl.add Chip8_game.games_htbl g.Chip8_game.name g
              | None ->
                Hashtbl.add Chip8_game.games_htbl g.Chip8_game.name g
            end;
            Lwt.return_unit
          | false -> Lwt.return_unit
    )

  let delete_game =
    server_function Json.t<string> (
      fun name ->
        Hashtbl.remove Chip8_game.games_htbl name;
        Lwt.return ()
    )

  let dump =
    server_function Json.t<unit> (
      fun () ->
        Chip8_game.dump_into_file ();
        Lwt.return ()
    )

}}


{client{

  open Eliom_content
  open Html5
  open D

  module DM = Dom_manip

  let container = div ~a:[ a_class ["admin"; "global_container" ]] []

  let rec connected_dom () =
    let games_s,games_u = Dom_react.S.create [] in
    let games_u f = games_u (f (Dom_react.S.value games_s)) in
    let open_s,open_u = Dom_react.S.create (-1) in

    let sign_out () =
      Lwt.async (
        fun _ ->
          %sign_out ()
      );
      Manip.replaceAllChild container [ not_connected_dom () ]
    in

    let game_dom ~action n =
      let name,path =
        match action with
          | `Create -> "",""
          | `Edit g -> g.Chip8_game.name,g.Chip8_game.path
      in

      let edit_game g_ =

        let g_ = Chip8_game.Dom_ext_game.save (Ext_dom.value g_) in

        Debug.log "name: %s, path: %s, game_rate: %f, timer_rate: %f, game_data: %s"
          g_.Chip8_game.name
          g_.Chip8_game.path
          (match g_.Chip8_game.game_rate with Some f -> f | None -> 0.)
          (match g_.Chip8_game.timer_rate with Some f -> f | None -> 0.)
          (match g_.Chip8_game.game_data with Some s -> s | None -> "null")
        ;

        match action with
          | `Edit g when
              g.Chip8_game.name <> g_.Chip8_game.name &&
              List.exists (fun g -> g.Chip8_game.name = g_.Chip8_game.name) (Dom_react.S.value games_s)
            -> (failwith "name must be unique")
          | _ ->
            games_u (fun gs -> g_::gs);

            Lwt.async (
              fun _ ->
                let old_name =
                  match action with
                    | `Create -> None
                    | `Edit g -> Some g.Chip8_game.name
                in

                %edit_game (old_name,g_)
            )
      in

      let delete_btn =
        let delete_act g =
          if Js.to_bool (Dom_html.window##confirm (Js.string (Printf.sprintf "Are you sure to delete %s ?" g.Chip8_game.name))) then
            Lwt.async (fun _ -> %delete_game g.Chip8_game.name)
        in

        match action with
          | `Edit g ->
            button ~button_type:`Button ~a:[ a_onclick (fun _ -> delete_act g; false)] [ pcdata "Delete" ];
          | `Create ->
            button ~button_type:`Button ~a:[ a_style "display:none" ] [];
      in

      let d =
        Dom_react.S.map (
          fun o ->
            let g =
              match action with
                | `Edit g -> Some g
                | `Create -> None
            in

            let g_dom =
              (let module M = Ext_dom.Dom_ext_option(Chip8_game.Dom_ext_game)
               in M.to_dom) g ;
            in

            if o = n then begin
              div ~a:[ a_class ["game"]] [
                h3 ~a:[ a_onclick (fun _ -> open_u (-1); false)] [
                  pcdata (if name = "" then "Create new game" else name)
                ];
                div ~a:[ a_class ["edit"]] [
                  Ext_dom.node g_dom ;
                  button ~button_type:`Button ~a:[ a_onclick (fun _ -> edit_game g_dom; false)] [ pcdata "Save" ];
                  delete_btn;
                ]
              ]
            end else begin
              div ~a:[ a_class ["game"]; a_onclick (fun _ ->  open_u n; false)] [
                h3 [ pcdata (if name = "" then "Create new game" else name) ]
              ]
            end
        ) open_s
      in
      R.node d
    in

    let games_dom = R.node (
        Dom_react.S.map (
          fun games ->
            open_u (-1);
            let d,_ =
              List.fold_left (
                fun (acc,n) g ->
                  (game_dom ~action:(`Edit g) n::acc,n + 1)
              ) ([ game_dom ~action:`Create 0 ],1) games
            in

            div d
        ) games_s
      )
    in

    Lwt.async (
      fun _ ->
        lwt games = %fetch_games () in
        games_u (fun _ -> games) ;
        Lwt.return ()
    );

    div ~a:[ a_class [ "connected" ]] [
      header [
        h2 [ pcdata "Hello admin !"];
        span ~a:[ a_onclick (fun _ -> sign_out (); false)] [ pcdata "Sign out"];
      ];
      h1 [ pcdata "Games configuration" ];
      games_dom ;
      button ~button_type:`Button ~a:[ a_onclick (fun _ -> Lwt.async (fun _ -> %dump ()); false) ] [ pcdata "DUMP!" ]
    ]

  and not_connected_dom () =
    let error_dom = p ~a:[ a_class ["error"]; a_style "display:none" ] [ pcdata "password mismatch" ] in
    let admin_password = input ~input_type:`Password () in

    let sign_in () =
      match DM.get_opt_value admin_password with
        | Some pwd ->
          Lwt.async (
            fun _ ->
              lwt logged = %sign_in pwd in
              if logged then Manip.replaceAllChild container [ connected_dom () ]
              else Manip.SetCss.display error_dom "block" ;
              Lwt.return_unit
          )
        | None -> Manip.SetCss.display error_dom "block"
    in

    Manip.Ev.onkeydown admin_password (
      fun ev ->
        let key = ev##keyCode in
        if key = Keycode.return then sign_in ()
        else Manip.SetCss.display error_dom "none";
        true
    );

    div ~a:[ a_class [ "not_connected" ]] [
      error_dom ;
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
          if is_connected then connected_dom ()
          else not_connected_dom ()
        in

        Manip.replaceAllChild container [ dom ];
        Lwt.return_unit
    )
}}
