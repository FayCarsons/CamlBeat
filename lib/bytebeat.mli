val parse : string -> (Ast.t, Error.t) result
val print_error : Error.t -> unit
val execute : Ast.t -> int -> int
val run : string -> unit
