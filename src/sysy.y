%{
#include <stdio.h>
#include "include/ast.h"
void yyerror(std::unique_ptr<BaseAST> &ast, const char *s);
extern int yylex(void);
%}

%parse-param { std::unique_ptr<BaseAST> &ast }

/// types
%union {
    int int_value;
    std::string* str_value;
    BaseAST *ast_value;
}

// 终结符
%token INT RETURN CONST VOID IF ELSE WHILE FOR BREAK CONTINUE
%token SEMICOLON LPAREN RPAREN LBRACE RBRACE
%token PLUS MINUS NOT TIMES DIVIDE MOD EQ NE GT GE LT LE AND OR
%token <str_value> IDENT
%token <int_value> INT_CONST

// 开始符
%start CompUnit

// 非终结符
%type <ast_value> FuncDef FuncType Block Stmt Number Exp PrimaryExp UnaryExp AddExp MulExp LOrExp LAndExp EqExp RelExp
%type <str_value> UnaryOp MulOp AddOp RelOp EqOp


%%
CompUnit
    : FuncDef { 
      auto comp_unit = std::make_unique<CompUnitAST>(); // 创建一个CompUnitAST对象
      comp_unit->func_def = unique_ptr<BaseAST>($1); // 将FuncDefAST对象赋值给CompUnitAST对象
      ast = std::move(comp_unit); // 将CompUnitAST对象赋值给ast
    }
    ;

FuncDef
    : FuncType IDENT LPAREN RPAREN Block { 
      auto ast = new FuncDefAST();
      ast->func_type = unique_ptr<BaseAST>($1);
      ast->ident = unique_ptr<string>($2);
      ast->block = unique_ptr<BaseAST>($5);
      $$ = ast;
    }
    ;

FuncType
    : INT { 
      auto ast = new FuncTypeAST();
      ast->type = "int";
      $$ = ast;
    }
    ;

Block
    : LBRACE Stmt RBRACE {
      auto ast = new BlockAST();
      ast->stmt = unique_ptr<BaseAST>($2);
      $$ = ast;
    }
    ;

Stmt
  : RETURN Exp SEMICOLON {
    auto ast = new StmtAST();
    ast->exp_ast = unique_ptr<BaseAST>($2);
    $$ = ast;
  }
  ;

Exp
  : LOrExp { 
    auto ast = new ExpAST();
    ast->lor_exp_ast = unique_ptr<BaseAST>($1); 
    $$ = ast;
  }
  ;

PrimaryExp
  : LPAREN Exp RPAREN {
    auto ast = new PrimaryExpAST();
    ast->type = PrimaryExpType::Exp;
    ast->primary_exp_ast = unique_ptr<BaseAST>($2);
    $$ = ast;
  } | Number {
    auto ast = new PrimaryExpAST();
    ast->type = PrimaryExpType::Number;
    ast->primary_exp_ast = unique_ptr<BaseAST>($1);
    $$ = ast;
  }
  ;

UnaryExp
  : PrimaryExp { 
    auto ast = new UnaryExpAST();
    ast->type = UnaryExpType::PrimaryExp;
    ast->primary_exp_ast = unique_ptr<BaseAST>($1);
    $$ = ast;
  } | UnaryOp UnaryExp {
    auto ast = new UnaryExpAST();
    ast->type = UnaryExpType::UnaryOpandUnaryExp;
    ast->unary_op = unique_ptr<string>($1);
    ast->unary_exp_ast = unique_ptr<BaseAST>($2);
    $$ = ast;
  }

UnaryOp
  : PLUS { $$ = new string("+"); }
  | MINUS { $$ = new string("-"); }
  | NOT { $$ = new string("!"); }
  ;

Number
  : INT_CONST {
    auto ast = new NumberAST();
    ast->val = $1;
    $$ = ast;
  }
  ;

