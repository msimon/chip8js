exception Error_json

module type Json_ext = sig
  type a
  val to_json : a -> Yojson.Safe.json
  val from_json : Yojson.Safe.json -> a
end

module Default(D : Json_ext) : Json_ext with type a = D.a = struct
  include D
end

module Json_ext_int = Default(struct
    type a = int
    let from_json = function
      | `Int i -> i
      | `String i -> int_of_string i
      | _ -> raise Error_json

    let to_json i =
      `Int i
  end)


module Json_ext_int32 = Default(struct
    type a = int32

    let from_json = function
      | `Int i -> Int32.of_int i
      | `String i -> Int32.of_string i
      | _ -> raise Error_json

    let to_json i =
      `Int (Int32.to_int i)

  end)

module Json_ext_int64 = Default(struct
    type a = int64

    let from_json = function
      | `Int i -> Int64.of_int i
      | `String i -> Int64.of_string i
      | _ -> raise Error_json

    let to_json i =
      `Int (Int64.to_int i)

  end)

module Json_ext_bool = Default(struct
    type a = bool
    let from_json = function
      | `Bool b -> b
      | `Int i -> i > 0
      | `String s ->
        begin try (int_of_string s) > 0
        with _ ->
          if s = "false" then false
          else true
        end
      | _ -> raise Error_json

    let to_json b =
      `Bool b
  end)

module Json_ext_float = Default(struct
    type a = float

    let from_json = function
      | `Float f -> f
      | `String f -> float_of_string f
      | _ -> raise Error_json

    let to_json f =
      `Float f

  end)

module Json_ext_string = Default(struct
    type a = string
    let from_json = function
      | `String s -> s
      | _ -> raise Error_json

    let to_json i =
      `String i
  end)

module Json_ext_list (A : Json_ext) = Default(struct
    type a = A.a list
    let from_json = function
      | `List l ->
        List.map (
          fun json ->
            A.from_json json
        ) l
      | _ -> raise Error_json

    let to_json l =
      `List (List.map (fun e -> A.to_json e) l)
  end)


module Json_ext_array (A : Json_ext) = Default(struct
    type a = A.a array
    let from_json = function
      | `List l ->
        let l =
          List.map (
            fun json ->
              A.from_json json
          ) l
        in

        Array.of_list l

      | _ -> raise Error_json

    let to_json a =
      let l = Array.to_list a in

      `List (List.map (fun e -> A.to_json e) l)
  end)


module Json_ext_option (A : Json_ext) = Default(struct
    type a = A.a option
    let from_json = function
      | `Null -> None
      | s -> Some (A.from_json s)

    let to_json = function
      | None -> `Null
      | Some o -> A.to_json o

  end)

(** Utils function **)

let assoc label json_list =
  try
    List.assoc label json_list
  with Not_found ->
    `Null

let fetch_assoc_value =
  function
    | `Assoc json_list -> json_list
    | _ -> raise Error_json

let fetch_list =
  function
    | `List json_list -> json_list
    | _ -> raise Error_json

let to_list json =
  `List json

let to_json json_list =
  `Assoc json_list

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
