type internal =
  | Empty_program
  | Unrecognized of string
  | UnexpectedEOF
  | SyntaxError

type parse_result = (Ast.t, internal) result

exception ParserError of internal

type t =
  { pos : Lexing.position
  ; context : string
  ; message : string
  }

let get_error_context : Lexing.lexbuf -> Lexing.position * string =
  fun lexbuf ->
  let pos = lexbuf.lex_curr_p in
  let line_start = pos.pos_bol in
  let line_end =
    try Bytes.index_from lexbuf.lex_buffer line_start '\n' with
    | Not_found -> Bytes.length lexbuf.lex_buffer
  in
  let line = Bytes.sub_string lexbuf.lex_buffer line_start (line_end - line_start) in
  let caret_pos = pos.pos_cnum - pos.pos_bol in
  let caret_pos = min caret_pos (String.length line) in
  (* Ensure caret doesn't go beyond line length *)
  let context = Printf.sprintf "%s\n%s^" line (String.make caret_pos ' ') in
  pos, context
;;

let position_to_string : Lexing.position -> string =
  fun positon ->
  Printf.sprintf
    "line %d, column %d"
    positon.pos_lnum
    (positon.pos_cnum - positon.pos_bol + 1)
;;

let of_internal : Lexing.lexbuf -> internal -> t =
  fun lexbuf error_kind ->
  let pos, context = get_error_context lexbuf in
  match error_kind with
  | Unrecognized unrecognized_string ->
    { pos; context; message = Printf.sprintf "Unrecognized token %s" unrecognized_string }
  | SyntaxError -> { pos; context; message = "Syntax error" }
  | Empty_program ->
    { pos; context; message = "A ByteBeat program must contain at least one expression" }
  | UnexpectedEOF -> { pos; context; message = "Incomplete expression" }
;;

let pp : t -> string =
  fun error ->
  Printf.sprintf
    "Syntax error %s:\n%s\n%s\n"
    (position_to_string error.pos)
    error.context
    error.message
;;
