open Error_type

let from_string json =
  try Yojson.Safe.from_string json
  with _ -> raise Error_json

let to_string s =
  try Yojson.Safe.to_string s
  with _ -> raise Error_json

(***** Json decription *****)

let fetch_int = function
  | `Int v -> v
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
        try f (Misc.list_assoc label el)
        with Not_found -> raise (Not_found_str label)
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
    | Not_found | Not_found_str _ ->
      None

let fetch_int_opt = fetch_opt fetch_int
let fetch_string_opt = fetch_opt fetch_string
let fetch_bool_opt = fetch_opt fetch_bool
let fetch_float_opt = fetch_opt fetch_float
let fetch_obj_opt = fetch_opt fetch_obj
