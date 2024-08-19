open Core

let program =
  {|(t << 1) ^ ((t << 1) + (t >> 7) & t >> 12)
    | t >> 4 - ((1 ^ 7) & t >> 19)
    | t >> 7 |}
;;

let _ =
  match Bytebeat.parse program with
  | Ok ast ->
    let executor = Bytebeat.execute ast in
    Audio.set_program executor;
    (match Audio.run () with
     | Ok () -> print_endline "Audio successful"
     | Error err ->
       print_endline "In Error branch of main";
       Audio.Error.pp_error err)
  | Error err -> Bytebeat.pp_error err
;;
