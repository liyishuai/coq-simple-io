(**
   [RawChar] reexports [SimpleIO] plus some additional features
   assuming Coq strings are extracted using [ExtrOcamlString]:

   - [ascii] is extracted to [char];
   - [string] is extracted to [char list].

   Though convenient, this is kept separate from [SimpleIO] because
   this uses additional extraction hacks.
 *)

From Coq.Strings Require Import
     String Ascii.

From Coq.extraction Require Import
     ExtrOcamlIntConv
     ExtrOcamlString.

From SimpleIO Require Import
     IO_Monad
     IO_Pervasives.

Extraction Blacklist Bytes Pervasives String .

(** * Conversions *)

Parameter int_of_ascii : ascii -> int.
Parameter ascii_of_int : int -> ascii.

Axiom char_is_ascii : char = ascii.

Definition char_of_ascii : ascii -> char :=
  match char_is_ascii in (_ = _ascii) return (_ascii -> char) with
  | eq_refl => fun c => c
  end.

Definition ascii_of_char : char -> ascii :=
  match char_is_ascii in (_ = _ascii) return (char -> _ascii) with
  | eq_refl => fun x => x
  end.

Extract Inlined Constant int_of_ascii => "Pervasives.int_of_char".
Extract Inlined Constant ascii_of_int => "Pervasives.char_of_int".

Parameter to_ostring : string -> ocaml_string.
Parameter from_ostring : ocaml_string -> string.

Extract Constant to_ostring =>
  "fun z -> Bytes.unsafe_to_string (
    let b = Bytes.create (List.length z) in
    let rec go z i =
      match z with
      | c :: z -> Bytes.set b i c; go z (i+1)
      | [] -> b
    in go z 0)".

Extract Constant from_ostring =>
  "fun s ->
    let rec go n z =
      if n = -1 then z
      else go (n-1) (String.get s n :: z)
    in go (String.length s - 1) []".

Coercion char_of_ascii : ascii >-> char.
Coercion to_ostring : string >-> ocaml_string.

(** ** Standard channels *)

(** *** [stdin] *)

Definition read_line' : IO string :=
  IO.map from_ostring read_line.

(** ** File handles *)

(** *** Input *)

Definition input_ascii : in_channel -> IO ascii :=
  fun h => IO.map ascii_of_char (input_char h).

Definition input_line' : in_channel -> IO string :=
  fun h => IO.map from_ostring (input_line h).
