open! Core
open! Async
open! Ast

let command =
  Command.async
    ~summary:"Commutable interpreter"
    (let open Command.Let_syntax in
    let%map_open filename = anon ("filename" %: string) in
    fun () ->
      let%map.Deferred program = Reader.file_contents filename in
      print_endline program)
;;

let () = Command.run command
