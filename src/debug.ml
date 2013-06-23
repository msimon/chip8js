{client{

  open Eliom_content
  open Html5
  open D

  let box_dom = div ~a:[ a_style "position:fixed;top:0;right:0;width:200px;background-color:rgba(0,0,0,0.3);padding:0 10px;max-height:500px; overflow:scroll" ] []

  let reset_btn = button ~button_type:`Button [ pcdata "reset" ]

  let init () =
    Manip.appendChild box_dom reset_btn;
    Manip.Ev.onclick reset_btn (
      fun _ ->
        Manip.replaceAllChild box_dom [ reset_btn ];
        false
    )

  let log s =
    Printf.ksprintf (
      fun s ->
        Firebug.console##debug (Js.string s) ;
        Manip.appendChild box_dom (
          div [ span [ pcdata s ] ]
        )
    ) s
}}
