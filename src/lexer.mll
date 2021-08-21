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

rule comment strbuf = parse
  | eof
    { EOF }
  | "/*"
    { Buffer.add_string strbuf "/*";
      let child = comment (Buffer.create 100) lexbuf in
      Buffer.add_string strbuf child;
      Buffer.add_string strbuf "*/";
      comment strbuf lexbuf }
  | newline
    { next_line lexbuf;
      Buffer.add_char strbuf '\n';
      comment strbuf lexbuf }
  | _ as c
    { Buffer.add_char strbuf c;
      comment strbuf lexbuf }
  | "*/"
    { Buffer.contents strbuf }

and read = parse
  | white
    { read lexbuf }
  | newline
    { next_line lexbuf;
      read lexbuf }
  | int as i
    { INT (int_of_string i) }
  | "/*"
    { COMMENT (comment (Buffer.create 100) lexbuf) }
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
    { IDENT (Ident.of_string id) }
  | eof
    { EOF }
  | _ as c
    { raise (SyntaxError ("Unexpected char or sequence: " ^ (String.make 1 c))) }