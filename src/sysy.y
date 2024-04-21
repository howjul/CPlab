%{
#include <stdio.h>
#include <vector>
#include "include/ast.h"
void yyerror(std::unique_ptr<BaseAST> &ast, const char *s);
extern int yylex(void);
%}

%parse-param { std::unique_ptr<BaseAST> &ast }

/// types
%union {
    int int_value;
    std::string* str_value;
    BaseAST* ast_value;
    std::vector<BaseAST*>* ast_list;
    std::vector<string>* str_list;
}

// 终结符
%token INT RETURN VOID IF ELSE WHILE BREAK CONTINUE
%token SEMICOLON LPAREN RPAREN LBRACE RBRACE COMMA LBRACKET RBRACKET
%token PLUS MINUS NOT TIMES DIVIDE MOD EQ NE GT GE LT LE AND OR ASSIGN
%token <str_value> IDENT
%token <int_value> INT_CONST

// 开始符
/* %start CompUnit */

// 非终结符
%type <ast_value> FuncDef Type Block Stmt Number Exp PrimaryExp UnaryExp AddExp MulExp LOrExp LAndExp EqExp RelExp Decl BlockItem LVal VarDecl VarDef InitVal FuncFParams FuncFParam CompUnit CompUnitList
%type <ast_list> BlockItemList VarDefList FuncFParamList FuncRParams
%type <str_value> UnaryOp MulOp AddOp RelOp EqOp
%type <str_list> ArrayDimList

%%
CompUnit
  : CompUnitList {
    auto comp_unit = make_unique<startAST>();
    comp_unit->comp_unit_ast = unique_ptr<BaseAST>($1);
    ast = std::move(comp_unit);
  }
  ;

CompUnitList
    : Decl {
      auto compunit = new CompUnitAST();
      compunit->decl_list.push_back($1);
      $$ = compunit;
    } | CompUnitList Decl {
      auto compunit = (CompUnitAST*)$1;
      compunit->decl_list.push_back($2);
      $$ = compunit;
    } | FuncDef {
      auto compunit = new CompUnitAST();
      compunit->func_def_list.push_back($1);
      $$ = compunit;
    } | CompUnitList FuncDef { 
      auto compunit = (CompUnitAST*)$1;
      compunit->func_def_list.push_back($2);
      $$ = compunit;
    } 
    ;

FuncDef
    : Type IDENT LPAREN RPAREN Block { 
      auto ast = new FuncDefAST();
      ast->type = FuncDefType::NoParams;
      ast->func_type = unique_ptr<BaseAST>($1);
      ast->ident = unique_ptr<string>($2);
      ast->block = unique_ptr<BaseAST>($5);
      $$ = ast;
    } | Type IDENT LPAREN FuncFParams RPAREN Block{
      auto ast = new FuncDefAST();
      ast->type = FuncDefType::WithParams;
      ast->func_type = unique_ptr<BaseAST>($1);
      ast->ident = unique_ptr<string>($2);
      ast->funcfparams = unique_ptr<BaseAST>($4);
      ast->block = unique_ptr<BaseAST>($6);
      $$ = ast;
    }
    ;

Type
    : INT { 
      auto ast = new TypeAST();
      ast->type = TypeType::Int;
      $$ = ast;
    } | VOID {
      auto ast = new TypeAST();
      ast->type = TypeType::Void;
      $$ = ast;
    }
    ;

FuncFParams
    : FuncFParam FuncFParamList {
      auto ast = new FuncFParamsAST();
      ast->funcfparam_ast = unique_ptr<BaseAST>($1);
      ast->funcfparam_list = *($2);
      $$ = ast;
    }

FuncFParamList
    : {
      auto funcfparam_list = new std::vector<BaseAST*>;
      $$ = funcfparam_list;
    } | FuncFParamList COMMA FuncFParam {
      auto funcfparam_list = $1;
      funcfparam_list->push_back($3);
      $$ = funcfparam_list;
    }

