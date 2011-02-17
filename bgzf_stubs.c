/* references:
https://forge.ocamlcore.org/scm/viewvc.php/trunk/zlibstubs.c?view=markup&root=camlzip
http://caml.inria.fr/pub/docs/manual-ocaml/manual032.html
*/

#include "bgzf.h"

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/custom.h>

static struct custom_operations bgzf_ops = {
  "bgzf",
  custom_finalize_default,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

#define BGZF_val(v) (*((BGZF**) Data_custom_val(v)))

static value alloc_bgzf(BGZF *bgzf) {
	value v = alloc_custom(&bgzf_ops,sizeof(BGZF*),0,1);
	BGZF_val(v) = bgzf;
	return v;
}

value caml_bgzf_open_in(value fn) {
	CAMLparam1(fn);
	BGZF *bgzf = bgzf_open(String_val(fn),"r");
	if(bgzf == NULL) caml_failwith("BGZF.open_in");
	CAMLreturn(alloc_bgzf(bgzf));
}

value caml_bgzf_close_in(value bgzf) {
	CAMLparam1(bgzf);
	bgzf_close(BGZF_val(bgzf));
	CAMLreturn(Val_unit);
}

value caml_bgzf_set_cache_size(value bgzf, value sz) {
	CAMLparam2(bgzf,sz);
	bgzf_set_cache_size(BGZF_val(bgzf),Val_int(sz));
	CAMLreturn(Val_unit);
}

value caml_bgzf_input(value bgzf, value buf, value ofs, value len) {
	CAMLparam4(bgzf,buf,ofs,len);
	CAMLreturn(Val_long(bgzf_read(BGZF_val(bgzf),&Byte_u(buf,Long_val(ofs)),Int_val(len))));
}

value caml_bgzf_tell(value bgzf) {
	CAMLparam1(bgzf);
	CAMLreturn(copy_int64(bgzf_tell(BGZF_val(bgzf))));
}

value caml_bgzf_seek(value bgzf,value pos) {
	CAMLparam2(bgzf,pos);
	if(bgzf_seek(BGZF_val(bgzf),Int64_val(pos),SEEK_SET) != 0) caml_failwith("BGZF.seek");
	CAMLreturn(Val_unit);
}
