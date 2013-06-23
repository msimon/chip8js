{client{

  open Eliom_content
  open Html5
  open D

  let get_value dom = Js.to_string ((Html5.To_dom.of_input dom)##value)
  let set_value e s = (Html5.To_dom.of_input e)##value <- Js.string s
  let empty_value e = (Html5.To_dom.of_input e)##value <- Js.string ""

  let get_opt_value dom =
    let s = get_value dom in
    if s = "" then None
    else Some s


  let get_value_textarea dom = Js.to_string ((Html5.To_dom.of_textarea dom)##value)
  let set_value_textarea e s = (Html5.To_dom.of_textarea e)##value <- Js.string s

  let get_opt_value_textarea dom =
    let s = get_value_textarea dom in
    if s = "" then None
    else Some s


  let get_value_select e = Js.to_string ((Html5.To_dom.of_select e)##value)
  let set_value_select e s = (Html5.To_dom.of_select e)##value <- Js.string s
  let select_index e i = (To_dom.of_select e)##selectedIndex <- i

  let nl_to_br s =
    let nl_rgx = Regexp.regexp "\\n" in
    let s_list = Regexp.split nl_rgx s in
    let l,_ =
      List.fold_left (
        fun (acc,n) s ->
          let acc =
            if n > 1 then
              br ()::(pcdata s)::acc
            else (pcdata s)::acc
          in
          (acc,n-1)
      ) ([],(List.length s_list)) s_list
    in
    List.rev l
}}
