{client{

  exception Illegal_operation of (int * int)

  let getshort i =
    i land 0xFFFF

  let get_last_byte i =
    i land 0x00FF

  let get_bits ?(len=1) pos i =
    let i_ =
      match len,pos with
        | 1,1 -> 0x000F
        | 1,2 -> 0x00F0
        | 1,3 -> 0x0F00
        | 1,4 -> 0xF000
        | 2,2 -> 0x00FF
        | 2,3 -> 0x0FF0
        | 2,4 -> 0xFF00
        | 3,3 -> 0x0FFF
        | 3,4 -> 0xFFF0
        | 4,4 -> 0xFFFF
        | _ -> raise (Illegal_operation (len,pos))
    in

    (i land i_) lsr ((pos - len) * 4)

}}
