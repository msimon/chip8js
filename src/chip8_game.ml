{server{

  exception Game_not_found of string
  exception Game_read_error of string

  let games = [
    "15puzzle"; "blinky"; "blitz"; "brix"; "connect4"; "guess"; "hidden"; "invaders"; "kaleid";
    "maze"; "merlin"; "missile"; "pong"; "pong2"; "puzzle"; "syzygy"; "tank"; "tetris"; "tictac" ;
    "ufo"; "vbrix"; "vers"; "wipeoff" ;
  ]


  let available_game =
    server_function Json.t<unit> (
      fun _ -> Lwt.return games
    )

  let load_game =
    server_function Json.t<string> (
      fun game ->
        let game = String.lowercase (String.trim game) in
        if List.mem game games then begin
          let in_chan =
            try open_in_bin ("./public/games/" ^ (String.uppercase game))
            with Sys_error exn ->
              raise (Game_read_error exn)
          in

          let rec read pos s =
            if input in_chan s pos 200 = 0 then s
            else begin
              let pos = String.length s in
              let s_ = String.make (200 + pos) '\032' in
              String.blit s 0 s_ 0 pos;
              read pos s_
            end
          in

          let s = read 0 (String.make 200 '\032') in
          close_in in_chan;

          Lwt.return (String.trim s)
        end else
          raise (Game_not_found game)
    )
}}

{client{
  module M = Mem_req
  module C = Config

  let get_time () =
    Js.to_float ((jsnew Js.date_now ())##getTime())


  let load_game game =
    M.initialize () ;
    lwt game_str = %load_game game in

    String.iteri (
      fun i c ->
        M.memory.(C.game_memory_init + i) <- int_of_char c
    ) game_str;

    Lwt.return ()


  let start_game_loop () =
    let now = get_time () in
    let t = ref now in
    let timer_t = ref now in
    let timer_late = ref 0. in

    (* d: we calculate the time the instruction took *)
    (* then we substract it the rate *)
    (* if it's faster than the rate we sleep for the difference *)
    (* if it's slower then the rate we keep the difference and apply it
       to the next instruction to try to catch up
    *)

    let decr_timer () =
      let t' = get_time () in
      let d = t' -. !timer_t +. !timer_late in
      timer_t:=t';
      if d < Config.timer_rate then begin
        timer_late := d ;
      end else begin
        timer_late := d -. C.timer_rate ;
        if !M.delay_timer > 0 then decr(M.delay_timer);
        if !M.sound_timer > 0 then decr(M.sound_timer);
      end
    in

    let rec game_loop late =
      Chip8_emu.emulate_cycle ();
      decr_timer ();

      if Chip8_emu.draw_flag () then
        Display.display ();

      Key.check ();

      let t' = get_time () in
      let d = t' -. !t in
      t:=t';

      let late = Config.game_rate -. d +. late in

      if late < 0. then begin
        game_loop late
      end else begin
        lwt _ = Lwt_js.sleep (late /. 1000.) in
        game_loop 0.
      end
    in

    game_loop 0.

  let current_game_thread = ref None

  let launch_game game =
    let _ =
      match !current_game_thread with
        | Some t -> Lwt.cancel t
        | None -> ()
    in
    current_game_thread := Some (
        try_lwt
          lwt _ = load_game game in
          start_game_loop ()
        with exn ->
          Lwt.return ()
      )
}}
