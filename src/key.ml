{client{
  module M = Mem_req

  let stack : ((Config.key * [ `Pressed | `Released ]) list ref) = ref []

  let key_of_keycode =
    function
      | 27 -> `Key_esc | 32 -> `Key_space | 8 -> `Key_backspace | 13 -> `Key_return
      | 37 -> `Key_left | 38 -> `Key_up | 39 -> `Key_right | 40 -> `Key_down
      | 48 | 96 -> `Key_0 | 49 | 97 -> `Key_1 | 50 | 98 -> `Key_2 | 51 | 99 -> `Key_3 | 52 | 100 -> `Key_4
      | 53 | 101 -> `Key_5 | 54 | 102 -> `Key_6 | 55 | 103 -> `Key_7 | 56 | 104 -> `Key_8 | 57 | 105 -> `Key_9
      | 65 -> `Key_a | 66 -> `Key_b | 67 -> `Key_c | 68 -> `Key_d
      | 69 -> `Key_e | 70 -> `Key_f | 71 -> `Key_g | 72 -> `Key_h
      | 73 -> `Key_i | 74 -> `Key_j | 75 -> `Key_k | 76 -> `Key_l
      | 77 -> `Key_m | 78 -> `Key_n | 79 -> `Key_o | 80 -> `Key_p
      | 81 -> `Key_q | 82 -> `Key_r | 83 -> `Key_s | 84 -> `Key_t
      | 85 -> `Key_u | 86 -> `Key_v | 87 -> `Key_w | 88 -> `Key_x
      | 89 -> `Key_y | 90 -> `Key_z
      | n ->
        `Other n

  let init () =
    let _ =
      Dom_events.listen Dom_html.window##document
        Dom_events.Typ.keydown (
        fun _ ev ->
          let key = key_of_keycode ev##keyCode in
          if not (List.mem (key, `Pressed) !stack) then
            stack := (key,`Pressed)::!stack;
          true
      )
    in

    let _ =
      Dom_events.listen Dom_html.window##document
        Dom_events.Typ.keyup (
        fun _ ev ->
          let key = key_of_keycode ev##keyCode in
          if not (List.mem (key, `Released) !stack) then
            stack := (key,`Released)::!stack;
          true
      )
    in
    ()

  let check () =
    let poll () =
      match !stack with
        | h::t -> stack := t; Some h
        | _ -> None
    in

    let handle_key (key,key_state) =
      let set_key n =
        let v = match key_state with
          | `Pressed -> 1
          | `Released -> 0
        in

        M.key.(n) <- v
      in
      let hex_of_key = function
        | `K0 -> 0x0
        | `K1 -> 0x1
        | `K2 -> 0x2
        | `K3 -> 0x3
        | `K4 -> 0x4
        | `K5 -> 0x5
        | `K6 -> 0x6
        | `K7 -> 0x7
        | `K8 -> 0x8
        | `K9 -> 0x9
        | `KA -> 0xa
        | `KB -> 0xb
        | `KC -> 0xc
        | `KD -> 0xd
        | `KE -> 0xe
        | `KF -> 0xf
      in

      try
        let kv = List.assoc key !Config.keys in
        set_key (hex_of_key kv)
      with Not_found ->
        ()
    in

    match poll () with
      | Some k -> handle_key k
      | _ -> ()


  let reset () =
    M.clear_array M.key;
    stack := []

}}
