{server{

  type emu_key = [
    | `K0 | `K1 | `K2 | `K3 | `K4 | `K5 | `K6 | `K7
    | `K8 | `K9 | `KA | `KB | `KC | `KD | `KE | `KF
  ] deriving (Json, Json_ext)

  type key = [
    | `Key_esc | `Key_space | `Key_backspace | `Key_return
    | `Key_left | `Key_up | `Key_right | `Key_down
    | `Key_0 | `Key_1 | `Key_2 | `Key_3 | `Key_4 | `Key_5 | `Key_6 | `Key_7 | `Key_8 | `Key_9
    | `Key_a | `Key_b | `Key_c | `Key_d | `Key_e | `Key_f | `Key_g | `Key_h | `Key_i | `Key_j | `Key_k | `Key_l | `Key_m
    | `Key_n | `Key_o | `Key_p | `Key_q | `Key_r | `Key_s | `Key_t | `Key_u | `Key_v | `Key_w | `Key_x | `Key_y | `Key_z
    | `Other of int
  ] deriving (Json, Json_ext)

  exception Missing_param of string

  let params = Hashtbl.create 0

  let set = Hashtbl.replace params
  let get name =
    try
      Hashtbl.find params name
    with Not_found -> raise (Missing_param name)

  open Simplexmlparser

  let _  =
    List.iter
      (function
	      | Element(k, _ , PCData (v) :: _) -> set k v
	      | _ -> ())
      (Eliom_config.get_config ())

}}

{client{

  open Eliom_content
  open Html5
  open D

  module Manip = Eliom_content.Html5.Manip

  type emu_key = [
    | `K0 | `K1 | `K2 | `K3 | `K4 | `K5 | `K6 | `K7
    | `K8 | `K9 | `KA | `KB | `KC | `KD | `KE | `KF
  ] deriving (Admin_mod)

  type key = [
    | `Key_esc | `Key_space | `Key_backspace | `Key_return
    | `Key_left | `Key_up | `Key_right | `Key_down
    | `Key_0 | `Key_1 | `Key_2 | `Key_3 | `Key_4 | `Key_5 | `Key_6 | `Key_7 | `Key_8 | `Key_9
    | `Key_a | `Key_b | `Key_c | `Key_d | `Key_e | `Key_f | `Key_g | `Key_h | `Key_i | `Key_j | `Key_k | `Key_l | `Key_m
    | `Key_n | `Key_o | `Key_p | `Key_q | `Key_r | `Key_s | `Key_t | `Key_u | `Key_v | `Key_w | `Key_x | `Key_y | `Key_z
    | `Other of int
  ] deriving (Admin_mod)

  let memory_size = 4096

  let register_nb = 16
  let key_nb = 16

  let default_keys : (key * emu_key) list = [
    `Key_x, `K0 ;
    `Key_1, `K1 ;
    `Key_2, `K2 ;
    `Key_3, `K3 ;
    `Key_q, `K4 ;
    `Key_w, `K5 ;
    `Key_e, `K6 ;
    `Key_a, `K7 ;
    `Key_s, `K8 ;
    `Key_d, `K9 ;
    `Key_z, `KA ;
    `Key_c, `KB ;
    `Key_4, `KC ;
    `Key_r, `KD ;
    `Key_f, `KE ;
    `Key_v, `KF ;
  ]

  let keys = ref default_keys

  let game_memory_init = 0x200

  let chip8_fontset =
    [|
      0xF0; 0x90; 0x90; 0x90; 0xF0; (* 0 *)
      0x20; 0x60; 0x20; 0x20; 0x70; (* 1 *)
      0xF0; 0x10; 0xF0; 0x80; 0xF0; (* 2 *)
      0xF0; 0x10; 0xF0; 0x10; 0xF0; (* 3 *)
      0x90; 0x90; 0xF0; 0x10; 0x10; (* 4 *)
      0xF0; 0x80; 0xF0; 0x10; 0xF0; (* 5 *)
      0xF0; 0x80; 0xF0; 0x90; 0xF0; (* 6 *)
      0xF0; 0x10; 0x20; 0x40; 0x40; (* 7 *)
      0xF0; 0x90; 0xF0; 0x90; 0xF0; (* 8 *)
      0xF0; 0x90; 0xF0; 0x10; 0xF0; (* 9 *)
      0xF0; 0x90; 0xF0; 0x90; 0x90; (* A *)
      0xE0; 0x90; 0xE0; 0x90; 0xE0; (* B *)
      0xF0; 0x80; 0x80; 0x80; 0xF0; (* C *)
      0xE0; 0x90; 0x90; 0x90; 0xE0; (* D *)
      0xF0; 0x80; 0xF0; 0x80; 0xF0; (* E *)
      0xF0; 0x80; 0xF0; 0x80; 0x80  (* F *)
    |]


  let gfx_width = 64
  let gfx_height = 32
  let sprite_width = 8

  let default_timer_rate = 1000. /. 60. (* 60 hz *)
  let default_game_rate =  1000. /. 840. (* 840 hz *)

  let timer_rate = ref default_timer_rate
  let game_rate = ref default_game_rate


}}
