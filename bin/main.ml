let program =
  {|(t << 1) ^ ((t << 1) + (t >> 7) & t >> 12)
    | t >> 4 - ((1 ^ 7) & t >> 19)
    | t >> 7 |}
;;

let () = Bytebeat.Render.run program
