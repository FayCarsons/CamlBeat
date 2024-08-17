{
  open Lexing
  open Grammar
}

let digit = [ '0' - '9' ]
let int = '-'? digit (digit | '_')*

let t = 't'

let whitespace = [ ' '  '\t' ]
let newline = '\r' | '\n' | "\r\n"

rule read = 
  parse 
    | whitespace { read lexbuf }
    | newline { new_line lexbuf; read lexbuf }
    | int { INT (int_of_string (Lexing.lexeme lexbuf)) }
    | t { T }
    | '+' { OP_ADD }
    | '-' { OP_SUB }
    | '*' { OP_MUL }
    | '/' { OP_DIV }
    | '%' { OP_MOD }
    | "<<" { OP_LEFT_SHIFT }
    | ">>" { OP_RIGHT_SHIFT }
    | '&' { OP_AND }
    | '|' { OP_OR }
    | '^' { OP_XOR }
    | '(' { LPAREN }
    | ')' { RPAREN }
    | eof { EOF }
    | _ { 
      let e = Error.Unrecognized (Printf.sprintf "Unrecognized operator \'%s\'" (Lexing.lexeme lexbuf)) in 
      raise @@ Error.ParserError e
    }
    
