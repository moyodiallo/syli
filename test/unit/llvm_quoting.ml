open Llvm_lir.Helpers

let show (input : string) : unit =
  Printf.printf "%S -> %s\n" input (quote_if_needed input)

let () =
  List.iter show
    [
      (* unquoted: named *)
      "syliMod.foo";
      "a-b";
      "_x-1.y";
      "-lead";
      "trail-";
      "a$b.c_d";
      (* unquoted: numeric *)
      "12";
      "123";
      (* digit-led, not numeric -> quoted *)
      "1abc";
      (* operator / marker names contain parens -> quoted *)
      "syliMod.(+)";
      "syliArr.(#index_set)";
      (* other illegal chars -> quoted (with escaping) *)
      "a:b";
      "a b";
      "a\"b";
      "";
    ]
