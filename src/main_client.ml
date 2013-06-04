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
            fun name g acc ->
              (span ~a:[
                 a_style "cursor:pointer; margin:10px";
                 a_onclick (fun _ ->
                   Chip8_game.launch_game g; false)
               ] [
                 pcdata name
               ])::acc
          ) Chip8_game.games_htbl []
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
