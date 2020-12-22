#include "casem.hpp"
#include "ckcontext.hpp"
#include "ckgrptokens.hpp"
#include "ckir.hpp"
#include "cktables.hpp"
#include <bits/c++config.h>
#include <vector>
#include <string>
#include <iostream>

namespace casem {

    cecko::CKTypeObs get_etype(cecko::context_obs ctx, cecko::gt_etype etype) {
        switch (etype) {
            case cecko::gt_etype::BOOL: return ctx->get_bool_type();
            case cecko::gt_etype::CHAR: return ctx->get_char_type();
            case cecko::gt_etype::INT: return ctx->get_int_type();
            default: return ctx->get_void_type();
        }
    }

    cecko::CKTypeRefPack process_specifiers(DeclarationSpecifierList specifiers) {
        cecko::CKTypeObs type;
        bool is_const = false;

        for (auto && specifier : specifiers) {
            if (specifier.is_const)
                is_const = true;
            if (specifier.has_type)
                type = specifier.type;
        }

        return cecko::CKTypeRefPack(type, is_const);
    }

    cecko::CKTypeRefPack wrap_type(cecko::context_obs ctx, cecko::CKTypeRefPack type, DeclaratorWrapperList wrappers) {
        for (auto && wrapper : wrappers) {

            if (wrapper.is_pointer()) {
                for (auto && pointer : wrapper.get_pointers()) {
                    auto pointer_type = ctx->get_pointer_type(type);
                    type = cecko::CKTypeRefPack(pointer_type, pointer.is_const);
                }
            }

            if (wrapper.is_array()) {
                auto array_type = ctx->get_array_type(type.type, wrapper.get_array_size());
                type = cecko::CKTypeRefPack(array_type, false);
            }

            if (wrapper.is_function()) {
                cecko::CKTypeObsArray function_parameters;
                for (auto && parameter : wrapper.get_function_parameters()) {
                    auto parameter_type = process_specifiers(parameter.specifiers);

                    if (parameter.declarators.size() > 0) {
                        for (auto && declarator : parameter.declarators) {
                            parameter_type = wrap_type(ctx, parameter_type, declarator.get_wrappers());
                            function_parameters.push_back(parameter_type.type);
                        }
                    } else if (!parameter_type.type->is_void()) {
                        function_parameters.push_back(parameter_type.type);
                    }
                }

                auto function_type = ctx->get_function_type(type.type, function_parameters);
                type = cecko::CKTypeRefPack(function_type, false);
            }

        }

        return type;
    }

    void process_declarators(cecko::context_obs ctx, DeclaratorList declarators, cecko::CKTypeRefPack specified_type, bool is_typedef) {

        for (auto && declarator : declarators) {
            cecko::CKTypeRefPack declarator_type = specified_type;
            declarator_type = wrap_type(ctx, declarator_type, declarator.get_wrappers());

            if (is_typedef) {
                ctx->define_typedef(declarator.name, declarator_type, declarator.line);
                continue;
            }

            if (declarator_type.type->is_function()) {
                ctx->declare_function(declarator.name, declarator_type.type, declarator.line);
            } else {
                ctx->define_var(declarator.name, declarator_type, declarator.line);
            }
        }
    }

    void create_declarations(cecko::context_obs ctx, DeclarationSpecifierList specifiers, DeclaratorList declarators) {
        cecko::CKTypeRefPack specified_type = process_specifiers(specifiers);

        process_declarators(ctx, declarators, specified_type, specifiers.back().is_typedef);
    }

    void create_function_declaration(cecko::context_obs ctx, DeclarationSpecifierList specifiers, Declarator declarator) {
        cecko::CKTypeRefPack specified_type = process_specifiers(specifiers);

        cecko::CKTypeRefPack declarator_type = wrap_type(ctx, specified_type, declarator.get_wrappers());

        if (!declarator_type.type->is_function())
            return;

        auto function_declaration = ctx->declare_function(declarator.name, declarator_type.type, declarator.line);

        cecko::CKFunctionFormalPackArray formal_parameters;
        for (auto && function_parameter : declarator.get_wrappers().back().get_function_parameters()) {
            if (!function_parameter.specifiers.front().type->is_void())
                formal_parameters.emplace_back(function_parameter.declarators.front().name, function_parameter.specifiers.front().is_const, declarator.line);
        }

        ctx->enter_function(function_declaration, formal_parameters, declarator.line);
    }