FuncFParam
    : INT IDENT {
      auto ast = new FuncFParamAST();
      auto type_ast = new TypeAST();
      type_ast->type = TypeType::Int;
      ast->btype = type_ast;
      ast->type = FuncFParamType::Var;
      ast->ident = unique_ptr<string>($2);
      $$ = ast;
    } | INT IDENT LBRACKET RBRACKET {
      auto ast = new FuncFParamAST();
      auto type_ast = new TypeAST();
      type_ast->type = TypeType::Int;
      ast->btype = type_ast;
      ast->type = FuncFParamType::Array;
      ast->ident = unique_ptr<string>($2);
      ast->array = new std::vector<string>;
      $$ = ast;
    } | INT IDENT LBRACKET RBRACKET ArrayDimList{
      auto ast = new FuncFParamAST();
      auto type_ast = new TypeAST();
      type_ast->type = TypeType::Int;
      ast->btype = type_ast;
      ast->type = FuncFParamType::Array;
      ast->ident = unique_ptr<string>($2);
      ast->array = $5;
      $$ = ast;
    }

Block
    : LBRACE BlockItemList RBRACE {
      auto ast = new BlockAST();
      ast->block_item_list = *($2);;
      $$ = ast;
    }
    ;

Stmt
  : LVal ASSIGN Exp SEMICOLON{
    auto ast = new StmtAST();
    ast->type = StmtType::LValAssignExp;
    ast->lval_ast = unique_ptr<BaseAST>($1);
    ast->exp_ast = unique_ptr<BaseAST>($3);
    $$ = ast;
  } | SEMICOLON {
    auto ast = new StmtAST();
    ast->type = StmtType::None;
    $$ = ast;
  } | Exp SEMICOLON{
    auto ast = new StmtAST();
    ast->type = StmtType::SingleExp;
  } | Block {
    auto ast = new StmtAST();
    ast->type = StmtType::Block;
    ast->block_ast = unique_ptr<BaseAST>($1);
    $$ = ast;
  } | IF LPAREN Exp RPAREN Stmt {
    auto ast = new StmtAST();
    ast->type = StmtType::OnlyIf;
    ast->exp_ast = unique_ptr<BaseAST>($3);
    ast->stmt_ast = unique_ptr<BaseAST>($5);
    $$ = ast;
  } | IF LPAREN Exp RPAREN Stmt ELSE Stmt {
    auto ast = new StmtAST();
    ast->type = StmtType::IfElse;
    ast->exp_ast = unique_ptr<BaseAST>($3);
    ast->stmt_ast = unique_ptr<BaseAST>($5);
    ast->else_stmt_ast = unique_ptr<BaseAST>($7);
    $$ = ast;
  } | WHILE LPAREN Exp RPAREN Stmt {
    auto ast = new StmtAST();
    ast->type = StmtType::While;
    ast->exp_ast = unique_ptr<BaseAST>($3);
    ast->stmt_ast = unique_ptr<BaseAST>($5);
    $$ = ast;
  } | BREAK SEMICOLON {
    auto ast = new StmtAST();
    ast->type = StmtType::Break;
    $$ = ast;
  } | CONTINUE SEMICOLON {
    auto ast = new StmtAST();
    ast->type = StmtType::Continue;
    $$ = ast;
  } | RETURN SEMICOLON {
    auto ast = new StmtAST();
    ast->type = StmtType::OnlyReturn;
    $$ = ast;
  } | RETURN Exp SEMICOLON {
    auto ast = new StmtAST();
    ast->type = StmtType::Return;
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
  } | LVal {
    auto ast = new PrimaryExpAST();
    ast->type = PrimaryExpType::LVal;
    ast->primary_exp_ast = unique_ptr<BaseAST>($1);
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
  } | IDENT LPAREN FuncRParams RPAREN {
    auto ast = new UnaryExpAST();
    ast->type = UnaryExpType::IdentFuncRParams;
    ast->ident = unique_ptr<string>($1);
    ast->funcrparams = *($3);
    $$ = ast;
  } | IDENT LPAREN RPAREN {
    auto ast = new UnaryExpAST();
    ast->type = UnaryExpType::OnlyIdent;
    ast->ident = unique_ptr<string>($1);
    $$ = ast;
  }