MulExp
  : UnaryExp { 
    auto ast = new MulExpAST();
    ast->type = MulExpType::UnaryExp;
    ast->unary_exp_ast = unique_ptr<BaseAST>($1);
    $$ = ast;
  } | MulExp MulOp UnaryExp {
    auto ast = new MulExpAST();
    ast->type = MulExpType::MulExpMulOpUnaryExp;
    ast->mul_exp_ast = unique_ptr<BaseAST>($1);
    ast->mul_op = unique_ptr<string>($2);
    ast->unary_exp_ast = unique_ptr<BaseAST>($3);
    $$ = ast;
  }
  ;

MulOp
  : TIMES { $$ = new string("*"); }
  | DIVIDE { $$ = new string("/"); }
  | MOD { $$ = new string("%"); }

AddExp
  : MulExp { 
    auto ast = new AddExpAST();
    ast->type = AddExpType::MulExp;
    ast->mul_exp_ast = unique_ptr<BaseAST>($1);
    $$ = ast;
  } | AddExp AddOp MulExp {
    auto ast = new AddExpAST();
    ast->type = AddExpType::AddExpAddOpMulExp;
    ast->add_exp_ast = unique_ptr<BaseAST>($1);
    ast->add_op = unique_ptr<string>($2);
    ast->mul_exp_ast = unique_ptr<BaseAST>($3);
    $$ = ast;
  }
  ;

AddOp 
  : PLUS { $$ = new string("+"); }
  | MINUS { $$ = new string("-"); }
  ;

RelExp
  : AddExp { 
    auto ast = new RelExpAST();
    ast->type = RelExpType::AddExp;
    ast->add_exp_ast = unique_ptr<BaseAST>($1);
    $$ = ast;
  } | RelExp RelOp AddExp {
    auto ast = new RelExpAST();
    ast->type = RelExpType::RelExpRelOpAddExp;
    ast->rel_exp_ast = unique_ptr<BaseAST>($1);
    ast->rel_op = unique_ptr<string>($2);
    ast->add_exp_ast = unique_ptr<BaseAST>($3);
    $$ = ast;
  }
  ;

RelOp
  : EQ { $$ = new string("=="); }
  | NE { $$ = new string("!="); }
  | GT { $$ = new string(">"); }
  | GE { $$ = new string(">="); }
  | LT { $$ = new string("<"); }
  | LE { $$ = new string("<="); }
  ;

EqExp
  : RelExp { 
    auto ast = new EqExpAST();
    ast->type = EqExpType::RelExp;
    ast->rel_exp_ast = unique_ptr<BaseAST>($1);
    $$ = ast;
  } | EqExp EqOp RelExp {
    auto ast = new EqExpAST();
    ast->type = EqExpType::EqExpEqOpRelExp;
    ast->eq_exp_ast = unique_ptr<BaseAST>($1);
    ast->eq_op = unique_ptr<string>($2);
    ast->rel_exp_ast = unique_ptr<BaseAST>($3);
    $$ = ast;
  }
  ;

EqOp
  : EQ { $$ = new string("=="); }
  | NE { $$ = new string("!="); }
  ;

LAndExp
  : EqExp { 
    auto ast = new LAndExpAST();
    ast->type = LAndExpType::EqExp;
    ast->eq_exp_ast = unique_ptr<BaseAST>($1);
    $$ = ast;
  } | LAndExp AND EqExp {
    auto ast = new LAndExpAST();
    ast->type = LAndExpType::LAndExpAndOpEqExp;
    ast->land_exp_ast = unique_ptr<BaseAST>($1);
    ast->eq_exp_ast = unique_ptr<BaseAST>($3);
    $$ = ast;
  }
  ;

LOrExp
  : LAndExp { 
    auto ast = new LOrExpAST();
    ast->type = LOrExpType::LAndExp;
    ast->land_exp_ast = unique_ptr<BaseAST>($1);
    $$ = ast;
  } | LOrExp OR LAndExp {
    auto ast = new LOrExpAST();
    ast->type = LOrExpType::LOrExpOrOpLAndExp;
    ast->lor_exp_ast = unique_ptr<BaseAST>($1);
    ast->land_exp_ast = unique_ptr<BaseAST>($3);
    $$ = ast;
  }
  ;


%%

void yyerror(unique_ptr<BaseAST> &ast, const char *s) {
    cerr << "error: " << s << endl;
}
