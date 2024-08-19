external unsafe_get_error : int -> string = "get_error"

type t = [ `PortAudio of string ]

let of_error_code error_code = `PortAudio (unsafe_get_error error_code)
let pp_error (`PortAudio reason) = print_endline reason