FuncRParams
  : Exp {
    auto funcrparams = new std::vector<BaseAST*>;
    funcrparams->push_back($1);
    $$ = funcrparams;
  } | FuncRParams COMMA Exp {
    auto funcrparams = $1;
    funcrparams->push_back($3);
    $$ = funcrparams;
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

Decl
  : VarDecl {
    auto ast = new DeclAST();
    ast->decl_ast = unique_ptr<BaseAST>($1);
    $$ = ast;
  }

/* Decl
  : ConstDecl { 
    auto ast = new DeclAST();
    ast->decl_ast = unique_ptr<BaseAST>($1);
    $$ = ast;
  } | VarDecl {
    auto ast = new DeclAST();
    ast->decl_ast = unique_ptr<BaseAST>($1);
    $$ = ast;
  } */

/* ConstDefList
  : {
    auto const_def_list = new std::vector<BaseAST*>;
    $$ = const_def_list;
  } | ConstDefList COMMA ConstDef {
    auto const_def_list = $1;
    const_def_list->push_back($3);
    $$ = const_def_list;
  }

ConstDecl
  : CONST Type ConstDef ConstDefList SEMICOLON {
    auto ast = new ConstDeclAST();
    ast->btype_ast = unique_ptr<BaseAST>($2);
    ast->const_def_ast = unique_ptr<BaseAST>($3);
    ast->const_def_list = *($4);
    $$ = ast;
  }

ConstDef
  : IDENT ASSIGN ConstInitVal {
    auto ast = new ConstDefAST();
    ast->ident = unique_ptr<string>($1);
    ast->const_init_val_ast = unique_ptr<BaseAST>($3);
    $$ = ast;
  }

ConstInitVal
  : ConstExp {
    auto ast = new ConstInitValAST();
    ast->const_exp_ast = unique_ptr<BaseAST>($1);
    $$ = ast;
  } */

BlockItemList
  : {
    auto block_item_list = new vector<BaseAST*>;
    $$ = block_item_list;
  } | BlockItemList BlockItem {
    auto block_item_list = $1;
    block_item_list->push_back($2);
    $$ = block_item_list;
  }

BlockItem
  : Decl { 
    auto ast = new BlockItemAST();
    ast->block_item_ast = unique_ptr<BaseAST>($1);
    $$ = ast;
  } | Stmt {
    auto ast = new BlockItemAST();
    ast->block_item_ast = unique_ptr<BaseAST>($1);
    $$ = ast;
  }
  ;

LVal
  : IDENT {
    auto ast = new LValAST();
    ast->ident = unique_ptr<string>($1);
    $$ = ast;
  }

/* ConstExp
  : Exp {
    auto ast = new ConstExpAST();
    ast->exp_ast = unique_ptr<BaseAST>($1);
    $$ = ast;
  } */

VarDefList
  : {
    auto var_def_list = new vector<BaseAST*>;
    $$ = var_def_list;
  } | VarDefList COMMA VarDef {
    auto var_def_list = $1;
    var_def_list->push_back($3);
    $$ = var_def_list;
  }

VarDecl
  : Type VarDef VarDefList SEMICOLON {
    auto ast = new VarDeclAST();
    ast->btype_ast = unique_ptr<BaseAST>($1);
    ast->var_def_ast = unique_ptr<BaseAST>($2);
    $$ = ast;
  }

VarDef
  : IDENT {
    auto ast = new VarDefAST();
    ast->type = VarDefType::Ident;
    ast->ident = unique_ptr<string>($1);
    $$ = ast;
  } | IDENT ASSIGN InitVal {
    auto ast = new VarDefAST();
    ast->type = VarDefType::IdentAssignInitVal;
    ast->ident = unique_ptr<string>($1);
    ast->init_val_ast = unique_ptr<BaseAST>($3);
    $$ = ast;
  } | IDENT ArrayDimList {
    auto ast = new VarDefAST();
    ast->type = VarDefType::InitArray;
    ast->ident = unique_ptr<string>($1);
    ast->init_array = $2;
    $$ = ast;
  } 

ArrayDimList
  : LBRACKET INT_CONST RBRACKET {
    auto array_dim_list = new vector<string>;
    array_dim_list->push_back(to_string($2));
    $$ = array_dim_list;
  } | ArrayDimList LBRACKET INT_CONST RBRACKET {
    auto array_dim_list = $1;
    array_dim_list->push_back(to_string($3));
    $$ = array_dim_list;
  }

InitVal
  : Exp {
    auto ast = new InitValAST();
    ast->exp_ast = unique_ptr<BaseAST>($1);
    $$ = ast;
  }

%%

void yyerror(unique_ptr<BaseAST> &ast, const char *s) {
    cerr << "error: " << s << endl;
}
