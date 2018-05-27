(**
  The [IO] monad.
*)

Require Extraction.
Require Export ExtrOcamlBasic.

Extraction Blacklist SimpleIO.

(* begin hide *)
Set Warnings "-extraction-opaque-accessed,-extraction".
(* end hide *)

(** * Main interface *)

Parameter IO : Type -> Type.

(** ** Functions *)

Parameter ret : forall {a}, a -> IO a.
Parameter bind : forall {a b}, IO a -> (a -> IO b) -> IO b.
Parameter fix_io : forall {a b}, ((a -> IO b) -> (a -> IO b)) -> a -> IO b.

Definition map_io {a b} : (a -> b) -> IO a -> IO b :=
  fun f m => bind m (fun a => ret (f a)).

Definition loop : forall {a void}, (a -> IO a) -> (a -> IO void) :=
  fun _ _ f => fix_io (fun k x => bind (f x) k).

Definition while_loop : forall {a}, (a -> IO (option a)) -> (a -> IO unit) :=
  fun _ f => fix_io (fun k x => bind (f x) (fun y' =>
    match y' with
    | None => ret tt
    | Some y => k y
    end)).

(** ** Notations *)

Module IONotations.

Delimit Scope io_scope with io.

Notation "c >>= f" := (bind c f)
(at level 50, left associativity) : io_scope.

Notation "f =<< c" := (bind c f)
(at level 51, right associativity) : io_scope.

Notation "x <- c1 ;; c2" := (bind c1 (fun x => c2))
(at level 100, c1 at next level, right associativity) : io_scope.

Notation "e1 ;; e2" := (_ <- e1%io ;; e2%io)%io
(at level 100, right associativity) : io_scope.

End IONotations.

(** ** Equations *)

Axiom fix_io_equation : forall {a b} f, @fix_io a b f = f (fix_io f).

(** *** Monad laws *)

Axiom bind_ret :
  forall {a b} (x : a) (k : a -> IO b), bind (ret x) k = k x.
Axiom ret_bind : forall {a} (m : IO a), bind m ret = m.
Axiom bind_bind :
  forall {a b c} (m : IO a) (k : a -> IO b) (h : b -> IO c),
    bind (bind m k) h = bind m (fun x => bind (k x) h).
Axiom bind_ext : forall {a b} (m : IO a) (k k' : a -> IO b),
    (forall x, k x = k' x) -> bind m k = bind m k'.

(** ** Run! *)

Parameter unsafe_run : forall {a}, IO a -> unit.

(** * Extraction *)

Extract Constant IO "'a" => "'a CoqSimpleIO.t".
Extract Inlined Constant ret => "CoqSimpleIO.return".
Extract Inlined Constant bind => "CoqSimpleIO.bind".
Extract Inlined Constant fix_io => "CoqSimpleIO.fix_io".
Extract Inlined Constant unsafe_run => "CoqSimpleIO.Impure.run".
