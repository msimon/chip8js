{client{

  type webstorage = Local | Session

  let length storage = storage##length ()

  let key storage i =
    if i < storage##length then begin
      Js.Opt.case (storage##key (i))
        (fun _ -> raise Not_found)
        (fun v -> Js.to_string v)
    end else
      raise Not_found

  let exist storage key =
    Js.Opt.case (storage##getItem (Js.string key))
      (fun _ -> false)
      (fun _ -> true)

  let get storage key : string =
    Js.Opt.case (storage##getItem (Js.string key))
      (fun _ -> raise Not_found)
      (fun v -> Js.to_string v)

  let add storage key value : unit = storage##setItem (Js.string key, Js.string value)
  let remove storage key = storage##removeItem (Js.string key)

  let replace storage key value : unit =
    storage##removeItem (Js.string key);
    storage##setItem (Js.string key, Js.string value)

  let clear storage = storage##clear ()

  let fetch_storage ?(where=Local) ~unavailable f =
    let s =
      match where with
        | Local -> Dom_html.window##localStorage
        | Session -> Dom_html.window##sessionStorage
    in

    Js.Optdef.case s (fun _ -> unavailable ()) (fun s -> f s)

  let fetch_storage_map ?where f f_ret =
    fetch_storage ?where ~unavailable:f_ret f

  let fetch_storage_iter ?where f =
    fetch_storage ?where ~unavailable:(fun _ -> ()) f

  module type Storage =
  sig
    val t: webstorage
    val prefix : string
  end

  module SFactory (S : Storage) =
  struct

    (*** MISC DATA & FUNCTION ****)
    let prefix_rgx = Regexp.regexp ("^" ^ S.prefix)
    let prefix_len = String.length S.prefix

    let rgx_match d =
      match Regexp.string_match prefix_rgx (String.lowercase d) 0 with
        | Some _ -> true
        | None -> false

    let strip d =
      let len = (String.length d) - prefix_len in
      String.sub d prefix_len len

    let concat s = S.prefix ^ s

    (*** Function to access storage ***)
    let fetch_storage_iter f = fetch_storage_iter ~where:S.t f
    let fetch_storage_map f f_ret = fetch_storage_map ~where:S.t f f_ret

    let key storage i =
      let d = key storage i in
      if rgx_match d then
        `Success (strip d)
      else
        `Wrong_prefix

    let exist storage key =
      exist storage (concat key)

    let get storage key =
      get storage (concat key)

    let add storage key value =
      add storage (concat key) value

    let remove storage key =
      remove storage (concat key)

    let replace storage key value =
      replace storage (concat key) value

    let clear () =
      fetch_storage_iter (
        fun storage ->
          let rec iter n =
            try begin
              match key storage n with
                | `Success d -> remove storage d; iter (n + 1)
                | `Wrong_prefix -> iter (n + 1)
            end with Not_found -> ()
          in
          iter 0
      )

    let list_of_storage () =
      fetch_storage_map (
        fun storage ->
          let rec fold acc n =
            try begin
              match key storage n with
                | `Success d -> fold ((d, get storage d)::acc) (n + 1)
                | `Wrong_prefix -> fold acc (n + 1)
            end with Not_found -> acc
          in
          fold [] 0
      ) (fun _ -> [])

  end

}}
