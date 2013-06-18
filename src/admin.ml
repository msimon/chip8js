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

  let container = div ~a:[ a_class [ "global_container" ]] []

  let _ =
    Lwt.async_exception_hook := (
      fun exn ->
        Debug.log "Error Lwt_async: %s" (Printexc.to_string exn)
    )

  let connected_dom () =
    let games_s,games_u = Dom_react.S.create [] in
    let games_u f = games_u (f (Dom_react.S.value games_s)) in
    let open_s,open_u = Dom_react.S.create (-1) in
    let register_sig = ref [] in

    let game_dom ~action n =
      let name,path =
        match action with
          | `Create -> "",""
          | `Edit g -> g.Chip8_game.name,g.Chip8_game.path
      in

      let edit_game g =
        let g = Chip8_game.Admin_mod_game.save g in
        match action with
          | _ ->

            let old_name =
              match action with
                | `Create -> None
                | `Edit g_ -> Some g_.Chip8_game.name
            in

            begin match old_name with
              | Some old_name ->
                if g.Chip8_game.name <> old_name &&
                   List.exists (fun g_ -> g_.Chip8_game.name = g.Chip8_game.name) (Dom_react.S.value games_s)
                then (failwith "name must be unique")
              | None ->
                if List.exists (fun g_ -> g_.Chip8_game.name = g.Chip8_game.name) (Dom_react.S.value games_s)
                then (failwith "name must be unique")
            end;

            games_u (fun gs ->
              let gs =
                List.filter (
                  fun g_ ->
                    match old_name with
                      | Some old_name ->
                        g_.Chip8_game.name <> old_name
                      | None -> true
                ) gs
              in

              gs @ [ g ]
            );

            Lwt.async (
              fun _ ->
                %edit_game (old_name,g)
            )
      in

      let delete_btn =
        let delete_act g =
          if Js.to_bool (Dom_html.window##confirm (Js.string (Printf.sprintf "Are you sure to delete %s ?" g.Chip8_game.name))) then begin
            Lwt.async (fun _ -> %delete_game g.Chip8_game.name);
            open_u (-1) ;
            games_u (fun gs ->
              List.filter (
                fun g_ ->
                  g_.Chip8_game.name <> g.Chip8_game.name
              ) gs
            )
          end
        in

        match action with
          | `Edit g ->
            button ~button_type:`Button ~a:[ a_onclick (fun _ -> delete_act g; false); a_class ["btn";"btn-danger"; "button-delete"]] [ pcdata "Delete" ];
          | `Create ->
            button ~button_type:`Button ~a:[ a_style "display:none" ] [];
      in

      let d =
        Dom_react.S.map (
          fun o ->
            let g =
              match action with
                | `Edit g ->
                  Some g
                | `Create -> None
            in

            let g_dom =
              (let module M = Admin_mod.Admin_mod_option(Chip8_game.Admin_mod_game)
               in M.to_dom) g ;
            in

            if o = n then begin
              li ~a:[ a_class ["game"] ] [
                Raw.a ~a:[ a_onclick (fun _ -> open_u (-1); false)] [
                  pcdata (if name = "" then "Create new game" else name)
                ];
                div ~a:[ a_class ["edit"]] [
                  Admin_mod.node g_dom ;
                  div ~a:[ a_class ["game_button_action"; "clearfix"]] [
                    delete_btn;
                    button ~button_type:`Button ~a:[ a_onclick (fun _ -> open_u (-1); false); a_class [ "btn"; "button-cancel"] ] [ pcdata "Cancel" ];
                    button ~button_type:`Button ~a:[ a_onclick (fun _ -> edit_game g_dom; false); a_class [ "btn"; "btn-success"; "button-save"]] [ pcdata "Save" ];
                  ]
                ]
              ]
            end else begin
              li ~a:[ a_class ["game"]; a_onclick (fun _ ->  open_u n; false)] [
                Raw.a [ pcdata (if name = "" then "Create new game" else name) ]
              ]
            end
        ) open_s
      in
      register_sig := d :: !register_sig ;
      R.node d
    in

    let games_dom = R.node (
        Dom_react.S.map (
          fun games ->
            (* clean previous signal *)
            List.iter Dom_react.S.stop !register_sig;
            register_sig := [];

            open_u (-1);
            (* regenerate the dom *)
            let games =
              List.sort (
                fun g1 g2 -> compare g1.Chip8_game.name g2.Chip8_game.name
              ) games
            in

            let games_1,games_2,_ =
              List.fold_left (
                fun (acc1,acc2,n) g ->
                  if n mod 2 = 0 then g::acc1,acc2,(n+1)
                  else acc1,g::acc2,(n+1)
              ) ([],[],0) games
            in

            let d1,_ =
              List.fold_left (
                fun (acc,n) g ->
                  (game_dom ~action:(`Edit g) n::acc,n + 1)
              ) ([],1) games_1
            in

            let d2,_ =
              List.fold_left (
                fun (acc,n) g ->
                  (game_dom ~action:(`Edit g) n::acc,n + 1)
              ) ([],((List.length games_1) + 1))  games_2
            in

            div ~a:[ a_class ["games_list"] ] [
              div ~a:[ a_class ["clearfix"]] [
                div ~a:[ a_class ["span6"]] [
                  ul ~a:[ a_class ["nav"; "nav-tabs";"nav-stacked"]] d1
                ];
                div ~a:[ a_class ["span6"]] [
                  ul ~a:[ a_class ["nav"; "nav-tabs";"nav-stacked"]] d2
                ];
              ];
              div ~a:[ a_class ["new_game_div"]] [
                ul ~a:[ a_class ["nav"; "nav-tabs";"nav-stacked"]] ([ game_dom ~action:`Create 0 ])
              ]
            ]
        ) games_s
      )
    in

    Lwt.async (
      fun _ ->
        lwt games = %fetch_games () in

        games_u (fun _ -> games) ;
        Lwt.return ()
    );

    let dump_done_txt = span ~a:[a_style "display:none"] [ pcdata "done!"] in

    div ~a:[ a_class [ "connected" ]] [
      h3 [ pcdata "Games configuration" ];
      games_dom ;
      div ~a:[ a_class ["dump_btn_container"]] [
        button ~button_type:`Button ~a:[
          a_onclick (fun _ -> Lwt.async (fun _ -> lwt _ = %dump () in Manip.SetCss.display dump_done_txt "inline"; Lwt.return_unit); false);
          a_class [ "btn"; "btn-primary"]
        ] [ pcdata "Dump configuration to file" ];
        dump_done_txt;
      ]
    ]

  let not_connected_dom connexion_u =
    let error_dom = p ~a:[ a_class ["error"]; a_style "display:none" ] [ pcdata "password mismatch" ] in
    let admin_password = input ~input_type:`Password () in

    let sign_in () =
      match DM.get_opt_value admin_password with
        | Some pwd ->
          Lwt.async (
            fun _ ->
              lwt logged = %sign_in pwd in
              connexion_u logged;
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
      button ~button_type:`Button ~a:[ a_onclick (fun _ -> sign_in (); false); a_class ["btn"; "btn-primary"]] [
        pcdata "Connect"
      ]
    ]

  let init () =
    let connected,connexion_u = Dom_react.S.create false in

    let sign_out () =
      Lwt.async (fun _ -> %sign_out ());
      connexion_u false ;
      Manip.replaceAllChild container [ not_connected_dom connexion_u ]
    in

    Manip.appendToBody (
      div [
        div ~a:[ a_class ["navbar"; "navbar-inverse"; "header"]] [
          div ~a:[ a_class ["navbar-inner"]] [
            Raw.a ~a:[ a_class ["brand"]] [ pcdata "Admin mod" ];
            R.node (
              Dom_react.S.map (
                function
                  | true ->
                    ul ~a:[ a_class [ "nav "]][
                      li [
                        Raw.a ~a:[ a_onclick (fun _ -> sign_out (); false)] [ pcdata "Sign out" ]
                      ]
                    ]
                  | false -> ul ~a:[ a_style "display:none"] []
              ) connected
            )
          ]
        ];
        container;
      ]
    );

    Lwt.async (
      fun _ ->
        lwt is_connected = %is_connected () in

        connexion_u is_connected ;

        let dom =
          if is_connected then connected_dom ()
          else not_connected_dom connexion_u
        in

        Manip.replaceAllChild container [ dom ];
        Lwt.return_unit
    )
}}
