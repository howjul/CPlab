CC=g++
CFLAGS=--std=c++14 -Isrc/include
FLEX=flex
BISON=bison

# 生成目标：sysy.out 和执行 sysy.out
all: run

# 链接生成最终可执行文件 sysy.out
sysy.out: src/sysy.tab.cpp src/sysy.lex.cpp src/main.cpp
	$(CC) src/sysy.tab.cpp src/sysy.lex.cpp src/main.cpp $(CFLAGS) -o sysy.out

# 使用 Bison 生成语法分析器的源文件
src/sysy.tab.cpp: src/sysy.y
	$(BISON) -d -o src/sysy.tab.cpp src/sysy.y

# 使用 Flex 生成词法分析器的源文件
src/sysy.lex.cpp: src/sysy.l
	$(FLEX) -o src/sysy.lex.cpp src/sysy.l

# 执行 sysy.out 文件，并将 test.c 作为输入
run: sysy.out
	./sysy.out test.c

# 清理生成的文件
clean:
	rm -f sysy.out src/sysy.tab.cpp src/sysy.tab.hpp src/sysy.lex.cpp

.PHONY: all run clean
