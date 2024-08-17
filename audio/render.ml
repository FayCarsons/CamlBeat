open Core
open Core_unix
open Bigarray

let buffer_size = 8096

let render render_sample =
  let buffer = Array1.create Int8_unsigned C_layout buffer_size in
  let fill_buffer offset =
    for i = 0 to pred buffer_size do
      Array1.unsafe_set buffer i (render_sample (offset + i))
    done
  in
  let sox =
    "sox -t raw -r 8000 -b 8 -e unsigned -c 1 - -t coreaudio"
    (*
       "sox -t raw -r 8000 -b 8 -e unsigned -c 1 -t coreaudio"
    *)
  in
  let stdin_read, stdin_write = pipe () in
  match fork () with
  | `In_the_child ->
    close stdin_write;
    dup2 ~src:stdin_read ~dst:stdin ();
    close stdin_read;
    never_returns (exec ~prog:"/bin/sh" ~argv:[ "/bin/sh"; "-c"; sox ] ())
  | `In_the_parent pid ->
    close stdin_read;
    let open Stdlib.Out_channel in
    let out_chan = out_channel_of_descr stdin_write in
    set_binary_mode out_chan true;
    (try
       let rec loop offset =
         fill_buffer offset;
         output_bigarray out_chan buffer 0 buffer_size;
         flush out_chan;
         loop (offset + buffer_size)
       in
       loop 0
     with
     | End_of_file ->
       close out_chan;
       ignore (waitpid pid)
     | e ->
       close out_chan;
       ignore (waitpid pid);
       raise e)
;;
