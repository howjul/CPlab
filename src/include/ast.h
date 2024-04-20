#pragma once
#include <cassert>
#include <cstdio>
#include <iostream>
#include <memory>
#include <string>

using namespace std;

enum PrimaryExpType { Exp, Number };
enum UnaryExpType { PrimaryExp, UnaryOpandUnaryExp };
enum MulExpType { UnaryExp, MulExpMulOpUnaryExp };
enum AddExpType { MulExp, AddExpAddOpMulExp };

// 所有 AST 的基类
class BaseAST {
 public:
  virtual ~BaseAST() = default;
  virtual void dump() const = 0;
};

class CompUnitAST : public BaseAST {
 public:
  std::unique_ptr<BaseAST> func_def;

  void dump() const override{
    cout << "CompUnitAST { ";
    func_def->dump();
    cout << " }";
  }
};

class FuncDefAST : public BaseAST {
 public:
  std::unique_ptr<BaseAST> func_type;
  std::unique_ptr<string> ident;
  std::unique_ptr<BaseAST> block;

  void dump() const override{
    cout << "FuncDef { ";
    func_type->dump();
    cout << ", " << *ident << ", ";
    block->dump();
    cout << " }";
  }
};

class FuncTypeAST : public BaseAST {
 public:
  std::string type;

  void dump() const override{
    cout << "FuncType { " << type << " }";
  }
};

class BlockAST : public BaseAST {
 public:
  std::unique_ptr<BaseAST> stmt;

  void dump() const override{
    cout << "Block { ";
    stmt->dump();
    cout << " }";
  }
};

class StmtAST : public BaseAST {
 public:
  std::unique_ptr<BaseAST> exp_ast;

  void dump() const override{
    cout << "Stmt { ";
    exp_ast->dump();
    cout << "; }";
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
    std::unique_ptr<BaseAST> add_exp_ast;
  
    void dump() const override{
      cout << "Exp { ";
      add_exp_ast->dump();
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
    }
};

class UnaryExpAST: public BaseAST {
  public:
    UnaryExpType type;
    std::unique_ptr<BaseAST> primary_exp_ast;
    std::unique_ptr<string> unary_op;
    std::unique_ptr<BaseAST> unary_exp_ast;
  
    void dump() const override{
      if (type == UnaryExpType::PrimaryExp) {
        cout << "UnaryExp { ";
        primary_exp_ast->dump();
        cout << " }";
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