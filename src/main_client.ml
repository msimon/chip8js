{client{

  open Eliom_content
  open Html5
  open D

  let games_div = div ~a:[ a_class ["game_list"]] []

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


  let game_dom name g =
    span ~a:[
      a_style "cursor:pointer; margin:10px";
      a_onclick (fun _ ->
        Chip8_game.launch_game g; false)
    ] [
      pcdata name
    ]


  let init () =
    Debug.init ();
    Display.init () ;
    Key.init () ;

    Lwt.async (
      fun _ ->
        lwt _ =
          if Hashtbl.length Chip8_game.games_htbl = 0 then begin
            lwt games = %Chip8_game.available_game () in
            List.iter (
              fun g ->
                Hashtbl.add Chip8_game.games_htbl g.Chip8_game.name g
            ) games;
            Lwt.return_unit
          end else Lwt.return_unit
        in

        let games =
          Hashtbl.fold (
            fun name g acc -> (game_dom name g)::acc
          ) Chip8_game.games_htbl []
        in

        Manip.replaceAllChild games_div games ;
        Lwt.return_unit
    );

    Manip.appendToBody (main_dom ())

}}
