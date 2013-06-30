open Eliom_service
open Eliom_parameter

let main = service ~path:[ "" ] ~get_params: Eliom_parameter.unit ()
let admin = service ~path:[ "admin" ] ~get_params: Eliom_parameter.unit ()
let about = service ~path:[ "about" ] ~get_params: Eliom_parameter.unit ()
