open Core
open Async
open! Ast
open Lexing

let string_of_position lexbuf =
  let { pos_fname; pos_lnum; pos_cnum; pos_bol } = lexbuf.lex_curr_p in
  let end_char = pos_cnum - pos_bol + 1 in
  [%string "%{pos_fname}:%{pos_lnum#Int}:%{end_char#Int}"]
;;

let read ~eval ~lexbuf =
  match Parser.program Lexer.read lexbuf with
  | exception Lexer.SyntaxError msg ->
    print_s
      [%message "Syntax error" ~at:(string_of_position lexbuf : string) (msg : string)]
  | exception _ ->
    print_s [%message "Unknown syntax error" ~at:(string_of_position lexbuf : string)]
  | e -> eval e
;;

let eval _ = print_endline "Hello"

let command =
  Command.async
    ~summary:"Commutable interpreter"
    (let open Command.Let_syntax in
    let%map_open filename = anon ("filename" %: string) in
    fun () ->
      (* CR-soon orau: it's kinda dumb to fully real the string when lexbuf can do a buffered
         read. Maybe we should just drop the [async] dependency & replace with with a reference
         to [In_channel]? *)
      let%map.Deferred program = Reader.file_contents filename in
      read ~eval ~lexbuf:(Lexing.from_string program))
;;

let () = Command.run command
