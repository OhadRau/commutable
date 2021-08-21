{
open! Core
open Lexing
open Parser

exception SyntaxError of string

let next_line lexbuf =
  let pos = lexbuf.lex_curr_p in
  lexbuf.lex_curr_p <- { pos with
    pos_bol = lexbuf.lex_curr_pos;
    pos_lnum = pos.pos_lnum + 1
  }
}

let white = [' ' '\t']+
let newline = '\r' | '\n' | "\r\n"

let int = '-'? ['0'-'9']+

let id = ['a'-'z' 'A'-'Z' '_'] ['a'-'z' 'A'-'Z' '0'-'9' '_' '\'' '-']*

rule comment comment_store position strbuf children = parse
  | "/*"
    { let child_position = Ast.Source_position.of_lexbuf lexbuf in
      let child = comment comment_store child_position (Buffer.create 100) [] lexbuf in
      let { Ast.Comment.contents; _ } = Option.value_exn (Ast.Comment_store.get comment_store ~id:child) in
      Buffer.add_string strbuf "/*";
      Buffer.add_string strbuf contents;
      Buffer.add_string strbuf "*/";
      comment comment_store position strbuf (child::children) lexbuf }
  | newline as n
    { next_line lexbuf;
      Buffer.add_string strbuf n;
      comment comment_store position strbuf children lexbuf }
  | _ as c
    { Buffer.add_char strbuf c;
      comment comment_store position strbuf children lexbuf }
  | "*/"
    { let comment = { Ast.Comment.position; contents = Buffer.contents strbuf; children } in
      Ast.Comment_store.add comment_store ~comment }

and read comment_store = parse
  | white
    { read comment_store lexbuf }
  | newline
    { next_line lexbuf;
      read comment_store lexbuf }
  | int as i
    { INT (int_of_string i) }
  | "/*"
    { let position = Ast.Source_position.of_lexbuf lexbuf in
      COMMENT (comment comment_store position (Buffer.create 100) [] lexbuf) }
  | "fn"
    { FN }
  | "let"
    { LET }
  | "if"
    { IF }
  | "then"
    { THEN }
  | "else"
    { ELSE }
  | "end"
    { END }
  | ';'
    { SEMICOLON }
  | ','
    { COMMA }
  | '='
    { EQUAL }
  | '('
    { LEFT_PAREN }
  | ')'
    { RIGHT_PAREN }
  | id as id
    { IDENT (Ast.Ident.of_string id) }
  | eof
    { EOF }
  | _ as c
    { raise (SyntaxError ("Unexpected char or sequence: " ^ (String.make 1 c))) }