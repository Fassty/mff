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

    void create_declarations(cecko::context_obs ctx, std::vector< DeclarationSpecifier> specs, std::vector< Declarator> decls ) {
        cecko::CKTypeRefPack target;
        bool is_const;
        bool is_typedef;
        cecko::CKTypeObs type;

        for (auto && x : specs) {
            if (x.is_const)
                is_const = true;
            if (x.is_typedef)
                is_typedef = true;
            if (x.type != NULL)
                type = x.type;
        }

        target = cecko::CKTypeRefPack(type, is_const);

        is_const = false;
        cecko::CIName name;
        cecko::loc_t line;
        cecko::CKTypeRefPack temp_ref_pack = target;
        for (int i = decls.size() - 1; i >= 0; --i) {
            if (decls[i].is_const)
                is_const = true;
            if (decls[i].is_pointer) {
                auto ptr_t = ctx->get_pointer_type(temp_ref_pack);
                temp_ref_pack = cecko::CKTypeRefPack(ptr_t, is_const || target.is_const);
            }

            if (name == "") {
                name = decls[i].name;
                line = decls[i].line;
                continue;
            }

            if (is_typedef) {

            } else {
                ctx->define_var(name, temp_ref_pack, line);
            }

            name = decls[i].name;
            line = decls[i].line;

            is_const = false;
            temp_ref_pack = target;
        }

        if (is_typedef) {
            // TODO: panic
        } else {
            ctx->define_var(name, temp_ref_pack, line);
        }
   }



}

