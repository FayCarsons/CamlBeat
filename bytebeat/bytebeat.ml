type program = Ast.t
type error = Error.t

let parse : string -> (program, Error.t) result = Parser.parse
let string_of_error : Error.t -> string = Error.pp
let pp_error : Error.t -> unit = Parser.print_error
let execute : program -> int -> int = Render.execute
