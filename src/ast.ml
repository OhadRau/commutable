open! Core

module Ident =
  String_id.Make
    (struct
      let module_name = "Ident"
    end)
    ()

module Comment_id = struct
  type t = int [@@deriving sexp, compare, hash]
end

module Source_position = struct
  type t =
    { filename : string
    ; line_number : int
    ; column_number : int
    ; offset : int
    }
  [@@deriving sexp]

  let of_lexbuf lexbuf =
    let open Lexing in
    let offset = lexbuf.lex_curr_pos in
    let { pos_fname = filename
        ; pos_lnum = line_number
        ; pos_cnum = column_number
        ; pos_bol = _
        }
      =
      lexbuf.lex_curr_p
    in
    { filename; line_number; column_number; offset }
  ;;
end

module Comment = struct
  type t =
    { position : Source_position.t
    ; contents : string
    ; children : Comment_id.t list
    }
  [@@deriving sexp]
end

module Comment_store = struct
  type t =
    { mutable counter : int
    ; table : (Comment_id.t, Comment.t) Hashtbl.t
    }

  let create () = { counter = 0; table = Hashtbl.create (module Comment_id) }

  let add t ~comment =
    let id = t.counter in
    t.counter <- t.counter + 1;
    Hashtbl.set t.table ~key:id ~data:comment;
    id
  ;;

  let get t ~id = Hashtbl.find t.table id
  let all t = Hashtbl.to_alist t.table
end

module Expr = struct
  type t =
    | Comment of Comment_id.t
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
    (* CR-soon orau: Are toplevel comments useful? *)
    | Comment of Comment_id.t
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
