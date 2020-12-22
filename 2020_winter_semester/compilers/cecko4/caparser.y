%language "c++"
%require "3.4"
// NEVER SET THIS INTERNALLY - SHALL BE SET BY CMAKE: %defines "../private/caparser.hpp"
// NEVER SET THIS INTERNALLY - SHALL BE SET BY CMAKE: %output "../private/caparser.cpp"
%locations
%define api.location.type {cecko::loc_t}
%define api.namespace {cecko}
%define api.value.type variant
%define api.token.constructor
%define api.parser.class {parser}
%define api.token.prefix {TOK_}
//%define parse.trace
%define parse.assert
%define parse.error verbose

%code requires
{
// this code is emitted to caparser.hpp

#include "ckbisonflex.hpp"

// adjust YYLLOC_DEFAULT macro for our api.location.type
#define YYLLOC_DEFAULT(res,rhs,N)	(res = (N)?YYRHSLOC(rhs, 1):YYRHSLOC(rhs, 0))

#include "ckgrptokens.hpp"
#include "ckcontext.hpp"
#include "casem.hpp"
}

%code
{
// this code is emitted to caparser.cpp

YY_DECL;

using namespace casem;
}

%param {yyscan_t yyscanner}		// the name yyscanner is enforced by Flex
%param {cecko::context * ctx}

%start translation_unit

%token EOF		0				"end of file"

%token						LBRA		"["
%token						RBRA		"]"
%token						LPAR		"("
%token						RPAR		")"
%token						DOT			"."
%token						ARROW		"->"
%token<cecko::gt_incdec>	INCDEC		"++ or --"
%token						COMMA		","
%token						AMP			"&"
%token						STAR		"*"
%token<cecko::gt_addop>		ADDOP		"+ or -"
%token						EMPH		"!"
%token<cecko::gt_divop>		DIVOP		"/ or %"
%token<cecko::gt_cmpo>		CMPO		"<, >, <=, or >="
%token<cecko::gt_cmpe>		CMPE		"== or !="
%token						DAMP		"&&"
%token						DVERT		"||"
%token						ASGN		"="
%token<cecko::gt_cass>		CASS		"*=, /=, %=, +=, or -="
%token						SEMIC		";"
%token						LCUR		"{"
%token						RCUR		"}"
%token						COLON		":"

%token						TYPEDEF		"typedef"
%token						VOID		"void"
%token<cecko::gt_etype>		ETYPE		"_Bool, char, or int"
%token						STRUCT		"struct"
%token						ENUM		"enum"
%token						CONST		"const"
%token						IF			"if"
%token					  ELSE		"else"
%token						DO			"do"
%token						WHILE		"while"
%token						FOR			"for"
%token						GOTO		"goto"
%token						CONTINUE	"continue"
%token						BREAK		"break"
%token						RETURN		"return"
%token						SIZEOF		"sizeof"

%token<CIName>				IDF			"identifier"
%token<CIName>				TYPEIDF		"type identifier"
%token<int>					INTLIT		"integer literal"
%token<CIName>				STRLIT		"string literal"

%type<cecko::CKTypeObs> type_specifier enum_specifier struct_or_union_specifier

%type<casem::DeclarationSpecifier> type_specifier_qualifier declaration_specifier

%type<casem::DeclarationSpecifierList> declaration_specifiers specifier_qualifier_list

%type<casem::Declarator> declarator direct_declarator function_declarator array_declarator function_abstract_declarator array_abstract_declarator direct_abstract_declarator abstract_declarator init_declarator member_declarator

%type<casem::DeclaratorList> init_declarator_list_opt init_declarator_list member_declarator_list

%type<casem::PointerList> pointer

%type<casem::ParameterList> parameter_list

%type<casem::Parameter> parameter_declaration

%type<casem::Enum> enumerator

%type<casem::EnumList> enumerator_list

%type<casem::Struct> struct_definition_head

%type<cecko::CKStructItemArray> member_declaration_list member_body member_declaration

%type<casem::Expression> expression primary_expression assignment_expression unary_expression logical_OR_expression logical_AND_expression equality_expression postfix_expression relational_expression additive_expression multiplicative_expression cast_expression expression_opt

%type<casem::ExpressionList> argument_expression_list argument_expression_list_opt

%type<cecko::CKIRConstantIntObs> constant_expression

/////////////////////////////////

%%

/////////////////////////////////

/* Expressions */

