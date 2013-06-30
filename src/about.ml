{client{

  open Eliom_content
  open Html5
  open D


  let what_is_chip8 () =
    div ~a:[ a_class [ "what_is_chip8" ]] [
      h2 [ pcdata "What is chip8 ?" ];
      div [
        p [
          Raw.a ~a:[ a_href "http://en.wikipedia.org/wiki/CHIP-8"; a_target "_blank" ] [
            pcdata "From wikipedia: "
          ];
          span [
            pcdata "CHIP-8 is an interpreted programming language, developed by Joseph Weisbecker.
It was initially used on the COSMAC VIP and Telmac 1800 8-bit microcomputers in the mid-1970s.
CHIP-8 programs are run on a CHIP-8 virtual machine. It was made to allow video games to be more easily programmed for said computers.
"
          ]
        ];
        p [
          pcdata "It implements a small machine designed specifically for simple video games.
It has less than 40 instructions, including arithmetic, control flow, graphics, and sound."
        ]
      ]
    ]


  let what_is_ochip8 () =
    let g_dom = Chip8_game.Dom_type_game.to_default () in

    let dom_type_example () =
      div [
        h4 [ pcdata "Dom_type example:" ];
        p [ pcdata "Game record in this project, are represented by:"];
        div ~a:[ a_class ["dom_type_example"; "clearfix"]] [
          pre [
            code [
              pcdata "type emu_key = [
    | `K0 | `K1 | `K2 | `K3 | `K4 | `K5 | `K6 | `K7
    | `K8 | `K9 | `KA | `KB | `KC | `KD | `KE | `KF
  ] deriving (Dom_type)
\n";
              pcdata "type key = [
    | `Key_esc | `Key_space | `Key_backspace | `Key_return
    | `Key_left | `Key_up | `Key_right | `Key_down
    | `Key_0 | `Key_1 | `Key_2 | `Key_3 | `Key_4
    | `Key_5 | `Key_6 | `Key_7 | `Key_8 | `Key_9
    | `Key_a | `Key_b | `Key_c | `Key_d | `Key_e
    | `Key_f | `Key_g | `Key_h | `Key_i | `Key_j
    | `Key_k | `Key_l | `Key_m | `Key_n | `Key_o
    | `Key_p | `Key_q | `Key_r | `Key_s | `Key_t
    | `Key_u | `Key_v | `Key_w | `Key_x | `Key_y
    | `Key_z | `Other of int
  ] deriving (Dom_type)
\n";
              pcdata "type game = {
    name : string ;
    path : string ;
    game_rate : float option ;
    timer_rate : float option ;
    game_data : string option ;
    keys : (key * emu_key) list ;
    img_path: string ;
    controls: string option ;
    instruction: string option ;
    information: string option ;
    hash: int option ;
  } deriving (Dom_type)"
            ];
          ];
          div [
            span [ pcdata "By simply calling:" ];
            pre [
              code [
                pcdata "let game_dom = Dom_type_game.to_dom game_value in
Dom_type.node game_dom
"
              ];
            ];
            span [ pcdata "or " ];
            pre [
              code [
                pcdata "let game_dom = Dom_type_game.to_default () in
Dom_type.node game_dom
"
              ];
            ];
            span [ pcdata "Will generate:" ];
            Dom_type.node g_dom
          ]
        ];
        p [
          pcdata "For more information about dom_type, follow the ";
          Raw.a ~a:[ a_href "no_link_yet"; a_target "_blank" ] [ pcdata "link" ];
        ]
      ]
    in

    let offline () =
      div [
        p [
          span [ pcdata "On the html5 side, "];
          Raw.a ~a:[ a_href "https://developer.mozilla.org/en-US/docs/Web/Guide/DOM/Storage"; a_target "_blank" ] [
            pcdata "local storage"
          ];
          span [ pcdata " and "];
          Raw.a ~a:[ a_href "https://developer.mozilla.org/en-US/docs/Online_and_offline_events"; a_target "_blank" ] [
            pcdata "offline"
          ];
          span [ pcdata " mode are use" ]
        ];
        p [
          pcdata "Each time a game is play, it is download from the server and save thanks to local storage. Later if your connection is lost
the offline mode will let you play any game previously played"
        ];
      ]
    in

    div ~a:[ a_class ["what_is_ochip8"]] [
      h2 [ pcdata "So what is Ochip8 ?" ];
      div [
        p [
          pcdata "Ochip8 is a full-javascript chip8 emulator, in other words it mimic the internal design and functionality of a chip8 interpretor"
        ];
        p [
          span [ pcdata "The 'O' stand for ocaml, which is the only language use to implement this project. Thanks to " ];
          Raw.a ~a:[ a_href "http://ocsigen.org/js_of_ocaml/"; a_target "_blank"] [ pcdata "js_of_ocaml" ];
          span [ pcdata " the ocaml code is compile to javascript for all the client-side application" ];
        ];
        p [
          span [
            pcdata "For the server-side application (deserving the most basic html page, ajax request, database,...), it use its olders brothers "
          ];
          Raw.a ~a:[ a_href "http://ocsigen.org/"; a_target "_blank" ] [ pcdata "ocsigen" ];
          span [
            pcdata " and "
          ];
          Raw.a ~a:[ a_href "http://ocsigen.org/eliom/"; a_target "_blank" ] [ pcdata "eliom" ];
          span [
            pcdata " (All thoses projects are developpe and maintain by "
          ];
          Raw.a ~a:[ a_href "http://www.irill.org/"; a_target "_blank" ] [ pcdata "irill"];
          span [
            pcdata ", a center for research and innovation, located in france)"
          ]
        ];
        p [
          span [ pcdata "While develipping this project, I also developpe " ];
          Raw.a ~a:[ a_href "no_link_yet"; a_target "_blank" ] [ pcdata "dom_type"];
          span [ pcdata ", a "];
          Raw.a ~a:[ a_href "https://code.google.com/p/deriving/"; a_target "_blank" ] [ pcdata "deriving" ];
          span [ pcdata " syntax extension that automaticaly generate complex ocaml type in html, and vice versa" ]
        ];
        p [
          span [ pcdata "It is use in the backend to easily modify game configuration" ]
        ];

        dom_type_example ();

        h4 [ pcdata "Offline mode" ];
        offline ();
      ];
    ]

  let thats_all () =
    div ~a:[ a_class ["thats_all_folks"]] [
      h2 [ pcdata "That's all folks!" ];
      div [
        p [
          pcdata "Hope you'll enjoy this project and that it will be fun and usefull for some of you.
It's quite small, it can be a great start to understand how ocaml can be use to unify server and client application
"
        ];
        p [
          (*@marcsimon42*)
          span [ pcdata "You can reach me on twiter " ];
          Raw.a ~a:[ a_href "https://twitter.com/marcsimon42"; a_target "_blank"] [ pcdata "@marcsimon42" ];
          span [ pcdata " for any question or issues." ]
        ]
      ]
    ]

  let dom header_link =
    div [
      Header.dom header_link;
      div ~a:[ a_class ["container"; "about"]] [
        what_is_chip8 ();
        what_is_ochip8 ();
        thats_all ();
      ]
    ]

  let init header_link =
    Manip.appendToBody (dom header_link)


}}
