{client{

  open Eliom_content
  open Html5
  open D

  let games_div = div ~a:[ a_class ["game_list"; "clearfix"]] []

  let main_dom () =
    div [
      header [
        div [
          span ~a:[ a_class ["logo"]] [];
          span ~a:[ a_class ["logo_txt"]] [ pcdata "OCHIP8" ];
        ]
      ];
      div ~a:[ a_class [ "container"]] [
        Debug.box_dom;
        div ~a:[ a_class ["canvas_div"; "row"]] [
          div ~a:[ a_class ["span9"] ] [ Display.canvas ];
          div ~a:[ a_class ["span3"; "instruction"]] []
        ];
        games_div
      ]
    ]


  let game_dom game_name =
    let g = Hashtbl.find Chip8_game.games_htbl game_name in
    div ~a:[
      a_class [ "game"; "span3" ];
      a_onclick (fun _ ->
        Chip8_game.launch_game game_name; false)
    ] [
      img ~src:g.Chip8_game.img_path ~alt:g.Chip8_game.img_path ();
      span [ pcdata game_name ]
    ]


  let init () =
    Debug.init ();
    Display.init () ;
    Key.init () ;

    Lwt.async (
      fun _ ->
        lwt game_names =
          lwt games = %Chip8_game.available_game () in
          let g = List.map (
              fun g ->
                Hashtbl.add Chip8_game.games_htbl g.Chip8_game.name g ;
                g.Chip8_game.name
            ) games in
          Lwt.return g
        in

        let game_names =
          List.sort (
            fun g1 g2 -> compare g1 g2
          ) game_names
        in

        Manip.replaceAllChild games_div (List.map game_dom game_names);
        Lwt.return_unit
    );

    Manip.appendToBody (main_dom ())

}}
