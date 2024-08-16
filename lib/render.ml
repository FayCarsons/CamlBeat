open Bigarray

let buffer_size = 8096
let buffer = Array1.create Int8_unsigned C_layout buffer_size

let execute : Ast.t -> int -> int =
  fun program t ->
  let rec go = function
    | `INTEGER n -> n
    | `T -> t
    | `OP (operator, lhs, rhs) ->
      let open Ast.BinOp in
      let l = go lhs
      and r = go rhs in
      (match operator with
       | ADD -> l + r
       | SUB -> l - r
       | MUL -> l * r
       | DIV -> l / r
       | MOD -> l mod r
       | AND -> l land r
       | OR -> l lor r
       | XOR -> l lxor r
       | SHR -> l lsr r
       | SHL -> l lsl r)
  in
  go program
;;

let fill_buffer offset program =
  for i = 0 to pred buffer_size do
    let sample = execute program (i + offset) in
    Array1.unsafe_set buffer i sample
  done
[@@inline]
;;

let render : Ast.t -> unit =
  fun program ->
  set_binary_mode_out stdout true;
  let rec loop offset =
    let open Out_channel in
    fill_buffer offset program;
    output_bigarray stdout buffer 0 buffer_size;
    flush stdout;
    loop (offset + buffer_size)
  in
  loop 0
;;

let ( >>= ) = Result.bind

let run : string -> unit =
  fun program ->
  match Parser.parse program with
  | Ok ast -> render ast
  | Error e -> Parser.print_error e
;;
