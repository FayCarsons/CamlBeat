open Core

let execute : Ast.t -> int -> int =
  fun program t ->
  let rec go = function
    | `INTEGER n -> n
    | `T -> t
    | `OP (operator, lhs, rhs) ->
      let l = go lhs
      and r = go rhs in
      (match operator with
       | `ADD -> l + r
       | `SUB -> l - r
       | `MUL -> l * r
       | `DIV -> l / r
       | `AND -> l land r
       | `OR -> l lor r
       | `XOR -> l lxor r
       | `SHR -> l lsr r
       | `SHL -> l lsl r)
  in
  go program
;;
