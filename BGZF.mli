(** A gunzip-compatible format allowing random access to the uncompressed data *)

type in_channel

val open_in : string -> in_channel
(** Open a BGZF-compressed file for reading *)

val close_in : in_channel -> unit
(** Close the file immediately. Otherwise it will be taken care of when the [in_channel] is
finalized by the garbage collector. *)

val input_char : in_channel -> char
(** Uncompress one character from the given channel, and return it.

@raise End_of_file if no more compressed data is available. *)

val input : in_channel -> string -> int -> int -> int
(** [input ic buf pos len] uncompresses up to [len] characters from the given channel [ic], storing
them in string [buf], starting at character number [pos]. It returns the actual number of characters
read, between 0 and [len] (inclusive).

@return A return value of 0 means that the end of file was reached. A return value between 0 and
[len] exclusive means that not all requested [len] characters were read, either because no more
characters were available at that time, or because the implementation found it convenient to do a
partial read; [input] must be called again to read the remaining characters, if desired. *)

val really_input : in_channel -> string -> int -> int -> unit
(** [really_input ic buf pos len] uncompresses [len] characters from the given channel, storing them
in string [buf], starting at character number [pos].

@raise End_of_file if fewer than [len] characters can be read. *)

type pos = Int64.t
(** The type of positions in the compressed data stream.

{b IMPORTANT}: positions should be treated as opaque values. You can {b not} construct positions {i
ab initio} nor perform any arithmetic on them. They are revealed as [int64]'s only to facilitate
serialization and deserialization. 

To get the 1,000,000th byte of a file, you would have to have previously opened the file from the
beginning, read the first 999,999 bytes, and then recorded the position using [BGZF.tell]. You can
then [seek] to this position to get the desired data. More generally, you need to index the BGZF
file in advance by completely passing through the data and recording positions that will be required
in the future. The positions are constant for a given BGZF file and version of the library. *)

val tell : in_channel -> pos
(** Return the current position in the file. Again, no interpetation of the value should be made,
other than a subsequent call to [seek] to position the file at the same point. *)

val seek : in_channel -> pos -> unit
(** Set the file to read from the location specified by pos, which must be a value previously
returned by [tell] for this file (but not necessarily one returned by this channel instance). *)

val set_cache_size : in_channel -> int -> unit
(** Set the maximum number of uncompressed bytes to cache, in order to speed up successive [seek]
and [input] operations from nearby positions. The cache size is 0 by default. A cache size of about
8 megabytes is suggested for frequent random access. *)
