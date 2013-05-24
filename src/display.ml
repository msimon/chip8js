{client{

  exception Canvas_not_initialized

  open Eliom_content
  open Html5
  open D

  open Dom_html

  module M = Mem_req
  module C = Config

  let canvas = canvas ~a:[ a_style "background-color: black"; a_width (C.gfx_width * 10); a_height (C.gfx_height * 10) ] []
  let ctx = ref None

  let init () =
    let canvas_js = Eliom_content.Html5.To_dom.of_canvas canvas in
    ctx := Some (canvas_js##getContext (_2d_))

  let display () =
    let ctx =
      match !ctx with
        | Some c -> c
        | None -> raise Canvas_not_initialized
    in

    let rec draw_y y =
      let rec draw_x x =
        if M.gfx.(y).(x) = 1 then begin
          ctx##rect(float_of_int (x * 10), float_of_int (y * 10), 10., 10.);
        end;
        if x >= C.gfx_width - 1 then ()
        else draw_x (x + 1)
      in

      draw_x 0 ;
      if y >= C.gfx_height - 1 then ()
      else draw_y (y + 1)
    in

    ctx##beginPath();
    ctx##clearRect(0.,0.,float_of_int (C.gfx_width * 10), float_of_int (C.gfx_height * 10));
    draw_y 0;
    ctx##fillStyle <- Js.string "yellow";
    ctx##closePath();
    ctx##fill ()

}}
