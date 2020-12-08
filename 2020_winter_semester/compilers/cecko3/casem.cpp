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

        cecko::CKTypeRefPack temp_ref_pack;
        for (int i = decls.size() - 1; i >= 0; --i) {
            temp_ref_pack = target;

            if (decls[i].pointer.depth > 0) {
                for (int j = 0; j < decls[i].pointer.depth; ++j) {
                    auto ptr_t = ctx->get_pointer_type(temp_ref_pack);
                    temp_ref_pack = cecko::CKTypeRefPack(ptr_t, decls[i].pointer.is_const || target.is_const);
                }
            }

            if (is_typedef) {

            } else {
                ctx->define_var(decls[i].name, temp_ref_pack, decls[i].line);
            }

        }
   }



}

