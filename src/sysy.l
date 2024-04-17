%option noinput
%option nounput
%option noyywrap

%{
#include "include/ast.h"
#include "sysy.tab.hpp"

using namespace std;
%}

/* 空白符和注释 */
WhiteSpace    [ \t\n\r]*
LineComment   "//".*
BlockComment  "/*"([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+"/"

/* 标识符 */
Identifier  [A-Za-z_]+[A-Za-z0-9_]*

/* 整数字面量 */
digit [0-9]
integer ([1-9]{digit}*)|0

%%

{WhiteSpace}    { }
{LineComment}   { }
{BlockComment}  { }


"int"           { return INT; }
"const"         { return CONST; }
"void"          { return VOID; }
"if"            { return IF; }
"else"          { return ELSE; }
"while"         { return WHILE; }
"continue"      { return CONTINUE; }
"break"         { return BREAK; }
"return"        { return RETURN; }

{integer}       { yylval.int_value = atoi(yytext);   return INT_CONST; }
{Identifier}    { yylval.str_value = new string(yytext); return IDENT; }

.               { return yytext[0]; }

%%