    cecko::CKTypeObs create_enum(cecko::context_obs ctx, cecko::CIName name, cecko::loc_t line, EnumList enums) {
        auto enum_type = ctx->declare_enum_type(name, line);
        ctx->define_enum_type_open(name, line);

        auto items = cecko::CKConstantObsVector();
        int current_value = 0;

        for (auto && enumerator : enums) {
            if (enumerator.value == -1) {
                enumerator.value = current_value;
                current_value++;
            } else {
                current_value = enumerator.value + 1;
            }

            auto enumeration_constant = ctx->define_constant(
                    enumerator.name,
                    ctx->get_int32_constant(enumerator.value),
                    enumerator.line
            );

            items.push_back(enumeration_constant);
        }

        ctx->define_enum_type_close(enum_type, items);
        return enum_type;
    }

    cecko::CKStructItemArray process_member(cecko::context_obs ctx, DeclarationSpecifierList specifiers, DeclaratorList declarators) {
            cecko::CKTypeRefPack specified_type = process_specifiers(specifiers);
            auto items = cecko::CKStructItemArray();

            for (auto && declarator : declarators) {
                cecko::CKTypeRefPack declarator_type = wrap_type(ctx, specified_type, declarator.get_wrappers());
                auto struct_item = cecko::CKStructItem(declarator_type, declarator.name, declarator.line);
                items.insert(items.begin(), struct_item);
            }

            return items;
    }

    Expression convert_to_rvalue(cecko::context_obs ctx, Expression expression, cecko::CIName message="") {
        if (expression.mode == ExpressionMode::LVALUE) {
            expression.value = ctx->builder()->CreateLoad(expression.type->get_ir(), expression.value, message);
            expression.mode = ExpressionMode::RVALUE;
        }

        return expression;
    }

    Expression convert_to_type(cecko::context_obs ctx, Expression expression, cecko::CKTypeSafeObs type) {
        cecko::CKIRValueObs new_value;

        if (type->is_int()) {
            new_value = ctx->builder()->CreateZExt(expression.value, type->get_ir(), "zext");
        } else if (type->is_char()) {
            new_value = ctx->builder()->CreateTrunc(expression.value, type->get_ir(), "trunc");
        } else if (type->is_pointer()) {
            if (expression.type->is_array()) {
                expression.mode = ExpressionMode::RVALUE;
            }
            new_value = expression.value;
        }

        expression.value = new_value;
        expression.type = type;
        return expression;
    }

    void return_from_function(cecko::context_obs ctx, Expression expression) {
        auto return_type = ctx->current_function_return_type();
        expression = convert_to_rvalue(ctx, expression, "retval");
        expression = convert_to_type(ctx, expression, return_type);

        ctx->builder()->CreateRet(expression.value);
        ctx->builder()->ClearInsertionPoint();
    }

    Operator get_cass_operator(cecko::gt_cass op) {
        switch (op) {
            case cecko::gt_cass::ADDA: return Operator::ADD;
            case cecko::gt_cass::SUBA: return Operator::SUB;
            case cecko::gt_cass::MULA: return Operator::MUL;
            case cecko::gt_cass::DIVA: return Operator::DIV;
            case cecko::gt_cass::MODA: return Operator::MOD;
            default: return Operator::ADD; // TODO: invalid OP
        }
    }

    Operator get_addop_operator(cecko::gt_addop op) {
        if (op == cecko::gt_addop::ADD) {
            return Operator::ADD;
        } else {
            return Operator::SUB;
        }
    }

    Operator get_divop_operator(cecko::gt_divop op) {
        if (op == cecko::gt_divop::DIV) {
            return Operator::DIV;
        } else {
            return Operator::MOD;
        }
    }

    Operation get_incdec_operation(cecko::gt_incdec op) {
        if (op == cecko::gt_incdec::INC) {
            return Operation::INC;
        } else {
            return Operation::DEC;
        }
    }

    Operation get_addop_operation(cecko::gt_addop op) {
        if (op == cecko::gt_addop::ADD) {
            return Operation::PLUS;
        } else {
            return Operation::MINUS;
        }
    }