primary_expression: IDF { $$ = casem::Expression::from_idf(ctx, $1, @1); }
                  | INTLIT { $$ = casem::Expression::from_intlit(ctx, $1); }
                  | STRLIT { $$ = casem::Expression::from_strlit(ctx, $1); }
                  | LPAR expression RPAR { $$ = $2; }
                  ;

postfix_expression: primary_expression
                  | postfix_expression LBRA expression RBRA
                  | postfix_expression LPAR argument_expression_list_opt RPAR { $$ = casem::call_function(ctx, $1, $3); }
                  | postfix_expression DOT IDF
                  | postfix_expression ARROW IDF
                  | postfix_expression INCDEC { $$ = casem::evaluate_unary_expression(ctx, $1, casem::get_incdec_operation($2)); }
                  ;

argument_expression_list: assignment_expression {
                            auto list = casem::ExpressionList();
                            list.push_back($1);
                            $$ = list;
                        }
                        | argument_expression_list COMMA assignment_expression {
                            $1.push_back($3);
                            $$ = $1;
                        }
                        ;

argument_expression_list_opt: argument_expression_list
                            | %empty { $$ = casem::ExpressionList(); }
                            ;

unary_expression: postfix_expression
                | INCDEC unary_expression { $$ = casem::evaluate_unary_expression(ctx, $2, casem::get_incdec_operation($1)); }
                | AMP cast_expression { $$ = casem::evaluate_unary_expression(ctx, $2, casem::Operation::REF); }
                | STAR cast_expression { $$ = casem::evaluate_unary_expression(ctx, $2, casem::Operation::DEREF); }
                | ADDOP cast_expression { $$ = casem::evaluate_unary_expression(ctx, $2, casem::get_addop_operation($1)); }
                | EMPH cast_expression {}
                | SIZEOF LPAR type_name RPAR {}
                ;

type_name: specifier_qualifier_list abstract_declarator_opt
         ;

cast_expression: unary_expression
               ;

assignment_expression: logical_OR_expression
                     | unary_expression ASGN assignment_expression { casem::assign(ctx, $1, $3, casem::Operator::ASGN); }
                     | unary_expression CASS assignment_expression { casem::assign(ctx, $1, $3, casem::get_cass_operator($2)); }
                     ;

logical_OR_expression: logical_AND_expression
                     | logical_OR_expression DVERT logical_AND_expression
                     ;

logical_AND_expression: equality_expression
                      | logical_AND_expression DAMP equality_expression
                      ;

equality_expression: relational_expression
                   | equality_expression CMPE relational_expression
                   ;

additive_expression: multiplicative_expression
                   | additive_expression ADDOP multiplicative_expression { $$ = casem::evaluate_binary_expression(ctx, $1, $3, casem::get_addop_operator($2)); }
                   ;

relational_expression: additive_expression
                     | relational_expression CMPO additive_expression
                     ;

multiplicative_expression: cast_expression
                         | multiplicative_expression STAR cast_expression { $$ = casem::evaluate_binary_expression(ctx, $1, $3, casem::Operator::MUL); }
                         | multiplicative_expression DIVOP cast_expression { $$ = casem::evaluate_binary_expression(ctx, $1, $3, casem::get_divop_operator($2)); }
                         ;

expression: assignment_expression
          ;

expression_opt: expression
              | %empty { $$ = casem::Expression(); }
              ;

constant_expression: logical_OR_expression { $$ = cecko::CKTryGetConstantInt($1.value); }
                   ;


/* Declarations */

declaration: declaration_body SEMIC
           ;

declaration_body: declaration_specifiers init_declarator_list_opt { casem::create_declarations(ctx, $1, $2); }
                ;

declaration_specifiers: declaration_specifier {
                            auto list = casem::DeclarationSpecifierList();
                            list.push_back($1);
                            $$ = list;
                      }
                      | declaration_specifier declaration_specifiers {
                            $2.push_back($1);
                            $$ = $2;
                      }
                      ;

declaration_specifier: TYPEDEF { $$ = casem::DeclarationSpecifier(false, true); }
                     | type_specifier_qualifier
                     ;

init_declarator_list_opt: init_declarator_list
                        | %empty { $$ = casem::DeclaratorList(); }
                        ;

init_declarator_list: init_declarator {
                            auto list = casem::DeclaratorList();
                            list.push_back($1);
                            $$ = list;
                    }
                    | init_declarator_list COMMA init_declarator {
                            $1.push_back($3);
                            $$ = $1;
                    }
                    ;

