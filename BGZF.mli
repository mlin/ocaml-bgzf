(** Reading from files compressed in BGZF, a gzip-compatible format allowing random access *)

type in_channel

val open_in : string -> in_channel
val close_in : in_channel -> unit
val set_cache_size : in_channel -> int -> unit

val input : in_channel -> string -> int -> int -> int
val really_input : in_channel -> string -> int -> int -> unit

type pos = Int64.t
val tell : in_channel -> pos
val seek : in_channel -> pos -> unit
