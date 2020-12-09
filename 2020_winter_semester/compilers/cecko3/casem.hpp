#ifndef casem_hpp_
#define casem_hpp_

#include "cktables.hpp"
#include "ckcontext.hpp"
#include "ckgrptokens.hpp"
#include <vector>
#include <string>
#include <utility>


namespace casem {

    class Pointer {
        public:
            bool is_const;

            Pointer():
                is_const(false) {}

            Pointer(bool is_cst):
                is_const(is_cst) {}
    };

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

    using d_specs = std::vector<DeclarationSpecifier>;

    class Declarator {
        public:
            cecko::CIName name;
            cecko::loc_t line;
            std::vector<Pointer> pointers;
            bool is_function;
            std::vector< std::pair<std::vector<DeclarationSpecifier>, std::vector<Declarator>>> params;

            Declarator():
                is_function(false) {}

            Declarator(cecko::CIName n, cecko::loc_t ln):
                name(n), line(ln), pointers(), is_function(false), params() {}

    };

    using decls = std::vector<Declarator>;

    class ParameterDeclaration {
        public:
            d_specs f_specs;
            decls f_decls;

            ParameterDeclaration():
                f_specs(), f_decls() {}

            ParameterDeclaration(d_specs fs, Declarator decl):
                f_specs(fs), f_decls(decls(1, decl)) {}
    };

    class FunctionHeader {
        public:
            cecko::CKFunctionSafeObs ret_type;
            cecko::CKFunctionFormalPackArray pack;

            FunctionHeader() {};

            FunctionHeader(cecko::CKFunctionSafeObs rt, cecko::CKFunctionFormalPackArray pck):
                ret_type(rt), pack(pck) {}
    };

    FunctionHeader create_function_header(cecko::context_obs ctx, d_specs scs, Declarator decl);

    cecko::CKTypeObs get_etype(cecko::gt_etype enum_t, cecko::context_obs ctx);

    void create_declarations(cecko::context_obs ctx, d_specs scs, decls dcs);

    std::vector< std::pair<d_specs, decls>> process_params(std::vector<ParameterDeclaration> params);
}

#endif
