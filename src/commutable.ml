open Core
open Async
open Ast
open Lexing

let string_of_position lexbuf =
  let { pos_fname; pos_lnum; pos_cnum; pos_bol } = lexbuf.lex_curr_p in
  let col_offset = pos_cnum - pos_bol + 1 in
  [%string "%{pos_fname}:%{pos_lnum#Int}:%{col_offset#Int}"]
;;

let read ~eval ~lexbuf =
  let comment_store = Comment_store.create () in
  match Parser.program (Lexer.read comment_store) lexbuf with
  | exception Lexer.SyntaxError msg ->
    print_s
      [%message "Syntax error" ~at:(string_of_position lexbuf : string) (msg : string)]
    |> Deferred.return
  | exception _ ->
    print_s [%message "Unknown syntax error" ~at:(string_of_position lexbuf : string)]
    |> Deferred.return
  | e -> eval ~comment_store e
;;

let eval ~comment_store _ =
  Comment_store.all comment_store
  |> Deferred.List.iter ~how:`Sequential ~f:(fun (comment_id, comment) ->
         let contents = comment.contents ^ "(" ^ string_of_int comment_id ^ ")!" in
         Comment_writer.replace ~comment_store ~comment_id ~contents)
;;

let command =
  Command.async
    ~summary:"Commutable interpreter"
    (let open Command.Let_syntax in
    let%map_open filename = anon ("filename" %: string) in
    fun () ->
      (* CR-soon orau: it's kinda dumb to fully real the string when lexbuf can do a buffered
         read. Maybe we should just drop the [async] dependency & replace with with a reference
         to [In_channel]? *)
      In_channel.with_file filename ~f:(fun in_channel ->
          let lexbuf = Lexing.from_channel in_channel in
          Lexing.set_filename lexbuf filename;
          read ~eval ~lexbuf))
;;

let () = Command.run command
