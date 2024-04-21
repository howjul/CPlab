#pragma once
#include <cassert>
#include <cstdio>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

using namespace std;

enum PrimaryExpType { Exp, Number, LVal };
enum UnaryExpType { PrimaryExp, UnaryOpandUnaryExp, IdentFuncRParams, OnlyIdent };
enum MulExpType { UnaryExp, MulExpMulOpUnaryExp };
enum AddExpType { MulExp, AddExpAddOpMulExp };
enum RelExpType { AddExp, RelExpRelOpAddExp };
enum EqExpType { RelExp, EqExpEqOpRelExp };
enum LAndExpType { EqExp, LAndExpAndOpEqExp };
enum LOrExpType { LAndExp, LOrExpOrOpLAndExp };
enum BlockItemType { Decl, Stmt };
enum DeclType { ConstDecl, VarDecl };
enum VarDefType { Ident, IdentAssignInitVal, InitArray };
enum StmtType { LValAssignExp, None, SingleExp, Block, Return, OnlyReturn, OnlyIf, IfElse, While, Break, Continue };
enum TypeType { Void, Int };
enum FuncDefType { NoParams, WithParams };
enum FuncFParamType { Var, Array };


// 所有 AST 的基类
class BaseAST {
 public:
  virtual ~BaseAST() = default;
  virtual void dump() const = 0;
};

class startAST: public BaseAST {
 public:
  std::unique_ptr<BaseAST> comp_unit_ast;

  void dump() const override{
    comp_unit_ast->dump();
  }
};

class CompUnitAST : public BaseAST {
 public:
  vector<BaseAST*> decl_list;
  vector<BaseAST*> func_def_list;

  void dump() const override{
    cout << "CompUnit { ";
    for (auto decl : decl_list) decl->dump();
    for (auto func_def : func_def_list) func_def->dump();
    cout << " }";
  }
};

class FuncDefAST : public BaseAST {
 public:
  FuncDefType type;
  std::unique_ptr<BaseAST> func_type;
  std::unique_ptr<string> ident;
  std::unique_ptr<BaseAST> block;
  std::unique_ptr<BaseAST> funcfparams;

  void dump() const override{
    if(type == FuncDefType::NoParams){
      cout << "FuncDef { ";
      func_type->dump();
      cout << " " << *ident << " ";
      block->dump();
      cout << " }";
    }
    if(type == FuncDefType::WithParams){
      cout << "FuncDef { ";
      func_type->dump();
      cout << " " << *ident << " ( ";
      funcfparams->dump();
      cout << " ) ";
      block->dump();
      cout << " }";
    }
  }
};

class TypeAST : public BaseAST {
 public:
  TypeType type;

  void dump() const override{
    if (type == TypeType::Void) cout << "void";
    if (type == TypeType::Int) cout << "int";
  }
};

class FuncFParamsAST : public BaseAST {
 public:
  std::vector<BaseAST*> funcfparam_list;
  std::unique_ptr<BaseAST> funcfparam_ast;

  void dump() const override{
    cout << "FuncFParams { ";
    funcfparam_ast->dump();
    cout << " ";
    for (auto funcfparam : funcfparam_list) {
      cout << ", ";
      funcfparam->dump();
    }
    cout << " }";
  }
};

class FuncFParamAST : public BaseAST {
 public:
  FuncFParamType type;
  BaseAST* btype;
  std::unique_ptr<string> ident;
  vector<string>* array;

  void dump() const override{
    btype->dump();
    cout << " " << *ident << " ";
    if(type == FuncFParamType::Array){
      cout << "[]";
      for (auto i : *array){
        cout << "[" << i << "]";
      }
    }
  }
};

class BlockAST : public BaseAST {
 public:
  std::vector<BaseAST*> block_item_list;

  void dump() const override{
    cout << "Block { ";
    for (auto block_item : block_item_list) block_item->dump();
    cout << " }";
  }
};