init_declarator: declarator
               ;

type_specifier_qualifier: type_specifier { $$ = casem::DeclarationSpecifier($1); }
                        | CONST { $$ = casem::DeclarationSpecifier(true, false); }
                        ;

type_specifier: VOID { $$ = ctx->get_void_type(); }
              | ETYPE { $$ = casem::get_etype(ctx, $1); }
              | struct_or_union_specifier
              | enum_specifier
              | TYPEIDF { $$ = ctx->find_typedef($1)->get_type_pack().type; }
              ;

declarator: pointer direct_declarator {
                $2.register_wrapper($1);
                $$ = $2;
          }
          | direct_declarator
          ;

pointer: STAR {
            auto list = casem::PointerList();
            list.insert(list.begin(), casem::Pointer(false));
            $$ = list;
       }
       | STAR type_qualifier_list {
            auto list = casem::PointerList();
            list.insert(list.begin(), casem::Pointer(true));
            $$ = list;
       }
       | STAR pointer {
            $2.insert($2.begin(), casem::Pointer(false));
            $$ = $2;
       }
       | STAR type_qualifier_list pointer {
            $3.insert($3.begin(), casem::Pointer(true));
            $$ = $3;
       }
       ;

direct_declarator: IDF { $$ = casem::Declarator($1, @1); }
                 | LPAR declarator RPAR { $$ = $2; }
                 | array_declarator
                 | function_declarator
                 ;

array_declarator: direct_declarator LBRA assignment_expression RBRA {
                        $1.register_wrapper(casem::Array(cecko::CKTryGetConstantInt($3.value)));
                        $$ = $1;
                }
                ;

function_declarator: direct_declarator LPAR parameter_list RPAR {
                        $1.register_wrapper(casem::Function($3));
                        $$ = $1;
                   }
                   ;

type_qualifier_list: CONST
                   | type_qualifier_list CONST
                   ;

/* Structs */
struct_definition_head: struct_or_union IDF { $$ = casem::Struct($2, ctx->define_struct_type_open($2, @2)); }
                      ;

struct_or_union_specifier: struct_definition_head LCUR member_declaration_list { ctx->define_struct_type_close($1.type, $3); } RCUR { $$ = $1.type; }
                         | struct_or_union IDF {
                                auto s = casem::Struct($2, ctx->declare_struct_type($2, @2));
                                $$ = s.type;
                         }
                         ;

struct_or_union: STRUCT
               ;

member_declaration_list: member_declaration {
                            auto list = cecko::CKStructItemArray();
                            list.insert(list.end(), $1.begin(), $1.end());
                            $$ = list;
                       }
                       | member_declaration_list member_declaration {
                            $1.insert($1.end(), $2.begin(), $2.end());
                            $$ = $1;
                       }
                       ;

member_declaration: member_body SEMIC
                  ;

member_body: specifier_qualifier_list {}
           | specifier_qualifier_list member_declarator_list { $$ = casem::process_member(ctx, $1, $2); }
           ;

member_declarator_list: member_declarator {
                            auto list = casem::DeclaratorList();
                            list.push_back($1);
                            $$ = list;
                      }
                      | member_declarator COMMA member_declarator_list {
                            $3.push_back($1);
                            $$ = $3;
                      }
                      ;

specifier_qualifier_list: type_specifier_qualifier {
                                auto list = DeclarationSpecifierList();
                                list.push_back($1);
                                $$ = list;
                        }
                        | type_specifier_qualifier specifier_qualifier_list {
                                $2.push_back($1);
                                $$ = $2;
                        }
                        ;

member_declarator: declarator
                 ;

/* Enums */

enum_specifier: ENUM IDF LCUR enumerator_list RCUR { $$ = casem::create_enum(ctx, $2, @2, $4); }
              | ENUM IDF LCUR enumerator_list COMMA RCUR { $$ = casem::create_enum(ctx, $2, @2, $4); }
              | ENUM IDF { $$ = ctx->declare_enum_type($2, @2); }
              ;

enumerator_list: enumerator {
                    auto list = casem::EnumList();
                    list.push_back($1);
                    $$ = list;
               }
               | enumerator_list COMMA enumerator {
                    $1.push_back($3);
                    $$ = $1;
               }
               ;

enumerator: IDF { $$ = casem::Enum($1, @1); }
          | IDF ASGN constant_expression { $$ = casem::Enum($1, @1, $3); }
          ;