    Expression evaluate_binary_expression(cecko::context_obs ctx, Expression lhs, Expression rhs, Operator op) {
        lhs = convert_to_rvalue(ctx, lhs);
        rhs = convert_to_rvalue(ctx, rhs);

        rhs = convert_to_type(ctx, rhs, ctx->get_int_type());
        lhs = convert_to_type(ctx, lhs, ctx->get_int_type());

        cecko::CKIRValueObs result;
        if (op == Operator::ADD) {
            result = ctx->builder()->CreateAdd(lhs.value, rhs.value, "add");
        } else if (op == Operator::SUB) {
            result = ctx->builder()->CreateSub(lhs.value, rhs.value, "sub");
        } else if (op == Operator::MUL) {
            result = ctx->builder()->CreateMul(lhs.value, rhs.value, "mul");
        } else if (op == Operator::DIV) {
            result = ctx->builder()->CreateSDiv(lhs.value, rhs.value, "div");
        } else if (op == Operator::MOD) {
            result = ctx->builder()->CreateSRem(lhs.value, rhs.value, "mod");
        }

        return Expression(ExpressionMode::RVALUE, result, ctx->get_int_type(), true);
    }

    Expression evaluate_unary_expression(cecko::context_obs ctx, Expression expression, Operation op) {

        if (op == Operation::INC) {
            expression = convert_to_rvalue(ctx, expression);
            expression = convert_to_type(ctx, expression, ctx->get_int_type());
            expression = evaluate_binary_expression(ctx, expression, Expression::from_intlit(ctx, 1), Operator::ADD);
        } else if (op == Operation::DEC) {
            expression = convert_to_rvalue(ctx, expression);
            expression = convert_to_type(ctx, expression, ctx->get_int_type());
            expression = evaluate_binary_expression(ctx, expression, Expression::from_intlit(ctx, 1), Operator::SUB);
        } else if (op == Operation::REF) {
            expression.mode = RVALUE;
            expression.type = ctx->get_pointer_type(cecko::CKTypeRefPack(expression.type, expression.is_const));
        } else if (op == Operation::DEREF) {
            auto result = convert_to_rvalue(ctx, expression, "deref");
            auto target = expression.type->get_pointer_points_to();
            result.mode = ExpressionMode::LVALUE;
            result.type = target.type;
            result.is_const = target.is_const;
            expression = result;
        } else if (op == Operation::PLUS) {
            expression = convert_to_rvalue(ctx, expression);
            expression = convert_to_type(ctx, expression, ctx->get_int_type());
        } else if (op == Operation::MINUS) {
            expression = convert_to_rvalue(ctx, expression);
            expression = convert_to_type(ctx, expression, ctx->get_int_type());
            expression.value = ctx->builder()->CreateNeg(expression.value, "usub");
        } else if (op == Operation::NEG) {

        } else if (op == Operation::SIZEOF) {

        }

        return expression;
    }

    void assign(cecko::context_obs ctx, Expression target, Expression source, Operator op) {
        Expression result;

        if (op != Operator::ASGN) {
            // CASS
            result = evaluate_binary_expression(ctx, target, source, op);
            result.mode = target.mode;
        } else {
            result = convert_to_rvalue(ctx, source, "assign");
        }

        result = convert_to_type(ctx, result, target.type);

        if ((target.mode != ExpressionMode::LVALUE) || target.is_const) {
            return;
        }
        ctx->builder()->CreateStore(result.value, target.value);
    }

    Expression call_function(cecko::context_obs ctx, Expression function, ExpressionList parameters) {
        auto return_type = function.type->get_function_return_type();
        auto n_args = function.type->get_function_arg_count();

        cecko::CKIRValueObsArray converted_params;
        if (function.type->is_function_variadic()) {
            auto arg_type = function.type->get_function_arg_type(0);
            for (auto && param : parameters) {
                auto arg_val = convert_to_type(ctx, convert_to_rvalue(ctx, param), arg_type);
                converted_params.push_back(arg_val.value);
            }
        } else {
            for (std::size_t i = 0; i < n_args; i++) {
                auto arg_type = function.type->get_function_arg_type(i);
                auto arg_val = convert_to_type(ctx, convert_to_rvalue(ctx, parameters[i]), arg_type);
                converted_params.push_back(arg_val.value);
            }

        }

        auto return_value = ctx->builder()->CreateCall(function.value, converted_params);
        auto ret_expr = Expression(ExpressionMode::RVALUE, return_value, return_type, true);
        return convert_to_type(ctx, ret_expr, return_type);
    }
}

