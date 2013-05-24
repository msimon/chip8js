{client{
  module C = Config
  (* 0x000-0x1FF - Chip 8 interpreter (contains font set in emu) *)
  (* 0x050-0x0A0 - Used for the built in 4x5 pixel font set (0-F) *)
  (* 0x200-0xFFF - Program ROM and work RAM *)

  (* total memory *)
  let memory = Array.make C.memory_size 0

  (* register *)
  let reg = Array.make C.register_nb 0

  (* index register *)
  let i = ref 0
  (* program counter *)
  let pc = ref 0

  let gfx = Array.make_matrix C.gfx_height C.gfx_width 0

  (* Some timer *)
  let delay_timer = ref 0
  let sound_timer = ref 0

  let stack : int list ref = ref []

  let key = Array.make C.key_nb 0

  let clear_screen () =
    let clear_matrix m =
      let leny = Array.length m in
      let lenx = Array.length m.(0) in
      let rec clear n =
        Array.fill m.(n) 0 lenx 0 ;
        if n = leny - 1 then ()
        else clear (n + 1)
      in

      clear 0
    in

    clear_matrix gfx

  let clear_array a =
    Array.fill a 0 ((Array.length a) - 1) 0

  let initialize () =
    pc := C.game_memory_init ;
    i := 0 ;

    clear_array memory ;
    clear_array reg ;
    clear_array key ;
    clear_screen ();

    stack := [];

    delay_timer := 0 ;
    sound_timer := 0 ;

    Array.iteri (
      fun i c ->
        memory.(i) <- c
    ) C.chip8_fontset;

    Random.self_init ()

}}
