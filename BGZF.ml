(* reference: https://forge.ocamlcore.org/scm/viewvc.php/trunk/zlib.ml?view=markup&root=camlzip *)

type in_channel_stub
type in_channel = { mutable is_open : bool; stub : in_channel_stub }

external close_in_stub : in_channel_stub -> unit = "caml_bgzf_close_in"
let close_in chan =
	if chan.is_open then begin
		chan.is_open <- false;
		close_in_stub chan.stub
	end

external open_in_stub : string -> in_channel_stub = "caml_bgzf_open_in"
let open_in fn =
	let chan = { is_open = true; stub = open_in_stub fn } in
	Gc.finalise close_in chan;
	chan

external set_cache_size_stub : in_channel_stub -> int -> unit = "caml_bgzf_set_cache_size"
let set_cache_size chan sz = set_cache_size_stub chan.stub sz

external input_stub : in_channel_stub -> string -> int -> int -> int = "caml_bgzf_input"
let input chan buf ofs len =
	match input_stub chan.stub buf ofs len with
		| 0 -> raise End_of_file
		| n when n<0 -> failwith "BGZF.input"
		| n -> n

type pos = Int64.t

external tell_stub : in_channel_stub -> pos = "caml_bgzf_tell"
let tell chan = tell_stub chan.stub

external seek_stub : in_channel_stub -> pos -> unit = "caml_bgzf_seek"
let seek chan pos = seek_stub chan.stub pos

let rec really_input iz buf pos len =
  if len <= 0 then () else begin
    let n = input iz buf pos len in
    assert (n > 0);
    really_input iz buf (pos + n) (len - n)
  end