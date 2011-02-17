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
let set_cache_size chan sz = if chan.is_open then set_cache_size_stub chan.stub sz

external getc : in_channel_stub -> int = "caml_bgzf_getc"
let input_char chan =
	if not chan.is_open then invalid_arg "BGZF.input_char";
	match getc chan.stub with
		| (-1) -> raise End_of_file
		| ch when ch >= 0 && ch <= 255 -> Char.chr ch
		| _ -> failwith "BGZF.input_char"

external input_stub : in_channel_stub -> string -> int -> int -> int = "caml_bgzf_input"
let input chan buf ofs len =
	if not chan.is_open || ofs < 0 || ofs+len > String.length buf then invalid_arg "BGZF.input";
	match input_stub chan.stub buf ofs len with
		| n when n<0 -> failwith "BGZF.input"
		| n -> n

type pos = Int64.t

external tell_stub : in_channel_stub -> pos = "caml_bgzf_tell"
let tell chan =
	if not chan.is_open then invalid_arg "BGZF.tell";
	let pos = tell_stub chan.stub in
	if Int64.compare pos Int64.zero < 0 then failwith "BGZF.tell";
	pos

external seek_stub : in_channel_stub -> pos -> unit = "caml_bgzf_seek"
let seek chan pos =
	if not chan.is_open then invalid_arg "BGZF.seek";
	seek_stub chan.stub pos

let rec really_input iz buf pos len =
  if len <= 0 then () else begin
    let n = input iz buf pos len in
	if n=0 then raise End_of_file;
    really_input iz buf (pos + n) (len - n)
  end
