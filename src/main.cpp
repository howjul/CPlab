#include "include/ast.h"

extern FILE *yyin;
extern int yyparse(std::unique_ptr<BaseAST> &ast);

int main(int argc, const char **argv) {
    // // 解析命令行参数. 测试脚本/评测平台要求你的编译器能接收如下参数:
    // // compiler 模式 输入文件 -o 输出文件
    // assert(argc == 5);
    // auto mode = argv[1];
    // auto input = argv[2];
    // auto output = argv[4];
    auto input = argv[1];

    // 打开输入文件, 并且指定 lexer 在解析的时候读取这个文件
    yyin = fopen(input, "r");
    assert(yyin);

    // 调用 parser 函数, parser 函数会进一步调用 lexer 解析输入文件的
    unique_ptr<BaseAST> ast;
    auto ret = yyparse(ast);
    assert(!ret);

    // 输出解析得到的 AST, 其实就是个字符串
    ast->dump();
    cout << endl;
    return 0;
}


