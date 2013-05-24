{client{

  open Eliom_content
  open Html5
  open D

  let init () =
    Debug.init ();
    Display.init () ;
    Key.init () ;

    let games_div = div [] in

    Lwt.async (
      fun _ ->
        lwt games = %Chip8_game.available_game () in
        let games =
          List.map (
            fun g ->
              span ~a:[
                a_style "cursor:pointer; margin:10px";
                a_onclick (fun _ ->
                  Debug.log "calling %s" g ;
                  Chip8_game.launch_game g; false)
              ] [
                pcdata g
              ]
          ) games
        in

        Manip.replaceAllChild games_div games ;
        Lwt.return_unit
    );

    Manip.appendToBody (
      div ~a:[ a_class ["container"]] [
        Debug.box_dom;
        h1 [ pcdata "CHIP8" ];
        div [
          Display.canvas
        ];
        games_div
      ]
    )

}}
