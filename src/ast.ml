open! Core

module Ident =
  String_id.Make
    (struct
      let module_name = "Ident"
    end)
    ()

module Unique_counter = Unique_id.Int ()

module Expr = struct
  type t =
    | Comment of Unique_counter.t * string
    | Int of int
    | String of string
    | Ident of Ident.t
    | Let of Ident.t * t * t
    | Lambda of Ident.t * t
    | Apply of t * t
    | Reload
end

module Toplevel = struct
  type t =
    | Comment of Unique_counter.t * string
    | Function of Ident.t * Ident.t list * Expr.t
end

module Program = struct
  type t = Toplevel.t list
end

(* example:
{[
  let comment = /* foo */;
  comment +/= /* bar */;
  print(comment);
  reload
  --->
  Let (Ident.of_string "comment", Comment (Unique_counter.create(), " foo "),
    Let (Ident.of_string "_",
      Apply (
        Ident (Ident.of_string "+/="),
        Ident (Ident.of_string "comment"),
        Comment (Unique_counter.create (), " bar ")),
      Let (Ident.of_string "_",
        Apply (
          Ident (Ident.of_string "print"),
          Ident (Ident.of_string "comment")),
        Reload)))
]}
*)
