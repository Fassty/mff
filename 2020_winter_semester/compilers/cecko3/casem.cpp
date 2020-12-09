#include "casem.hpp"
#include <vector>
#include <string>
#include <iostream>

namespace casem {

    cecko::CKTypeObs get_etype(cecko::gt_etype enum_t, cecko::context_obs ctx) {
        switch (enum_t) {
            case cecko::gt_etype::BOOL: return ctx->get_bool_type();
            case cecko::gt_etype::CHAR: return ctx->get_char_type();
            case cecko::gt_etype::INT: return ctx->get_int_type();
        }
        return NULL;
    }

    cecko::CKTypeObs get_abstract_function_param(cecko::context_obs ctx, cecko::CKTypeObs ret_type, Declarator decl) {
        cecko::CKTypeObsArray type_arr;
        for (auto && param : decl.params) {
            d_specs fn_specs = param.first;
            std::vector<Declarator> fn_decls = param.second;

            cecko::CKTypeObs p_type;
            bool p_is_const = false;
            for (auto && spec : fn_specs) {
                if (spec.type != NULL)
                    p_type = spec.type;
                if (spec.is_const)
                    p_is_const = true;
            }

            bool is_function = false;
            for (auto && dec : fn_decls) {
                if (dec.is_function) is_function = true;
                for (auto && ptr : dec.pointers) {
                   auto rp = cecko::CKTypeRefPack(p_type, ptr.is_const);
                   p_type = ctx->get_pointer_type(rp);
                }
            }

            if (is_function) {
                p_type = get_abstract_function_param(ctx, p_type, fn_decls[0]);
                auto rp = cecko::CKTypeRefPack(p_type, false);
                p_type = ctx->get_pointer_type(rp);
            }

            if (!p_type->is_void()) {
                type_arr.push_back(p_type);
            }

        }

        return ctx->get_function_type(ret_type, type_arr, false);
    }

    void create_declarations(cecko::context_obs ctx, std::vector< DeclarationSpecifier> specs, std::vector< Declarator> declars ) {
        cecko::CKTypeRefPack target;
        bool is_const = false;
        bool is_typedef = false;
        cecko::CKTypeObs type;

        for (auto && x : specs) {
            if (x.is_const)
                is_const = true;
            if (x.is_typedef)
                is_typedef = true;
            if (x.type != NULL)
                type = x.type;

            // TODO: fail if multiple types
        }

        target = cecko::CKTypeRefPack(type, is_const);

        cecko::CKTypeRefPack temp_ref_pack;
        cecko::CKTypeObsArray fn_params;
        for (int i = declars.size() - 1; i >= 0; --i) {
            temp_ref_pack = target;

            if (declars[i].is_function) {
                cecko::CKTypeObsArray type_arr;
                for (auto && param : declars[i].params) {
                    d_specs fn_specs = param.first;
                    std::vector<Declarator> fn_decls = param.second;

                    cecko::CKTypeObs p_type;
                    bool p_is_const = false;
                    for (auto && spec : fn_specs) {
                        if (spec.type != NULL)
                            p_type = spec.type;
                        if (spec.is_const)
                            p_is_const = true;
                    }

                    bool is_function = false;
                    for (auto && dec : fn_decls ) {
                        if (dec.is_function) is_function = true;
                        for (auto && ptr : dec.pointers) {
                            auto rp = cecko::CKTypeRefPack(p_type, ptr.is_const);
                            p_type = ctx->get_pointer_type(rp);
                        }
                    }

                    if (is_function) {
                        p_type = get_abstract_function_param(ctx, p_type, fn_decls[0]);
                        auto rp = cecko::CKTypeRefPack(p_type, false);
                        p_type = ctx->get_pointer_type(rp);
                    }

                    if (!p_type->is_void())
                        type_arr.push_back(p_type);

                }

                fn_params = type_arr;
            }

            for (auto && arr : declars[i].arrays) {
                auto at = ctx->get_array_type(temp_ref_pack.type, ctx->get_int32_constant(arr.size));
                temp_ref_pack = cecko::CKTypeRefPack(at, false);
            }

            for (auto && ptr : declars[i].pointers) {
                auto ptr_t = ctx->get_pointer_type(temp_ref_pack);
                temp_ref_pack = cecko::CKTypeRefPack(ptr_t, ptr.is_const);
            }

            if (is_typedef) {
                ctx->define_typedef(declars[i].name, temp_ref_pack, declars[i].line);
            } else {
                if (declars[i].is_function) {
                    auto f_type = ctx->get_function_type(temp_ref_pack.type, fn_params, false);
                    ctx->declare_function(declars[i].name, f_type, declars[i].line);
                } else {
                    ctx->define_var(declars[i].name, temp_ref_pack, declars[i].line);
                }
            }

        }
    }

    FunctionHeader create_function_header(cecko::context_obs ctx, d_specs scs, Declarator decl) {
        bool is_const = false;
        bool is_typedef = false;
        cecko::CKTypeObs ret_type;

        for (auto && x : scs) {
            if (x.is_const)
                is_const = true;
            if (x.is_typedef)
                is_typedef = true;
            if (x.type != NULL)
                ret_type = x.type;
        }

        cecko::CKTypeRefPack trp = cecko::CKTypeRefPack(ret_type, is_const);
        cecko::CKTypeObsArray fn_params;
        cecko::CKFunctionFormalPackArray pack;
        for (auto && param : decl.params) {
            cecko::CKTypeObs p_type;
            cecko::CIName name;
            cecko::loc_t line = 0;
            bool p_is_const = false;

            for (auto && spec : param.first) {
                if (spec.is_const) p_is_const = true;
                if (spec.type != NULL) p_type = spec.type;
            }

            for (auto && dec : param.second) {
                if (dec.name != "") name = dec.name;
                if (dec.line > 0) line = dec.line;

                for (auto && ptr : dec.pointers) {
                    auto rp = cecko::CKTypeRefPack(p_type, ptr.is_const);
                    p_type = ctx->get_pointer_type(rp);
                }
            }

            if (!p_type->is_void()) {
                fn_params.push_back(p_type);
                pack.push_back(cecko::CKFunctionFormalPack(name, p_is_const, line));
            }
        }

        for (auto && ptr : decl.pointers) {
            auto ptr_t = ctx->get_pointer_type(trp);
            trp = cecko::CKTypeRefPack(ptr_t, ptr.is_const || is_const);
        }

        auto f_type = ctx->get_function_type(trp.type, fn_params, false);
        cecko::CKFunctionSafeObs rt = ctx->declare_function(decl.name, f_type, decl.line);

        return FunctionHeader(rt, pack);
    }


    std::vector< std::pair<d_specs, decls>> process_params(std::vector<ParameterDeclaration> params) {
        std::vector< std::pair<d_specs, decls>> target;

        for (auto && x : params) {
            target.push_back(std::make_pair(x.f_specs, x.f_decls));
        }

        return target;
    }

    DeclarationSpecifier create_enum(cecko::context_obs ctx, cecko::CIName name, cecko::loc_t line, std::vector<Enum> enums) {
        auto e_t = ctx->declare_enum_type(name, line);
        auto consts = cecko::CKConstantObsVector();
        int value = 0;

        for (auto && e : enums) {
            if (e.value == -1) {
                e.value = value;
                value++;
            } else {
                value = e.value + 1;
            }

            auto ev = ctx->get_int32_constant(e.value);
            auto ec = ctx->define_constant(e.name, ev, e.line);
            consts.push_back(ec);
        }
        ctx->define_enum_type_close(e_t, consts);
        return DeclarationSpecifier(e_t);
    }

}

