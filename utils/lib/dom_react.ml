(* From besport Balsa_react.ml *)

{client{
  let sleep s = Lwt_js.sleep s
}}

{server{
  let sleep s = Lwt_unix.sleep s
}}

{shared{


  type 'a signal = 'a Lwt_react.signal
  type 'a event = 'a Lwt_react.event

  module S = struct
    include Lwt_react.S

    let create_with_update_value v =
      let _sig, u_sig = create v in
      let u f = u_sig (f (value _sig)) in
      _sig,u

    let iter ?(t="") f s =
      let f x =
        try f x
        with exc ->
          ()
      in
      let _ = map f s in
      ()

    let iter_opt f s =
      let _ = map (fun x ->
          match x with
            | None -> ()
            | Some x -> f x) s
      in ()

    let map ?eq f s =
      let f x =
        try f x
        with exc ->
          raise exc
      in map ?eq f s

    let map_s f s =
      let f x =
        try_lwt f x
        with exc ->
          Lwt.fail exc
      in map_s f s

    let compare s i f = fix i (fun old ->
        let result = map f (Pair.pair old s) in
        (map (fun x -> x) s),result)

    let list_diff s = compare s [] (fun (s1,s2) ->
        List.filter (fun s -> not (List.mem s s1)) s2,
        List.filter (fun s -> not (List.mem s s2)) s1
      )

    let limit_freq t s =
      let s',s_u = create (value s) in
      let thread = ref Lwt.return_unit in
      let _ = map (fun x ->
          (*
        We check if a thread exist
        We cancel it when sleeping to delay the execution
      *)
          if Lwt.is_sleeping !thread then Lwt.cancel !thread;
          thread := (
            lwt _ = sleep t in
            s_u x ;
            Lwt.return_unit
          )
        ) s in
      s'


  end

  module E = struct
    include Lwt_react.E

    let iter ?(t="") f e =
      let f e =
        try f e
        with exc ->

          ()
      in
      let _ = map f e in
      ()


    let map ?(t="") f e =
      let f e =
        try f e
        with exc ->
          raise exc
      in map f e

    let map_s f s =
      let f x =
        try_lwt f x
        with exc ->
          Lwt.fail exc
      in map_s f s

    let create_delay t =
      let e,e_u = create () in
      let thread = ref Lwt.return_unit in
      e,(fun x ->
        (*
      We check if a thread exist
      We cancel it when sleeping to delay the execution
    *)
        if Lwt.is_sleeping !thread then Lwt.cancel !thread;
        thread := (
          lwt _ = sleep t in
          e_u x ;
          Lwt.return_unit
        )
      )

    let create_throttle t =
      let e,e_u = create () in
      let thread = ref Lwt.return_unit in
      e,(fun x ->
        (*
        We check if a thread exist
        We cancel it when sleeping to delay the execution
      *)
        if Lwt.is_sleeping !thread then ()
        else begin
          e_u x ;
          thread := sleep t ;
        end
      )

  end
}}
