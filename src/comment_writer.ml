open Core
open Async
open Ast

(* CR-someday orau: We should be able to batch writes by file & defer them until the next [reload]/end of execution.
   A good way of doing this might be storing in-memory versions of each file within the [Comment_store] module &
   updating those, then adding a [Comment_writer.save] function to write the cached versions of each file to disk. *)
let replace ~comment_store ~comment_id ~contents =
  let open Deferred.Let_syntax in
  let comment = Comment_store.get comment_store ~id:comment_id |> Option.value_exn in
  let { Source_position.filename; offset; _ } = comment.position in
  let%bind file_contents = Reader.file_contents filename in
  (* CR orau: after updating this comment, we'll need to update the position for every comment that comes after.
     Alternatively, we could just re-parse the file & swap out the comment stores.
     
     Either way, this also leads to an interesting question: what happens if we insert a new comment into the text
     of an existing comment? This would invalidate all the counters, so maybe we need to come up with a better way
     to identify comments? *)
  let new_contents =
    String.substr_replace_first
      file_contents
      ~pos:offset
      ~pattern:comment.contents
      ~with_:contents
  in
  Writer.save filename ~temp_file:(filename ^ ".tmp") ~contents:new_contents
;;