class StmtAST : public BaseAST {
 public:
  StmtType type;
  std::unique_ptr<BaseAST> exp_ast;
  std::unique_ptr<BaseAST> lval_ast;
  std::unique_ptr<BaseAST> block_ast;
  std::unique_ptr<BaseAST> stmt_ast;
  std::unique_ptr<BaseAST> else_stmt_ast;

  void dump() const override{
    if (type == StmtType::LValAssignExp){
      cout << "Stmt { ";
      lval_ast->dump();
      cout << " = ";
      exp_ast->dump();
      cout << "; }";
    }
    if (type == StmtType::Return){
      cout << "Stmt { return ";
      exp_ast->dump();
      cout << "; }";
    }
    if (type == StmtType::None){
      cout << "Stmt { ; }";
    }
    if (type == StmtType::SingleExp){
      cout << "Stmt { ";
      exp_ast->dump();
      cout << " }";
    }
    if (type == StmtType::Block){
      cout << "Stmt { ";
      block_ast->dump();
      cout << " }";
    }
    if (type == StmtType::OnlyReturn){
      cout << "Stmt { return; }";
    }
    if (type == StmtType::OnlyIf){
      cout << "Stmt { if (";
      exp_ast->dump();
      cout << ") ";
      stmt_ast->dump();
      cout << " }";
    }
    if (type == StmtType::IfElse){
      cout << "Stmt { if ( ";
      exp_ast->dump();
      cout << " ) { ";
      stmt_ast->dump();
      cout << " } else { ";
      else_stmt_ast->dump();
      cout << " }";
    }
    if (type == StmtType::While){
      cout << "Stmt { while ( ";
      exp_ast->dump();
      cout << " ) { ";
      stmt_ast->dump();
      cout << " }";
    }
    if (type == StmtType::Break){
      cout << "Stmt { break; }";
    }
    if (type == StmtType::Continue){
      cout << "Stmt { continue; }";
    }
  }
};

class NumberAST : public BaseAST {
 public:
  int val;

  void dump() const override{
    // cout << "Number { " << val << " }";
    cout << val;
  }
};

class ExpAST: public BaseAST {
  public:
    std::unique_ptr<BaseAST> lor_exp_ast;
  
    void dump() const override{
      cout << "Exp { ";
      lor_exp_ast->dump();
      cout << " }";
    }
};

class PrimaryExpAST: public BaseAST {
  public:
    PrimaryExpType type;
    std::unique_ptr<BaseAST> primary_exp_ast;
  
    void dump() const override{
      if (type == PrimaryExpType::Exp) {
        cout << "PrimaryExp { (";
        primary_exp_ast->dump();
        cout << ") }";
      } 
      if (type == PrimaryExpType::Number){
        cout << "PrimaryExp { ";
        primary_exp_ast->dump();
        cout << " }";
      }
      if (type == PrimaryExpType::LVal){
        cout << "PrimaryExp { ";
        primary_exp_ast->dump();
        cout << " }";
      }
    }
};

class UnaryExpAST: public BaseAST {
  public:
    UnaryExpType type;
    std::unique_ptr<BaseAST> primary_exp_ast;
    std::unique_ptr<string> unary_op;
    std::unique_ptr<BaseAST> unary_exp_ast;
    std::vector<BaseAST*> funcrparams;
    std::unique_ptr<string> ident;
  
    void dump() const override{
      if (type == UnaryExpType::PrimaryExp) {
        cout << "UnaryExp { ";
        primary_exp_ast->dump();
        cout << " }";
      }
      if (type == UnaryExpType::OnlyIdent){
        cout << "UnaryExp { " << *ident << "() }";
      }
      if (type == UnaryExpType::IdentFuncRParams){
        cout << "UnaryExp { ";
        cout << *ident << "(";
        for (auto funcrparam : funcrparams) {
          funcrparam->dump();
        }
        cout << ") }";
      }
      if (type == UnaryExpType::UnaryOpandUnaryExp){
        cout << "UnaryExp { " << *unary_op << " ";
        unary_exp_ast->dump();
        cout << " }";
      }
    }
};

