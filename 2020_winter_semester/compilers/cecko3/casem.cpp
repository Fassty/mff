#include "casem.hpp"
#include "ckcontext.hpp"
#include "cktables.hpp"
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
        cecko::CKTypeRefPack declarator_type = specified_type;

        for (auto && declarator : declarators) {
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

}

