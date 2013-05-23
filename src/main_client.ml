{client{

  open Eliom_content
  open Html5
  open D


  let get_time () =
    Js.to_float ((jsnew Js.date_now ())##getTime())

  let t = ref (get_time ())
  let interval = 1. /. 840. (* 840 instruction / sec *)

  let rec game_loop () =
    Chip8.emulate_cycle ();

    if Chip8.draw_flag () then
      Display.display ();
    Key.check ();

    let t' = get_time () in
    let d = t' -. !t in
    t:=t';
    if d > interval
    then begin
      game_loop ()
    end else begin
      lwt _ = Lwt_js.sleep (interval -. d) in
      game_loop ()
    end

  let init () =
    Display.init () ;
    Key.init () ;

    Lwt.async (
      fun _ ->
        try_lwt
          lwt _ = Chip8.load_game "pong1" in
          game_loop ()
        with exn ->
          Firebug.console##debug(Js.string (Printf.sprintf "exn: %s\n%!" (Printexc.to_string exn)));
          Lwt.return ()
    ) ;

    Manip.appendToBody (
      div ~a:[ a_class ["container"]] [
        h1 [ pcdata "CHIP8" ];
        Display.gfx_dom ;
        (* Chip8.hex_dom ; *)
        div [
          Display.canvas
        ]
      ]
    )

}}