class AddExpAST: public BaseAST {
  public:
    AddExpType type;
    std::unique_ptr<BaseAST> mul_exp_ast;
    std::unique_ptr<string> add_op;
    std::unique_ptr<BaseAST> add_exp_ast;

    void dump() const override{
      if (type == AddExpType::MulExp) {
        cout << "AddExp { ";
        mul_exp_ast->dump();
        cout << " }";
      } 
      if (type == AddExpType::AddExpAddOpMulExp){
        cout << "AddExp { ";
        add_exp_ast->dump();
        cout << " " << *add_op << " ";
        mul_exp_ast->dump();
        cout << " }";
      }
    }
};

class MulExpAST: public BaseAST {
  public:
    MulExpType type;
    std::unique_ptr<BaseAST> mul_exp_ast;
    std::unique_ptr<string> mul_op;
    std::unique_ptr<BaseAST> unary_exp_ast;
    
    void dump() const override{
      if (type == MulExpType::UnaryExp) {
        cout << "MulExp { ";
        unary_exp_ast->dump();
        cout << " }";
      } 
      if (type == MulExpType::MulExpMulOpUnaryExp){
        cout << "MulExp { ";
        mul_exp_ast->dump();
        cout << " " << *mul_op << " ";
        unary_exp_ast->dump();
        cout << " }";
      }
    }
};

class RelExpAST: public BaseAST {
  public:
    RelExpType type;
    std::unique_ptr<BaseAST> add_exp_ast;
    std::unique_ptr<string> rel_op;
    std::unique_ptr<BaseAST> rel_exp_ast;

    void dump() const override{
      if (type == RelExpType::AddExp) {
        cout << "RelExp { ";
        add_exp_ast->dump();
        cout << " }";
      } 
      if (type == RelExpType::RelExpRelOpAddExp){
        cout << "RelExp { ";
        rel_exp_ast->dump();
        cout << " " << *rel_op << " ";
        add_exp_ast->dump();
        cout << " }";
      }
    }
};

class EqExpAST: public BaseAST {
  public:
    EqExpType type;
    std::unique_ptr<BaseAST> rel_exp_ast;
    std::unique_ptr<string> eq_op;
    std::unique_ptr<BaseAST> eq_exp_ast;

    void dump() const override{
      if (type == EqExpType::RelExp) {
        cout << "EqExp { ";
        rel_exp_ast->dump();
        cout << " }";
      } 
      if (type == EqExpType::EqExpEqOpRelExp){
        cout << "EqExp { ";
        eq_exp_ast->dump();
        cout << " " << *eq_op << " ";
        rel_exp_ast->dump();
        cout << " }";
      }
    }
};

class LAndExpAST: public BaseAST {
  public:
    LAndExpType type;
    std::unique_ptr<BaseAST> eq_exp_ast;
    std::unique_ptr<string> and_op = std::make_unique<string>("&&");
    std::unique_ptr<BaseAST> land_exp_ast;

    void dump() const override{
      if (type == LAndExpType::EqExp) {
        cout << "LAndExp { ";
        eq_exp_ast->dump();
        cout << " }";
      } 
      if (type == LAndExpType::LAndExpAndOpEqExp){
        cout << "LAndExp { ";
        land_exp_ast->dump();
        cout << " " << *and_op << " ";
        eq_exp_ast->dump();
        cout << " }";
      }
    }
};

class LOrExpAST: public BaseAST {
  public:
    LOrExpType type;
    std::unique_ptr<BaseAST> land_exp_ast;
    std::unique_ptr<string> or_op = std::make_unique<string>("||");
    std::unique_ptr<BaseAST> lor_exp_ast;

