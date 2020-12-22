#ifndef casem_hpp_
#define casem_hpp_

#include "ckir.hpp"
#include "cktables.hpp"
#include "ckcontext.hpp"
#include "ckgrptokens.hpp"
#include <cstdint>
#include <vector>
#include <string>
#include <utility>


namespace casem {

    class DeclarationSpecifier;
    class Pointer;
    class Array;
    class Enum;
    class Function;
    class Struct;
    class Parameter;
    class DeclaratorWrapper;
    class Declarator;
    class Expression;

    using ParameterList = std::vector<Parameter>;
    using DeclarationSpecifierList = std::vector<DeclarationSpecifier>;
    using DeclaratorWrapperList = std::vector<DeclaratorWrapper>;
    using DeclaratorList = std::vector<Declarator>;
    using PointerList = std::vector<Pointer>;
    using EnumList = std::vector<Enum>;
    using ExpressionList = std::vector<Expression>;


    enum WrapperKind {
        FUNCTION,
        ARRAY,
        POINTERS,
    };

    class DeclarationSpecifier {
        public:
            cecko::CKTypeObs type;
            bool is_const;
            bool is_typedef;
            bool has_type;

            DeclarationSpecifier():
                type(cecko::CKTypeObs()), is_const(false), is_typedef(false), has_type(false) {}

            DeclarationSpecifier(bool is_const, bool is_typedef):
                type(cecko::CKTypeObs()), is_const(is_const), is_typedef(is_typedef), has_type(false) {}

            DeclarationSpecifier(cecko::CKTypeObs type):
                type(type), is_const(false), is_typedef(false), has_type(true) {}
    };

    class Pointer {
        public:
            bool is_const;

            Pointer():
                is_const(false) {}

            Pointer(bool is_const):
                is_const(is_const) {}
    };

    class Array {
        public:
            cecko::CKIRConstantIntObs size;

            Array():
                size(0) {}

            Array(cecko::CKIRConstantIntObs size):
                size(size) {}

    };

    class Enum {
        public:
            cecko::CIName name;
            cecko::loc_t line;
            int value;

            Enum():
                value(-1) {}

            Enum(cecko::CIName name, cecko::loc_t line):
                name(name), line(line), value(-1) {}

            Enum(cecko::CIName name, cecko::loc_t line, cecko::CKIRConstantIntObs value):
                name(name), line(line), value(value->getZExtValue()) {}

    };

    class Function {
        public:
            ParameterList parameters;


            Function() {}

            Function(ParameterList parameters):
                parameters(parameters) {}

    };

    class Struct {
        public:
            cecko::CIName name;
            cecko::CKStructTypeObs type;

            Struct() {}

            Struct(cecko::CIName name, cecko::CKStructTypeObs type):
                name(name), type(type) {}

    };

    class DeclaratorWrapper {
        public:
            WrapperKind kind;
            PointerList pointers;
            Array array;
            Function function;

            DeclaratorWrapper() {}

            DeclaratorWrapper(PointerList pointers):
                kind(WrapperKind::POINTERS), pointers(pointers) {}

            DeclaratorWrapper(Array array):
                kind(WrapperKind::ARRAY), array(array) {}

            DeclaratorWrapper(Function function):
                kind(WrapperKind::FUNCTION), function(function) {}

            bool is_pointer() {
                return kind == WrapperKind::POINTERS;
            }

            bool is_array() {
                return kind == WrapperKind::ARRAY;
            }

            bool is_function() {
                return kind == WrapperKind::FUNCTION;
            }

            cecko::CKIRConstantIntObs get_array_size() {
                return array.size;
            }

            ParameterList get_function_parameters() {
                return function.parameters;
            }

            PointerList get_pointers() {
                return pointers;
            }
    };

    class Declarator {
        public:
            cecko::CIName name;
            cecko::loc_t line;
            DeclaratorWrapperList wrappers;

            Declarator() {}

            Declarator(cecko::CIName name, cecko::loc_t line):
                name(name), line(line) {}

            void register_wrapper(DeclaratorWrapper wrapper) {
                wrappers.insert(wrappers.begin(), wrapper);
            }

            DeclaratorWrapperList get_wrappers() {
                return wrappers;
            }
    };

