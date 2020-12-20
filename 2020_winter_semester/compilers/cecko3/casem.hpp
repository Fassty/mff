#ifndef casem_hpp_
#define casem_hpp_

#include "ckir.hpp"
#include "cktables.hpp"
#include "ckcontext.hpp"
#include "ckgrptokens.hpp"
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

    using ParameterList = std::vector<Parameter>;
    using DeclarationSpecifierList = std::vector<DeclarationSpecifier>;
    using DeclaratorWrapperList = std::vector<DeclaratorWrapper>;
    using DeclaratorList = std::vector<Declarator>;
    using PointerList = std::vector<Pointer>;
    using EnumList = std::vector<Enum>;


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

            Enum(cecko::CIName name, cecko::loc_t line, int value):
                name(name), line(line), value(value) {}

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

    // Functions
    cecko::CKTypeObs get_etype(cecko::context_obs ctx, cecko::gt_etype etype);
    void create_declarations(cecko::context_obs ctx, DeclarationSpecifierList specifiers, DeclaratorList declarators);
    void create_function_declaration(cecko::context_obs ctx, DeclarationSpecifierList specifiers, Declarator declarator);
    cecko::CKTypeObs create_enum(cecko::context_obs ctx, cecko::CIName name, cecko::loc_t line, EnumList enums);
    cecko::CKStructItemArray process_member(cecko::context_obs ctx, DeclarationSpecifierList specifiers, DeclaratorList declarators);

}

#endif
