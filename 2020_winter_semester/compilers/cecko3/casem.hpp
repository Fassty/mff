#ifndef casem_hpp_
#define casem_hpp_

#include "cktables.hpp"
#include "ckcontext.hpp"
#include "ckgrptokens.hpp"
#include <vector>
#include <string>


namespace casem {


    class DeclarationSpecifier {
        public:
            bool is_const;
            bool is_typedef;
            cecko::CKTypeObs type;

            DeclarationSpecifier() {};

            DeclarationSpecifier(bool is_tdf, bool is_cst):
                is_typedef(is_tdf), is_const(is_cst), type() {}

            DeclarationSpecifier(cecko::CKTypeObs tpc):
                is_typedef(false), is_const(false), type(tpc) {}

    };

    class Declarator {
        public:
            bool is_const;
            bool is_pointer;
            cecko::CIName name;
            cecko::loc_t line;

            Declarator() {};

            Declarator(bool is_cst, bool is_ptr):
                is_const(is_cst), is_pointer(is_ptr), name(), line() {}

            Declarator(cecko::CIName n, cecko::loc_t ln):
                is_const(false), is_pointer(false), name(n), line(ln) {}

    };

    using d_specs = std::vector<DeclarationSpecifier>;
    using decls = std::vector<Declarator>;

    cecko::CKTypeObs get_etype(cecko::gt_etype enum_t, cecko::context_obs ctx);

    void create_declarations(cecko::context_obs ctx, d_specs scs, decls dcs);

}

#endif
