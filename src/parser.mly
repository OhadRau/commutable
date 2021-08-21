%token <int>         INT
%token <Ast.Ident.t> IDENT
%token <string>      COMMENT

%token FN LET IF THEN ELSE END
%token EOF
%token LEFT_PAREN RIGHT_PAREN SEMICOLON COMMA EQUAL

%right SEMICOLON

%nonassoc LEFT_PAREN

%{
  open Ast
%}

%start <Ast.Program.t> program
%%

program:
  | EOF
    { [] }
  | t = toplevel; prog = program
    { t::prog }
;

toplevel:
  | FN; name = IDENT; LEFT_PAREN; p = params; RIGHT_PAREN; e = expr; END
    { Function (name, p, e) }
  | c = COMMENT
    { Toplevel.Comment (Unique_counter.create (), c) }
;

params:
  |
    { [] }
  | id = IDENT
    { [id] }
  | id = IDENT; COMMA; rest = params
    { id::rest }
;

expr:
  | LEFT_PAREN; e = expr; RIGHT_PAREN
    { e }
  | LET; id = IDENT; EQUAL; value = expr; SEMICOLON; body = expr
    { Let (id, value, body) }
  | c = COMMENT
    { Expr.Comment (Unique_counter.create (), c) }
  | i = INT
    { Int i }
  | left = expr; SEMICOLON; right = expr
    { Let (Ident.of_string "_", left, right) }
;
