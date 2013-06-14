{client{

  open Eliom_content
  open Html5
  open D

  type game = {
    name : string ;
    path : string ;
    game_rate : float option ;
    timer_rate : float option ;
    game_data : string option ;
    keys : (Config.key * Config.emu_key) list ;
  } deriving (Admin_mod)

}}

{server{

  exception Game_not_found of string
  exception Game_read_error of string

  type game = {
    name : string ;
    path : string ;
    game_rate : float option ;
    timer_rate : float option ;
    game_data : string option ;
    keys : (Config.key * Config.emu_key) list ;
  } deriving (Json, Json_ext)

  let games_htbl = Hashtbl.create 20

  let dump_into_file () =
    let l : game list =
      Hashtbl.fold (
        fun _ g acc ->
          g::acc
      ) games_htbl []
    in

    Json_utils_game.list_to_file l (Config.get "games-conf-file")

  let load_into_mem () =
    let games =
      try
        Json_utils_game.list_of_file (Config.get "games-conf-file")
      with _ -> []
    in

    List.iter (
      fun g ->
        Hashtbl.add games_htbl g.name g
    ) (games :> game list)

  let _ =
    load_into_mem ()


  let available_game =
    server_function Json.t<unit> (
      fun _ ->
        let games =
          Hashtbl.fold (
            fun _ g acc -> g::acc
          ) games_htbl []
        in
        Lwt.return games
    )

  let load_game =
    server_function Json.t<string> (
      fun game ->
        try
          let g = Hashtbl.find games_htbl game in
          let in_chan =
            try open_in_bin ((Config.get "game-dir") ^ g.name)
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

        with Not_found ->
          raise (Game_not_found game)
    )
}}

{client{
  module M = Mem_req
  module C = Config

  let games_htbl : (string, game) Hashtbl.t = Hashtbl.create 20

  let get_time () =
    Js.to_float ((jsnew Js.date_now ())##getTime())

  let load_game game =
    M.initialize () ;
    lwt game_str =
      match game.game_data with
        | Some d -> Lwt.return d
        | None ->
          lwt d = %load_game game.name in
          let game = {
            game with
              game_data = Some d ;
          } in
          Hashtbl.replace games_htbl game.name game ;
          Lwt.return d
    in

    begin match game.timer_rate with
      | Some t ->
        C.timer_rate := t
      | None ->
        C.timer_rate := C.default_timer_rate
    end;

    begin
      match game.game_rate with
        | Some t ->
          C.game_rate := t
        | None ->
          C.game_rate := C.default_game_rate
    end;

    begin
      match game.keys with
        | [] ->
          C.keys := C.default_keys
        | k ->
          C.keys := k
    end;

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
      if d < !C.timer_rate then begin
        timer_late := d ;
      end else begin
        timer_late := d -. !C.timer_rate ;
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

      let late = !C.game_rate -. d +. late in

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
