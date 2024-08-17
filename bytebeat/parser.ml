let print_error error = print_endline @@ Error.pp error

let parse : string -> (Ast.t, Error.t) result =
  fun input ->
  let lexbuf = Lexing.from_string input in
  try Grammar.parse Lexer.read lexbuf |> Result.map_error (Error.of_internal lexbuf) with
  | exn ->
    Printexc.to_string exn |> print_endline;
    exit 1
;;

open Ast.BinOp

let%test "Simple" =
  let parsed = parse "1 >> t"
  and expected = `OP (SHR, `INTEGER 1, `T) in
  parsed = Ok expected
;;

let%test "Nesting depth 1" =
  let parsed = parse "1 >> t * t"
  and expected = `OP (SHR, `INTEGER 1, `OP (MUL, `T, `T)) in
  parsed = Ok expected
;;
