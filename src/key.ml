{server{

  type.json key = [
    | `Key_esc | `Key_space | `Key_backspace | `Key_return
    | `Key_left | `Key_up | `Key_right | `Key_down
    | `Key_0 | `Key_1 | `Key_2 | `Key_3 | `Key_4 | `Key_5 | `Key_6 | `Key_7 | `Key_8 | `Key_9
    | `Key_a | `Key_b | `Key_c | `Key_d | `Key_e | `Key_f | `Key_g | `Key_h | `Key_i | `Key_j | `Key_k | `Key_l | `Key_m
    | `Key_n | `Key_o | `Key_p | `Key_q | `Key_r | `Key_s | `Key_t | `Key_u | `Key_v | `Key_w | `Key_x | `Key_y | `Key_z
    | `Other of int
  ]

}}

{client{

  open Eliom_content
  open Html5
  open D

  module Manip = Eliom_content.Html5.Manip

  type.dom key = [
    | `Key_esc | `Key_space | `Key_backspace | `Key_return
    | `Key_left | `Key_up | `Key_right | `Key_down
    | `Key_0 | `Key_1 | `Key_2 | `Key_3 | `Key_4 | `Key_5 | `Key_6 | `Key_7 | `Key_8 | `Key_9
    | `Key_a | `Key_b | `Key_c | `Key_d | `Key_e | `Key_f | `Key_g | `Key_h | `Key_i | `Key_j | `Key_k | `Key_l | `Key_m
    | `Key_n | `Key_o | `Key_p | `Key_q | `Key_r | `Key_s | `Key_t | `Key_u | `Key_v | `Key_w | `Key_x | `Key_y | `Key_z
    | `Other of int
  ]

  module M = Mem_req

  let stack : ((key * [ `Pressed | `Released ]) list ref) = ref []

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

      match key with
        | `Key_x -> set_key 0x0

        | `Key_1 -> set_key 0x1
        | `Key_2 -> set_key 0x2
        | `Key_3 -> set_key 0x3
        | `Key_q -> set_key 0x4
        | `Key_w -> set_key 0x5
        | `Key_e -> set_key 0x6
        | `Key_a -> set_key 0x7
        | `Key_s -> set_key 0x8
        | `Key_d -> set_key 0x9
        | `Key_z -> set_key 0xa
        | `Key_c -> set_key 0xb

        | `Key_4 -> set_key 0xc
        | `Key_r -> set_key 0xd
        | `Key_f -> set_key 0xe
        | `Key_v -> set_key 0xf
        | _ -> ()
    in

    match poll () with
      | Some k -> handle_key k
      | _ -> ()


  let reset () =
    M.clear_array M.key;
    stack := []

}}
