(** ByteBeat compilation and execution *)

(** A compiled ByteBeat program *)
type program = Ast.t

type error = Error.t

(** [parse program] Attempts to parse a ByteBeat program, returning either an
    AST which can be executed with {!execute} or an error which can be printed
    with {!print_error} *)
val parse : string -> (program, Error.t) result

val string_of_error : Error.t -> string

(** [print_error error] pretty prints a parser error to stdout for debugging *)
val pp_error : Error.t -> unit

(** [execute program_ast t]
    Executes a program with a tree-walking interpreter for a given t (a
    monotonic 8khz counter), returning the result *)
val execute : program -> int -> int
