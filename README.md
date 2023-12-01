# Echo Programming Language Compiler

## Overview

"Echo" is a developer-friendly C-based programming language designed for simplicity and efficient compilation. This repository contains the compiler for the "echo" language, focusing on fast compilation times and generating reliable executables.

## Compiler Details

- Modular architecture with components such as lexer, parser, and semantic analysis.
- Robust error handling, clear messages, and graceful recovery strategies.
- Rigorous testing, including unit and integration tests, ensures reliability.

## Parsing Technique

### Bottom-Up Parsing (LALR)

- Implemented using Yacc, starting from input symbols towards the start symbol of the grammar.
- LALR parsing with a fixed number of lookahead symbols for parsing decisions.
- Left-to-right reading, processing input symbols from left to right.
- Emphasis on rightmost derivation, building the parse tree from leaves to the root.

## Keywords in Echo Language

- "Echo": Corresponds to void.
- Loop Keywords: "loop," "whilst."
- Control Flow Keywords: "interrupt," "resume," "condition," "else," "result."
- Data Type Keywords: "number," "character," "decimal," "precision."
- Modifier Keywords: "lengthy," "very lengthy," "short," "negative," "positive."

## Grammar

- Context-free grammar (Type 2) describing syntax with terminals, non-terminals, production rules, and a start symbol.

## Usage

Make sure `flex` and `bison` are downloaded and added to the system's path variables.

### Commands

```bash
# Generate lexer
flex ECHO-Scanner.l

# Generate parser
bison -dy ECHO-Parser.y

# Compile the code
gcc y.tab.c -w -o a

# Run with input testcase
./a <input testcase.c>
