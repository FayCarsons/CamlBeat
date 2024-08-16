type parser_error = Error.t
type program = Ast.t

let parse : string -> (program, parser_error) result = Parser.parse
let string_of_error : parser_error -> string = Error.pp
let pp_error : parser_error -> unit = Parser.print_error
let execute : program -> int -> int = Render.execute
let run : string -> unit = Render.run
