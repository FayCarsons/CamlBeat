%{
  open! Error

  let both_ok lhs rhs = 
    match lhs, rhs with 
    | (Ok lhs, Ok rhs) -> Ok (lhs, rhs)
    | Error err, _  
    | _, Error err -> Error err

  let op_or_error (op : Ast.BinOp.t) (lhs : parse_result) (rhs : parse_result) : parse_result = 
    match both_ok lhs rhs with 
    | Ok (lhs, rhs) -> Ok (`OP (op, lhs, rhs))
    | Error err -> Error err
%}

%token <int> INT 
%token T

%token LPAREN RPAREN
%token OP_ADD OP_SUB OP_MUL OP_DIV OP_MOD
%token OP_UMINUS
%token OP_RIGHT_SHIFT OP_LEFT_SHIFT 
%token OP_AND OP_OR OP_XOR
%token EOF

%left OP_OR OP_XOR
%left OP_AND
%left OP_RIGHT_SHIFT OP_LEFT_SHIFT
%left OP_ADD OP_SUB
%left OP_MUL OP_DIV
%nonassoc OP_UMINUS

%start <parse_result> parse
%%

let parse := 
  ~ = expr; EOF; <>

let identifier == 
  | T; { Ok `T }
  | int = INT; { Ok ( `INTEGER int ) } 

let binop := 
  | OP_ADD; { ADD }
  | OP_SUB; { SUB }
  | OP_MUL; { MUL }
  | OP_DIV; { DIV }
  | OP_MOD; { MOD }
  | OP_RIGHT_SHIFT; { SHR }
  | OP_LEFT_SHIFT; { SHL }
  | OP_AND; { AND }
  | OP_OR; { OR }
  | OP_XOR; { XOR }
 
let expr := 
  | ident = identifier; { ident }
  | OP_SUB; e = expr; %prec OP_UMINUS {
      match e with 
      | Ok (`INTEGER n) -> Ok (`INTEGER (-n))
      | err -> err
    }
  | lhs = expr; op = binop; rhs = expr; { op_or_error op lhs rhs }
  | LPAREN; e = expr; RPAREN; { e }
  | error; { Error SyntaxError }
