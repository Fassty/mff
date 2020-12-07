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
#include <vector>
#include <string>
#include <iostream>
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

/////////////////////////////////

%type<cecko::CKTypeObs> type_specifier typedef_name
%type<casem::DeclarationSpecifier> declaration_specifier type_specifier_qualifier storage_class_specifier type_qualifier
%type<casem::Declarator> declarator init_declarator direct_declarator array_declarator function_declarator
%type<std::vector<casem::DeclarationSpecifier>> declaration_specifiers
%type<std::vector<casem::Declarator>> init_declarator_list

%%

/////////////////////////////////

primary_expression: IDF
                  | INTLIT
                  | STRLIT
                  | LPAR expression RPAR
                  ;

postfix_expression: primary_expression
                  | postfix_expression LBRA expression RBRA
                  | postfix_expression LPAR argument_expression_list_opt RPAR
                  | postfix_expression DOT IDF
                  | postfix_expression ARROW IDF
                  | postfix_expression INCDEC
                  ;

argument_expression_list: assignment_expression
                        | argument_expression_list COMMA assignment_expression
                        ;

argument_expression_list_opt: argument_expression_list
                            | %empty
                            ;

unary_expression: postfix_expression
                | INCDEC unary_expression
                | unary_operator cast_expression
                | SIZEOF LPAR type_name RPAR
                ;

unary_operator: AMP
              | STAR
              | ADDOP
              | EMPH
              ;

cast_expression: unary_expression
               ;

multiplicative_expression: cast_expression
                         | multiplicative_expression STAR cast_expression
                         | multiplicative_expression DIVOP cast_expression
                         ;

additive_expression: multiplicative_expression
                   | additive_expression ADDOP multiplicative_expression
                   ;

relational_expression: additive_expression
                     | relational_expression CMPO additive_expression
                     ;

equality_expression: relational_expression
                   | equality_expression CMPE relational_expression
                   ;

logical_AND_expression: equality_expression
                      | logical_AND_expression DAMP equality_expression
                      ;

logical_OR_expression: logical_AND_expression
                     | logical_OR_expression DVERT logical_AND_expression
                     ;

assignment_expression: logical_OR_expression
                     | unary_expression assignment_operator assignment_expression
                     ;

assignment_operator: ASGN
                   | CASS
                   ;

expression: assignment_expression
          ;

expression_opt: expression
              | %empty
              ;

constant_expression: logical_OR_expression
                   ;

declaration: no_leading_attribute_declaration
           ;

declaration_body: declaration_specifiers init_declarator_list {
                    casem::create_declarations(ctx, $1, $2);
                }
                | declaration_specifiers
                ;

no_leading_attribute_declaration: declaration_body SEMIC

declaration_specifiers: declaration_specifier {
                        auto decl = std::vector< casem::DeclarationSpecifier>();
                        decl.push_back($1);
                        $$ = decl;

                      }
                      | declaration_specifier declaration_specifiers {
                        $2.push_back($1);
                        $$ = $2;
                      }
                      ;

declaration_specifier: storage_class_specifier { $$ = $1; }
                     | type_specifier_qualifier { $$ = $1; }
                     ;

init_declarator_list: init_declarator {
                        auto decl = std::vector< casem::Declarator>();
                        decl.push_back($1);
                        $$ = decl;
                    }
                    | init_declarator_list COMMA init_declarator {
                        $1.push_back($3);
                        $$ = $1;
                    }
                    ;

init_declarator: declarator { $$ = $1; }
               ;

storage_class_specifier: TYPEDEF { $$ = casem::DeclarationSpecifier(true, false); }
                       ;

type_specifier: VOID { $$ = ctx->get_void_type(); }
              | ETYPE { $$ = casem::get_etype($1, ctx); }
              | struct_or_union_specifier { $$ = ctx->get_void_type(); }
              | enum_specifier { $$ = ctx->get_void_type(); }
              | typedef_name { $$ = $1; }
              ;

struct_or_union_specifier: struct_or_union IDF LCUR member_declaration_list RCUR
                         | struct_or_union IDF
                         ;