    class Parameter {
        public:
            DeclarationSpecifierList specifiers;
            DeclaratorList declarators;

            Parameter() {}

            Parameter(DeclarationSpecifierList specifiers):
                specifiers(specifiers) {}

            Parameter(DeclarationSpecifierList specifiers, DeclaratorList declarators):
                specifiers(specifiers), declarators(declarators) {}

    };

    // Expressions
    enum ExpressionMode {
        LVALUE,
        RVALUE,
    };

    enum Operator {
        ADD,
        SUB,
        MUL,
        DIV,
        MOD,
        ASGN,
        AND,
        OR,
    };

    enum Operation {
        INC,
        DEC,
        REF,
        DEREF,
        PLUS,
        MINUS,
        NEG,
        SIZEOF,
    };

    class Expression {
        public:
            ExpressionMode mode;
            cecko::CKIRValueObs value;
            cecko::CKTypeSafeObs type;
            bool is_const;

            Expression() {}

            Expression(ExpressionMode mode, cecko::CKIRValueObs value, cecko::CKTypeSafeObs type, bool is_const):
                mode(mode), value(value), type(type), is_const(is_const) {}

            static Expression from_intlit(cecko::context_obs ctx, std::int_fast32_t literal) {
                ExpressionMode mode = ExpressionMode::RVALUE;
                cecko::CKIRValueObs value = ctx->get_int32_constant(literal);
                cecko::CKTypeSafeObs type = ctx->get_int_type();
                return Expression(mode, value, type, true);
            }

            static Expression from_strlit(cecko::context_obs ctx, cecko::CIName literal) {
                ExpressionMode mode = ExpressionMode::RVALUE;
                cecko::CKIRValueObs value = ctx->builder()->CreateGlobalStringPtr(literal);
                auto str = ctx->builder()->CreateGlobalString(literal);
                auto ref_pack = cecko::CKTypeRefPack(ctx->get_char_type(), true);
                cecko::CKTypeSafeObs type = ctx->get_pointer_type(ref_pack);
                return Expression(mode, value, type, true);
            }

            static Expression from_idf(cecko::context_obs ctx, cecko::CIName name, cecko::loc_t line) {
                cecko::CKNamedSafeObs descriptor = ctx->find(name);

                if (!descriptor)
                    ctx->message(cecko::errors::UNDEF_IDF, line, name);

                if (descriptor->is_function()) {
                    auto mode = ExpressionMode::RVALUE;
                    return Expression(mode, descriptor->get_function_ir(), descriptor->get_type(), descriptor->is_const());
                } else {
                    auto mode = ExpressionMode::LVALUE;
                    return Expression(mode, descriptor->get_ir(), descriptor->get_type(), descriptor->is_const());
                }
            }

    };

    cecko::CKTypeObs get_etype(cecko::context_obs ctx, cecko::gt_etype etype);
    void create_declarations(cecko::context_obs ctx, DeclarationSpecifierList specifiers, DeclaratorList declarators);
    void create_function_declaration(cecko::context_obs ctx, DeclarationSpecifierList specifiers, Declarator declarator);
    cecko::CKTypeObs create_enum(cecko::context_obs ctx, cecko::CIName name, cecko::loc_t line, EnumList enums);
    cecko::CKStructItemArray process_member(cecko::context_obs ctx, DeclarationSpecifierList specifiers, DeclaratorList declarators);

    void return_from_function(cecko::context_obs ctx, Expression expression);
    Operator get_cass_operator(cecko::gt_cass op);
    Operator get_addop_operator(cecko::gt_addop op);
    Operator get_divop_operator(cecko::gt_divop op);
    Operation get_incdec_operation(cecko::gt_incdec op);
    Operation get_addop_operation(cecko::gt_addop op);
    void assign(cecko::context_obs ctx, Expression source, Expression target, Operator op);
    Expression evaluate_unary_expression(cecko::context_obs, Expression expr, Operation op);
    Expression evaluate_binary_expression(cecko::context_obs ctx, Expression lhs, Expression rhs, Operator op);
    Expression call_function(cecko::context_obs ctx, Expression function, ExpressionList parameters);

}

#endif
