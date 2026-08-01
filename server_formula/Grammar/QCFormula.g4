grammar QCFormula;

/*
 * QC Formula Grammar
 * This grammar defines the syntax for the qc_formula language.
 * It supports variable assignments, arithmetic and logical expressions, 
 * parameters, and function calls.
 */

// --- Parser Rules ---

// The entry point for the grammar. A program consists of zero or more
// statements followed by a mandatory final expression.
prog: (statement)* final_expression EOF;

// A statement is an assignment followed by a semicolon.
statement
    : assignment ';'
    ;

// An assignment gives a value to a variable.
assignment
    : ID T_ASSIGN expression
    ;

// The final part of the script, which is an expression that provides the return value.
final_expression
    : expression ';'?
    ;

// Expression rule with precedence climbing and labeled alternatives.
// Precedence is from lowest to highest.
expression
    : T_SUB expression                   # UnaryMinusExpr
    | <assoc=right> expression T_POW expression # PowExpr
    | expression (T_MUL | T_DIV) expression # MulDivExpr
    | expression (T_ADD | T_SUB) expression # AddSubExpr
    | expression (T_GT | T_GTE | T_LT | T_LTE) expression # CompExpr
    | expression (T_EQ | T_NEQ) expression # EqExpr
    | expression T_AND expression        # AndExpr
    | expression T_OR expression         # OrExpr
    | atom                               # AtomExpr
    ;

// Atomic elements of an expression.
atom
    : T_LPAREN expression T_RPAREN       # ParenExpr
    | T_LBRACK ID T_RBRACK               # ParamExpr
    | T_LDBRACK ID T_RDBRACK             # ArrayParamExpr
    | ID T_LPAREN (arg_list)? T_RPAREN   # FuncCallExpr
    | ID                                 # VarExpr
    | NUMBER                             # NumberExpr
    ;

// A comma-separated list of arguments for function calls.
arg_list
    : expression (T_COMMA expression)*
    ;


// --- Lexer Rules ---

// Operators
T_ADD: '+';
T_SUB: '-';
T_MUL: '*';
T_DIV: '/';
T_POW: '^';

// Logical Operators
T_AND: '&&';
T_OR: '||';

// Comparison Operators
T_GT: '>';
T_GTE: '>=';
T_LT: '<';
T_LTE: '<=';
T_EQ: '==';
T_NEQ: '!=';

// Symbols
T_ASSIGN: '=';
T_LPAREN: '(';
T_RPAREN: ')';
T_LDBRACK: '[[';
T_RDBRACK: ']]';
T_LBRACK: '[';
T_RBRACK: ']';
T_SEMICOLON: ';';
T_COMMA: ',';

// Identifiers (for variables and function names)
ID: [a-zA-Z_] [a-zA-Z0-9_]*;

// Numeric literals (integers and decimals)
NUMBER: [0-9]+ ('.' [0-9]+)?;

// Skip comments (single line)
COMMENT: '//' ~[\r\n]* -> skip;

// Skip whitespace characters
WS: [ \t\r\n]+ -> skip;
