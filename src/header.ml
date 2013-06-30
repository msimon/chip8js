{client{

  open Eliom_content
  open Html5
  open D


  let dom (service_name,service) =
    let online_status =
      Dom_react.S.map (
        function
          | true ->
            span ~a:[ a_style "display:none" ] []
          | false ->
            span ~a:[ a_class ["online_status"]] [ pcdata "offline mode"]
      ) Offline.online_status
    in

    header [
      div [
        div ~a:[ a_class ["logo_side"]] [
          span ~a:[ a_class ["logo"]] [];
          span ~a:[ a_class ["logo_txt"]] [ pcdata "OCHIP8" ];
        ];
        div ~a:[ a_class ["link_side"]] [
          a ~service [ pcdata service_name ] () ;
        ];
        R.node online_status;
        Raw.a ~a:[ a_class ["github_fork"]; Raw.a_href "https://github.com/msimon/chip8js"; a_target "_blank" ] [
          img ~src:"https://s3.amazonaws.com/github/ribbons/forkme_right_gray_6d6d6d.png" ~alt:"https://github.com/msimon/chip8js" ()
        ]
      ]
    ]

}}
