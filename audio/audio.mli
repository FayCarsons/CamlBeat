val set_program : (int -> int) -> unit

module Error : sig
  type t = [ `PortAudio of string ]

  val pp_error : Error.t -> unit
end

val run : unit -> (unit, Error.t) result