    void dump() const override{
      if (type == LOrExpType::LAndExp) {
        cout << "LOrExp { ";
        land_exp_ast->dump();
        cout << " }";
      } 
      if (type == LOrExpType::LOrExpOrOpLAndExp){
        cout << "LOrExp { ";
        lor_exp_ast->dump();
        cout << " " << *or_op << " ";
        land_exp_ast->dump();
        cout << " }";
      }
    }
};

class DeclAST : public BaseAST {
 public:
  std::unique_ptr<BaseAST> decl_ast;

  void dump() const override{
    cout << "Decl { ";
    decl_ast->dump();
    cout << " }";
  }
};

// class ConstDeclAST : public BaseAST {
//  public:
//   std::vector<BaseAST*> const_def_list;
//   std::unique_ptr<BaseAST> const_def_ast;
//   std::unique_ptr<BaseAST> btype_ast;

//   void dump() const override{
//     cout << "ConstDecl { const ";
//     btype_ast->dump();
//     const_def_ast->dump();
//     cout << " ";
//     for (auto const_def : const_def_list) {
//       cout << ", ";
//       const_def->dump();
//     }
//     cout << " ;";
//     cout << " }";
//   }
// };

// class ConstDefAST : public BaseAST {
//  public:
//   std::unique_ptr<string> ident;
//   std::unique_ptr<BaseAST> const_init_val_ast;

//   void dump() const override{
//     cout << "ConstDef { ";
//     cout << *ident << " = ";
//     const_init_val_ast->dump();
//     cout << " }";
//   }
// };

// class ConstInitValAST : public BaseAST {
//  public:
//   std::unique_ptr<BaseAST> const_exp_ast;

//   void dump() const override{
//     cout << "ConstInitVal { ";
//     const_exp_ast->dump();
//     cout << " }";
//   }
// };

// class ConstExpAST : public BaseAST{
//   public:
//     std::unique_ptr<BaseAST> exp_ast;

//   void dump() const override{
//     cout << "ConstExp { ";
//     exp_ast->dump();
//     cout << " }";
//   }
// };

class BlockItemAST : public BaseAST{
  public:
    std::unique_ptr<BaseAST> block_item_ast;
    BlockItemType type;

    void dump() const override{
      cout << "BlockItem { ";
      block_item_ast->dump();
      cout << " }";
    }
};

class LValAST : public BaseAST {
  public:
    std::unique_ptr<string> ident;

    void dump() const override{
      cout << "LVal { " << *ident << " }";
    }
};

class VarDeclAST : public BaseAST {
 public:
  std::vector<BaseAST*> var_def_list;
  std::unique_ptr<BaseAST> var_def_ast;
  std::unique_ptr<BaseAST> btype_ast;

  void dump() const override{
    cout << "VarDecl { ";
    btype_ast->dump();
    var_def_ast->dump();
    cout << " ";
    for (auto var_def : var_def_list) {
      cout << ", ";
      var_def->dump();
    }
    cout << " ;";
    cout << " }";
  }
};

class VarDefAST : public BaseAST {
 public:
  VarDefType type;
  std::unique_ptr<string> ident;
  std::unique_ptr<BaseAST> init_val_ast;
  std::vector<string>* init_array;

  void dump() const override{
    if (type == VarDefType::Ident){
      cout << "VarDef { ";
      cout << *ident;
      cout << " }";
    }
    if (type == VarDefType::IdentAssignInitVal){
      cout << "VarDef { ";
      cout << *ident;
      cout << " = ";
      init_val_ast->dump();
      cout << " }";
    }
    if (type == VarDefType::InitArray){
      cout << "VarDef { ";
      cout << *ident;
      for (auto i : *init_array){
        cout << "[" << i << "] ";
      }
      cout << " }";
    }
  }
};

class InitValAST : public BaseAST {
 public:
  std::unique_ptr<BaseAST> exp_ast;

  void dump() const override{
    cout << "InitVal { ";
    exp_ast->dump();
    cout << " }";
  }
};