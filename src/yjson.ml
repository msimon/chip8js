exception Error_json
exception Json_not_found of string
exception File_not_found of string

let from_string json =
  try Yojson.Safe.from_string json
  with _ -> raise Error_json

let to_string s =
  try Yojson.Safe.to_string s
  with _ -> raise Error_json

let from_file file_name =
  let in_chan =
    open_in_gen [ Open_creat ] 0o666 file_name
  in

  let rec read pos s =
    if input in_chan s pos 200 = 0 then s
    else begin
      let pos = String.length s in
      let s_ = String.make (200 + pos) '\032' in
      String.blit s 0 s_ 0 pos;
      read pos s_
    end
  in
  let s = read 0 (String.make 200 '\032') in
  let json = from_string (String.trim s) in

  close_in in_chan;
  json

let to_file json file_name =
  let out_chan = open_out_gen [ Open_trunc; Open_creat; Open_wronly ] 0o666 file_name in

  let s = to_string json in
  let len = String.length s in
  output out_chan s 0 len;

  close_out out_chan


(***** Json fetch *****)

let fetch_int = function
  | `Int v -> v
  | `Intlit i -> int_of_string i
  | `String v -> int_of_string v
  | _ -> raise Not_found

let fetch_string = function
  | `String v -> v
  | _ -> raise Not_found

let fetch_bool = function
  | `Bool v -> v
  | `Int i when i = 0 -> false
  | `Int i when i = 1 -> true
  | _ -> raise Not_found

let fetch_float = function
  | `Float v -> v
  | `String v -> float_of_string v
  | _ -> raise Not_found

let fetch_obj = function
  | (`Assoc _) as el -> el
  | _ -> raise Not_found

let fetch f label (json:Yojson.Safe.json) =
  match json with
    | `Assoc el ->
      begin
        try f (List.assoc label el)
        with Not_found -> raise (Json_not_found label)
      end
    | _ -> raise Error_json

let fetch_int = fetch fetch_int
let fetch_string = fetch fetch_string
let fetch_bool = fetch fetch_bool
let fetch_float = fetch fetch_float
let fetch_obj = fetch fetch_obj

let fetch_opt f label json =
  try Some (f label json)
  with
    | Not_found | Json_not_found _ ->
      None

let fetch_int_opt = fetch_opt fetch_int
let fetch_string_opt = fetch_opt fetch_string
let fetch_bool_opt = fetch_opt fetch_bool
let fetch_float_opt = fetch_opt fetch_float
let fetch_obj_opt = fetch_opt fetch_obj

(***** Json write *****)

let to_int i = `Int i
let to_string s = `String s
let to_bool b = `Bool b
let to_float f = `Float f

let to_json json_list =
  `Assoc json_list

let to_json_opt json_list =
  let json_list =
    List.fold_left (
      fun acc (id,e) ->
        match e with
          | Some e -> (id,e)::acc
          | None -> acc
    ) [] json_list
  in

  `Assoc json_list
