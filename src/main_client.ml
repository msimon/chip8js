{client{

  open Eliom_content
  open Html5
  open D

  module Gs = Chip8_game.Gs

  let games_div = div ~a:[ a_class ["game_list"; "clearfix"]] []

  let instruction,update_instruction = Dom_react.S.create None
  let online_status,update_online_status = Dom_react.S.create true


  let main_dom () =
    let instruction_dom =
      Dom_react.S.map (
        function
          | None -> div ~a:[ a_class ["span3"; "instruction"]] []
          | Some g ->
            let controls_dom =
              match g.Chip8_game.controls with
                | Some s ->
                  div [
                    h3 [ pcdata "Controls" ];
                    p (Dom_manip.nl_to_br s);
                  ]
                | None ->
                  div ~a:[ a_style "display:none" ] []
            in
            let instruction_dom =
              match g.Chip8_game.instruction with
                | Some s ->
                  div [
                    h3 [ pcdata "Instruction" ];
                    p (Dom_manip.nl_to_br s)
                  ]
                | None ->
                  div ~a:[ a_style "display:none" ] []
            in
            let information_dom =
              match g.Chip8_game.information with
                | Some s ->
                  div [
                    h3 [ pcdata "Information" ];
                    p (Dom_manip.nl_to_br s)
                  ]
                | None ->
                  div ~a:[ a_style "display:none" ] []
            in

            div ~a:[ a_class ["span3"; "instruction"]] [
              controls_dom;
              instruction_dom ;
              information_dom
            ]
      ) instruction
    in

    let online_status =
      Dom_react.S.map (
        function
          | true ->
            span ~a:[ a_style "display:none" ] []
          | false ->
            span ~a:[ a_class ["online_status"]] [ pcdata "offline"]
      ) online_status
    in

    div [
      header [
        div [
          span ~a:[ a_class ["logo"]] [];
          span ~a:[ a_class ["logo_txt"]] [ pcdata "OCHIP8" ];
          R.node online_status
        ]
      ];
      div ~a:[ a_class [ "container"]] [
        Debug.box_dom;
        div ~a:[ a_class ["canvas_div"; "row"]] [
          div ~a:[ a_class ["span9"] ] [ Display.canvas ];
          R.node instruction_dom
        ];
        games_div
      ]
    ]


  let game_dom canvas_js game_name =
    let g = Hashtbl.find Chip8_game.games_htbl game_name in
    div ~a:[
      a_class [ "game"; "span3" ];
      a_onclick (fun _ ->
        update_instruction (Some g);
        canvas_js##scrollIntoView (Js._false);
        Chip8_game.launch_game game_name;
        false
      )
    ] [
      img ~src:g.Chip8_game.img_path ~alt:g.Chip8_game.img_path ();
      span [ pcdata game_name ]
    ]

  let init_online_status () =
    let _ =
      Dom_events.listen (Obj.magic Dom_html.window)
        Dom_events.Typ.online (
        fun _ _ ->
          update_online_status true;
          Debug.log "online";
          true
      )
    in

    let _ =
      Dom_events.listen (Obj.magic Dom_html.window)
        Dom_events.Typ.offline (
        fun _ _ ->
          update_online_status false;
          Debug.log "offline";
          true
      )
    in

    update_online_status (Js.to_bool Dom_html.window##navigator##onLine)


  let init () =
    Debug.init ();
    Key.init () ;
    let canvas_js = Display.init () in
    init_online_status ();

    (* Loading game that we have in local storage *)
    let games = Gs.list_of_storage () in

    List.iter (
      fun (_,g) ->
        (* we must have a try case in case the game record change *)
        try
          let g = Deriving_Json.from_string Json.t<Chip8_game.game> g in
          Hashtbl.add Chip8_game.games_htbl g.Chip8_game.name g
        with _ -> ()
    ) games;

    Lwt.async (
      fun _ ->
        (* if we have a connexion, then check if hash are equal, if not or game missing: update localstorage *)
        lwt game_names,notload =
          lwt games = %Chip8_game.available_game () in
          let g = List.fold_left (
              fun (names,notload) (game_name,game_hash) ->
                Gs.fetch_storage_map (
                  fun storage ->
                    try
                      let lg = Deriving_Json.from_string Json.t<Chip8_game.game> (Gs.get storage game_name) in
                      let notload =
                        if lg.Chip8_game.hash <> game_hash then game_name::notload
                        else notload
                      in
                      ((game_name::names),notload)
                    with _ ->
                      (game_name::names, game_name::notload)
                ) (fun _ ->
                  (* if no localstorage, fallback *)
                  (game_name::names, game_name::notload)
                );
            ) ([],[]) games in
          Lwt.return g
        in

        lwt games = %Chip8_game.load_game_info notload in
        List.iter (
          fun g ->
            Hashtbl.replace Chip8_game.games_htbl g.Chip8_game.name g;
            Gs.fetch_storage_iter (
              fun storage ->
                Gs.add storage g.Chip8_game.name (Deriving_Json.to_string Json.t<Chip8_game.game> g)
            );
        ) games ;

        let game_names =
          List.sort (
            fun g1 g2 -> compare g1 g2
          ) game_names
        in

        Manip.replaceAllChild games_div (List.map (game_dom canvas_js) game_names);
        Lwt.return_unit
    );

    Manip.appendToBody (main_dom ())

}}
