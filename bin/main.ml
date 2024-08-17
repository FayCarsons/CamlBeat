let program =
  {|(t << 1) ^ ((t << 1) + (t >> 7) & t >> 12)
    | t >> 4 - ((1 ^ 7) & t >> 19)
    | t >> 7 |}
;;

let () =
  match Bytebeat.parse program with
  | Ok ast -> Audio.Render.render (Bytebeat.execute ast)
  | Error e -> Bytebeat.pp_error e
;;
