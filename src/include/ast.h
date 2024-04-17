#pragma once
#include <cassert>
#include <cstdio>
#include <iostream>
#include <memory>
#include <string>

using namespace std;

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
  std::unique_ptr<BaseAST> Number;

  void dump() const override{
    cout << "Stmt { ";
    Number->dump();
    cout << " }";
  }
};

class NumberAST : public BaseAST {
 public:
  int val;

  void dump() const override{
    cout << "Number { " << val << " }";
  }
};
