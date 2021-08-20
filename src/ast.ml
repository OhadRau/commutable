open! Core

module Ident = struct
  type t = private string

  let of_string x = x
  let to_string x = x
end

module Expr = struct
  type t =
    | Comment of string
    | Int of int
    | String of string
    | Ident of Ident.t
    | Let of Ident.t * t * t
    | Lambda of Ident.t * t
    | Apply of t * t
    | Reload
end

(* example:
{[
  let comment = /* foo */;
  comment +/= /* bar */;
  print(comment);
  reload
  --->
  Let (Ident.of_string "comment", Comment " foo ",
    Let (Ident.of_string "_",
      Apply (
        Ident (Ident.of_string "+/="),
        Ident (Ident.of_string "comment"),
        Comment " bar "),
      Let (Ident.of_string "_",
        Apply (
          Ident (Ident.of_string "print"),
          Ident (Ident.of_string "comment")),
        Reload)))
]}
*)