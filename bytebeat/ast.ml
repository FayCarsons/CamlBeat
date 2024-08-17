module BinOp = struct
  type t =
    | ADD
    | SUB
    | MUL
    | DIV
    | MOD
    | SHR
    | SHL
    | AND
    | OR
    | XOR
  [@@deriving show, enum, eq]

  let to_int = to_enum
end

type t =
  [ `T
  | `INTEGER of int
  | `OP of BinOp.t * t * t
  ]
[@@deriving show, eq]
