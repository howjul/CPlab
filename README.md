## 1. 文件结构与使用说明

根目录下，使用`make`命令可以直接`src`中的文件，并自动对根目录下`test.c`文件进行词法分析和语法分析。若文件内容符合文法，则输出语法树；若文件不符合文法，则报错退出。使用`make clean`命令，清除生成的中间文件和可执行文件。

`src`文件夹下为代码源文件：

- `include`：包含`ast.h`头文件，定义了抽象语法树AST的节点结构，这些节点在语法分析阶段被创建，用于表示程序的结构。
- `main.cpp`：程序的主入口文件。它包含了主函数main()，该函数负责初始化词法分析器和语法分析器，读取输入文件（如test.c），并触发词法和语法分析过程。分析成功后，它将构建并可能输出抽象语法树。
- `sysy.l`：词法分析器的定义文件，用于定义程序中用到的词法规则。
- `sysy.y`：语法分析器的定义文件，用于定义语法规则和相应的处理代码。

`tests`文件夹下测试样例，在根目录下首先使用`make`进行编译，再进入`tests`目录，`python3 test.py ../sysy.out lab1`即可进行样例测试。

```
CPlab
├── README.md
├── makefile
├── src
│   ├── include
│   │   └── ast.h
│   ├── main.cpp
│   ├── sysy.l
│   └── sysy.y
├── test.c
└── tests
    └── ...
```

## 2. 功能实现

### 词法分析

词法分析可以从源代码中提取词法单元，为后续的语法分析阶段做准备，具体实现规则如下：

- 空白符和注释：定义处理空白符（空格、制表符、换行符）和注释（单行和多行）的规则，这些文本被识别后不进行任何操作。
- 关键字和运算符：定义每个关键字（如 `int`, `void`, `if` 等），运算符（如 `+`, `-`, `*` 等）和连接符（如 `,`, `;`, `(` 等）的规则，返回对应的 token。
- 标识符和整数字面量：定义了标识符以及十进制整数的规则，返回字符串或者整数。
- 如上词法已经穷举所有的情况，如果无法与上述词法匹配，则肯定有不符合词法的错误，因此报错。

### 语法分析

按照程序的语法规则, 将输入的 token 流变成程序的 AST。

#### 数据类型

- parser 函数参数（%parse-param）： 由于函数返回类型一定是 int, 所以通过参数来返回 AST。
- 数据类型（%union）：定义了Bison动作中不同类型的数据，用于如下终结符和非终结符的定义。
- 终结符（%token）：声明了用于词法分析的关键字，标识符和整数。
- 非终结符（%type）：声明了非终结符，大部分非终结符都是一个 AST 节点的指针。还有指向 AST 节点数组的指针，用于 EBNF 中的递归情况，比如 `LVal::= IDENT {"[" Exp "]"};`。字符串类型的非终结符用于运算符号比如加减乘除或者逻辑运算。字符串数组类型的非终结符用于数组的索引。

#### 语法规则

语法规则部分代码整体按照给出的 EBNF 进行设计，这里仅介绍较为特殊的几个实现。

`CompUnit`：`CompUnit ::= [CompUnit] (Decl | FuncDef);`，`CompUnit` 是程序的顶层结构，可以包含多个声明和函数定义。这里情况较为复杂，考虑到这里的意思其实就是多个 `Decl` 和 `FuncDef` 的组合，所以我们直接维护了两个 vector 数组来存放声明和函数定义的语法树结构。每当匹配到 Decl 或者 FuncDef，就直接将其语法树结构 push 到数组中。

递归情况（以 `VarDecl` 为例）：`VarDecl ::= BType VarDef {"," VarDef} ";";`，`VarDecl` 指的是变量的声明，在这里出现的比较典型的规则是 `{...}`，表示花括号内包含的项可被重复零次或多次。对于此类 EBNF，我们采用刚刚在数据类型中所提到的 AST 节点指针数组来进行存放。首先我们加入非终结符 `VarDefList` ，然后把式子分成了两个部分 `VarDecl := BType VarDef VarDefList ";";` 和 `VarDefList := VarDefList "," VarDef`，当然 `VarDefList` 可能为空，如果为空，即 vector 数组为空。每当匹配到逗号和 `VarDef`，就将 `VarDef` 语法树结构 push 到 `VarDefList` 中。

```bison
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
    ast->var_def_list = *($3);
    $$ = ast;
  }
```

或者情况（以 `PrimaryExp` 为例）：对于 `PrimaryExp ::= "(" Exp ")" | LVal | Number;` 这种，有多种情况的时候，由于对应的都是 `PrimaryExp` 类型的 AST 树，为了让 AST 树知道匹配到的是哪种情况，在 `ast.h` 头文件中定义了枚举 `enum PrimaryExpType { Exp, Number, LVal };`，来记录实际匹配到的生成式。

```bison
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
```

`BType` & `FuncType`：由于`BType ::= "int";` `FuncType ::= "void" | "int";` 会产生冲突，所以将这两者合并为一个非终结符号 `Type`。也就是说所有的 `int` 都会被归约为 `Type`，也就避免了冲突的发生。

无 AST 树结构非终结符：这种类型的非终结符数量较少，主要有两类。第一类是各种符号包括 `UnaryOp` `MulOp` `AddOp` `RelOp` 和 `EqOp`，他们都是字符串类型，直接返回字符串，然后传给归约目标的 AST 树结构中。第二类是数组的索引，因为数组的索引可以有无限维，所以直接使用一个字符串数组来进行存储。

```bison
MulOp
  : TIMES { $$ = new string("*"); }
  | DIVIDE { $$ = new string("/"); }
  | MOD { $$ = new string("%"); }
```

#### 语法树

AST 类的定义：在 `ast.h` 中定义了所有 AST 节点的类。每个类都继承自 `BaseAST` 基类，基类定义了一个虚析构函数和一个纯虚函数 `dump` 用于输出节点的结构。`dump` 函数是打印语法树的核心，当一个 AST 类中含有别的子树，那么打印的时候直接调用子树的 `dump`，其他信息则预先设定，直接打印。

AST 节点构造：每个语法规则都伴随着构建 AST 的动作，这些动作实例化相应的 AST 节点类，设置它们的属性，并将它们链接成树结构。例如，在函数定义规则中，创建了一个 `FuncDefAST` 节点，并将其类型、标识符、参数和函数体作为子节点进行关联。

```bison
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
```
