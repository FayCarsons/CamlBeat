module AudioError = Error
open Core
open Bigarray

type buffer = (char, int8_unsigned_elt, c_layout) Array1.t

external unsafe_get_buffer_size : unit -> int = "caml_get_buffer_size"
external unsafe_get_buffer : unit -> buffer = "caml_get_buffer"
external unsafe_init : unit -> int = "audio_init"
external unsafe_write_buffer : unit -> int = "audio_write"
external unsafe_cleanup : unit -> int = "audio_cleanup"

(** 'run' is curried tree-walking execution function with current program bound
    to it. Takes T and returns current sample *)
type program = { mutable run : int -> int }

(* NOTE : This is the current Bytebeat program, specifically a curried version of
   `Bytebeat.execute`. On receiving a new program from the user, *)
let program = { run = Int.succ }
let set_program new_program = program.run <- new_program

let init_audio () =
  match unsafe_init () with
  | 0 -> Ok ()
  | error_code -> Error (AudioError.of_error_code error_code)
;;

let write_buffer () =
  match unsafe_write_buffer () with
  | 0 -> Ok ()
  | error_code -> Error (AudioError.of_error_code error_code)
;;

let close_audio () =
  match unsafe_cleanup () with
  | 0 -> Ok ()
  | error_code -> Error (AudioError.of_error_code error_code)
;;

let render : int -> buffer -> (unit, AudioError.t) result =
  fun buffer_size buffer ->
  let fill_buffer offset =
    for i = 0 to pred buffer_size do
      let sample = offset + i |> program.run |> Char.unsafe_of_int in
      Array1.unsafe_set buffer i sample
    done
      [@@inline]
  in
  let rec loop offset =
    fill_buffer offset;
    match write_buffer () with
    | Ok () -> loop (offset + buffer_size)
    | Error error ->
      unsafe_cleanup () |> ignore;
      AudioError.pp_error error;
      exit 1
  in
  loop 0
;;

let run : unit -> (unit, AudioError.t) result =
  fun () ->
  let buffer_size = unsafe_get_buffer_size () in
  match init_audio () with
  | Ok () ->
    let buffer = unsafe_get_buffer () in
    render buffer_size buffer
  | err -> err
;;
