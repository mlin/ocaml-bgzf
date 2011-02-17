open Printf

let one_megabyte = 1048576
let chunks = 100
let magic_word i = sprintf "HELLO, WORLD! %06d" i
let magic_word_length = String.length (magic_word 0)

let random_megabyte () =
	let dna = [| 'A'; 'G'; 'C'; 'T' |] in
	let mb = String.create one_megabyte in
	for i = 0 to one_megabyte-1 do
		mb.[i] <- dna.(Random.int 4)
	done;
	mb

let write_bgzf () =
	let mb = random_megabyte () in
	let fn = Filename.temp_file "test" ".bgzf" in
	let chan = Unix.open_process_out ("./bgzip -c > " ^ fn) in
	for i = 1 to chunks do
		output_string chan (magic_word i);
		output_string chan mb
	done;
	ignore (Unix.close_process_out chan);
	fn
	
let index_chunks fn =
	let index = Array.make chunks (Int64.of_int (-1)) in
	let chan = BGZF.open_in fn in
	let buf = String.create one_megabyte in
	for i = 1 to chunks do
		index.(i-1) <- BGZF.tell chan;
		BGZF.really_input chan buf 0 (magic_word_length+one_megabyte);
		assert (String.sub buf 0 magic_word_length = magic_word i)
	done;
	BGZF.close_in chan;
	index
	
let access_chunks fn index =
	let chan = BGZF.open_in fn in
	let buf = String.create magic_word_length in
	for i = 1 to chunks*25 do
		let which_chunk = 1 + Random.int chunks in
		BGZF.seek chan index.(which_chunk-1);
		BGZF.really_input chan buf 0 magic_word_length;
		if buf <> magic_word which_chunk then
			failwith (sprintf "expected \"%s\", got \"%s\"" (magic_word which_chunk) buf)
	done;
	BGZF.close_in chan

let main () =
	printf "writing test BGZF file..."; flush stdout;
	let fn = write_bgzf () in
	try
		printf "%s\n" fn;
		let original_sz = chunks * (magic_word_length + one_megabyte) in
		let deflated_sz = Unix.((stat fn).st_size) in
		printf "original size = %d\ncompressed size = %d\ncompression = %.2f%%\n"
			original_sz deflated_sz
			(100.0 *. (1.0 -. (float deflated_sz /. (float original_sz))));
		printf "indexing...\n"; flush stdout;
		let index = index_chunks fn in
(*		for i = 1 to chunks do
			printf "%2d...%s\n" i (Int64.to_string index.(i-1))
		done; *)
		flush stdout;
		printf "verifying random access...\n"; flush stdout;
		for i = 1 to 4 do access_chunks fn index done;
		Sys.remove fn;
		printf "OK!\n"
	with exn -> begin
		Sys.remove fn;
		raise exn
	end

let _ = main ()