struct_or_union: STRUCT
               ;

member_declaration_list: member_declaration
                       | member_declaration_list member_declaration
                       ;

member_declaration: member_body SEMIC
                  ;

member_body: specifier_qualifier_list
           | specifier_qualifier_list_with_member_declarators
           ;

specifier_qualifier_list_with_member_declarators: specifier_qualifier_list member_declarator
                                               | specifier_qualifier_list_with_member_declarators COMMA member_declarator
                                               ;

specifier_qualifier_list: type_specifier_qualifier
                        | type_specifier_qualifier specifier_qualifier_list
                        ;

type_specifier_qualifier: type_specifier { $$ = casem::DeclarationSpecifier($1); }
                        | type_qualifier { $$ = $1; }
                        ;

member_declarator: declarator
                 ;

enum_specifier: ENUM IDF LCUR enumerator_list RCUR
              | ENUM IDF LCUR enumerator_list COMMA RCUR
              | ENUM IDF
              ;

enumerator_list: enumerator
               | enumerator_list COMMA enumerator
               ;

enumeration_constant: IDF
                    ;

enumerator: enumeration_constant
          | enumeration_constant ASGN constant_expression
          ;

type_qualifier: CONST { $$ = casem::DeclarationSpecifier(false, true); }
              ;


declarator: pointer direct_declarator {
            $2.is_pointer = true;
            $$ = $2;
          }
          | direct_declarator { $$ = $1; }
          ;

direct_declarator: IDF { $$ = casem::Declarator($1, @1); }
                 | LPAR declarator RPAR { $$ = $2; }
                 | array_declarator { $$ = casem::Declarator(true, true); }
                 | function_declarator { $$ = casem::Declarator(true, true); }
                 ;

array_declarator: direct_declarator LBRA assignment_expression RBRA
                ;

function_declarator: direct_declarator LPAR parameter_type_list RPAR
                   ;

pointer: STAR type_qualifier_list_opt
       | STAR type_qualifier_list_opt pointer
       ;


type_qualifier_list: type_qualifier
                   | type_qualifier_list type_qualifier
                   ;

type_qualifier_list_opt: type_qualifier_list
                       | %empty
                       ;

parameter_type_list: parameter_list
                   ;

parameter_type_list_opt: parameter_type_list
                       | %empty
                       ;

parameter_list: parameter_declaration
              | parameter_list COMMA parameter_declaration
              ;

parameter_declaration: declaration_specifiers declarator
                     | declaration_specifiers abstract_declarator_opt
                     ;

type_name: specifier_qualifier_list abstract_declarator_opt
         ;

abstract_declarator: pointer
                   | pointer direct_abstract_declarator
                   | direct_abstract_declarator
                   ;

abstract_declarator_opt: abstract_declarator
                       | %empty
                       ;

direct_abstract_declarator: LPAR abstract_declarator RPAR
                          | array_abstract_declarator
                          | function_abstract_declarator
                          ;

direct_abstract_declarator_opt: direct_abstract_declarator
                              | %empty
                              ;

array_abstract_declarator: direct_abstract_declarator_opt LBRA assignment_expression RBRA
                         ;

function_abstract_declarator: direct_abstract_declarator LPAR parameter_type_list_opt RPAR
                            | LPAR parameter_type_list_opt RPAR
                            ;

typedef_name: TYPEIDF { $$ = ctx->find_typedef($1)->get_type_pack().type; }
            ;

statementa: expression_statement
          | compound_statement
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

compound_statement: LCUR block_item_list_opt RCUR
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

jump_statement: RETURN expression_opt SEMIC
              ;

translation_unit: external_declaration
                | translation_unit external_declaration
                ;

external_declaration: function_definition
                    | declaration
                    ;

function_definition: declaration_specifiers declarator compound_statement
                   ;

/////////////////////////////////

%%

namespace cecko {

	void parser::error(const location_type& l, const std::string& m)
	{
		ctx->message(cecko::errors::SYNTAX, l, m);
	}

}