/* Functions */

parameter_list: parameter_declaration {
                    auto list = casem::ParameterList();
                    list.push_back($1);
                    $$ = list;
              }
              | parameter_list COMMA parameter_declaration {
                    $1.push_back($3);
                    $$ = $1;
              }
              ;

parameter_declaration: declaration_specifiers { $$ = casem::Parameter($1); }
                     | declaration_specifiers declarator {
                            auto list = casem::DeclaratorList();
                            list.push_back($2);
                            $$ = casem::Parameter($1, list);
                     }
                     | declaration_specifiers abstract_declarator {
                            auto list = casem::DeclaratorList();
                            list.push_back($2);
                            $$ = casem::Parameter($1, list);
                     }
                     ;


abstract_declarator: pointer {
                        auto declarator = casem::Declarator();
                        declarator.register_wrapper($1);
                        $$ = declarator;
                   }
                   | direct_abstract_declarator
                   | pointer direct_abstract_declarator {
                        $2.register_wrapper($1);
                        $$ = $2;
                   }
                   ;

abstract_declarator_opt: abstract_declarator
                       | %empty
                       ;

direct_abstract_declarator: LPAR abstract_declarator RPAR { $$ = casem::Declarator($2); }
                          | array_abstract_declarator
                          | function_abstract_declarator
                          ;

array_abstract_declarator: LBRA assignment_expression RBRA {
                                auto declarator = casem::Declarator();
                                declarator.register_wrapper(casem::Array(cecko::CKTryGetConstantInt($2.value)));
                                $$ = declarator;
                         }
                         | direct_abstract_declarator LBRA assignment_expression RBRA {
                                $1.register_wrapper(casem::Array(cecko::CKTryGetConstantInt($3.value)));
                                $$ = $1;
                         }
                         ;

function_abstract_declarator: direct_abstract_declarator LPAR parameter_list RPAR {
                                $1.register_wrapper(casem::Function($3));
                                $$ = $1;
                            }
                            | LPAR parameter_list RPAR {
                                auto declarator = casem::Declarator();
                                declarator.register_wrapper(casem::Function($2));
                                $$ = declarator;
                            }
                            ;

/* Statements */

statementa: expression_statement
          | inner_compound_statement
          | selection_statement_a
          | iteration_statement_a
          | jump_statement
          ;

statementb: selection_statement_b
          | iteration_statement_b
          ;

statement: statementa
         | statementb
         ;

compound_statement: LCUR block_item_list_opt {
                        if (ctx->builder()->GetInsertBlock()) {
                            ctx->builder()->CreateRetVoid();
                        }

                        ctx->exit_function();
                  } RCUR
                  ;

inner_compound_statement: { ctx->enter_block(); } LCUR block_item_list_opt { ctx->exit_block(); } RCUR
                        ;

block_item_list: block_item
               | block_item_list block_item
               ;

block_item_list_opt: block_item_list
                   | %empty
                   ;

block_item: declaration
          | statement
          ;

expression_statement: expression_opt SEMIC
                    ;

selection_statement_a: IF LPAR expression RPAR statementa ELSE statementa
                     ;

selection_statement_b: IF LPAR expression RPAR statement
                     | IF LPAR expression RPAR statementa ELSE statementb
                     ;

iteration_statement_a: WHILE LPAR expression RPAR statementa
                     | DO statementa WHILE LPAR expression RPAR SEMIC
                     | FOR LPAR expression_opt SEMIC expression_opt SEMIC expression_opt RPAR statementa
                     ;

iteration_statement_b: WHILE LPAR expression RPAR statementb
                     | DO statementb WHILE LPAR expression RPAR SEMIC
                     | FOR LPAR expression_opt SEMIC expression_opt SEMIC expression_opt RPAR statementb
                     ;

jump_statement: RETURN SEMIC {
                    ctx->builder()->CreateRetVoid();
              }
              | RETURN expression SEMIC { casem::return_from_function(ctx, $2); }
              ;

translation_unit: external_declaration
                | translation_unit external_declaration
                ;

external_declaration: function_definition
                    | declaration
                    ;

function_head: declaration_specifiers declarator { casem::create_function_declaration(ctx, $1, $2); }
             ;

function_definition: function_head compound_statement
                   ;

/////////////////////////////////

%%

namespace cecko {

	void parser::error(const location_type& l, const std::string& m)
	{
		ctx->message(cecko::errors::SYNTAX, l, m);
	}

}

