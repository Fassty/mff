%{

// allow access to YY_DECL macro
#include "ckbisonflex.hpp"
#include <string>
#include <tuple>
#include <cctype>

#include INCLUDE_WRAP(BISON_HEADER)

  std::string get_leading_number(const std::string s) {
    int first_non_digit_index = -1;
    for (int i = 0; i < s.length(); i++) {
      if (!isdigit(s[i])) {
        first_non_digit_index = i;
        break;
      }
    }

    return first_non_digit_index == -1 ? s : s.substr(0, first_non_digit_index);
  }

  std::string get_leading_hex(const std::string s) {
    int first_non_digit_index = -1;
    for (int i = 0; i < s.length(); i++) {
      if (!isxdigit(s[i])) {
        first_non_digit_index = i;
        break;
      }
    }

    return first_non_digit_index == -1 ? s : s.substr(0, first_non_digit_index);
  }


  int char_to_digit(const char c) {
    if (c >= '0' && c <= '9') {
      return (int)(c - '0');
    } else if (c >= 'a' && c <= 'f') {
      return (int)(c - 'a') + 10;
    } else if (c >= 'A' && c <= 'F') {
      return (int)(c - 'A') + 10;
    } else {
      return (int)c;
    }
  }

  std::tuple<int, bool> str_to_int(const std::string s) {
    int result = 0;
    bool stripped = false;
    for (auto c : s) {
      int new_result = 10 * result + char_to_digit(c);
      if (new_result < result) {
        stripped = true;
      }
      result = new_result;
    }
    return std::make_tuple(result, stripped);
  }

  std::tuple<int, bool> str_to_hex(const std::string s) {
    int result = 0;
    bool stripped = false;
    for (auto c : s) {
      int new_result = 16 * result + char_to_digit(c);
      if (new_result < result) {
        stripped = true;
      }
      result = new_result;
    }
    return std::make_tuple(result, stripped);
  }

  int char_to_int(const std::string s) {
    int result = 0;
    for (auto c : s){
      result = (result << 8) | c;
    }
    return result;
  }

  int char_to_hex(const std::string s) {
    int result = 0;
    for (auto c : s) {
      result = (result << 4) | char_to_digit(c);
    }
    result = result & 0xff;
    return result;
  }

  void replaceAll(std::string& str, const std::string& from, const std::string& to) {
    if(from.empty())
      return;
    size_t start_pos = 0;
    while((start_pos = str.find(from, start_pos)) != std::string::npos) {
      str.replace(start_pos, from.length(), to);
      start_pos += to.length();
    }
  }

%}

/* NEVER SET %option outfile INTERNALLY - SHALL BE SET BY CMAKE */

%option noyywrap nounput noinput
%option batch never-interactive reentrant
%option nounistd

/* AVOID backup perf-report - DO NOT CREATE UNMANAGEABLE BYPRODUCT FILES */

%x STRING SCOMMENT MCOMMENT CHARCONST HEXESCAPE

DIGIT[0-9]+
HEXDIGIT[0-9a-fA-F]+
WS[ \r\t\f\v]

IDENT([_a-zA-Z][_a-zA-Z0-9]*)

%%

%{
      int valbuffer = 0;
      std::string buffer;
      int nesting_level = 0;
%}

"//"      {
                BEGIN(SCOMMENT);
          }

\"        {
                BEGIN(STRING);
          }

''        {
                ctx->message(cecko::errors::EMPTYCHAR, ctx->line());
                return cecko::parser::make_INTLIT(0, ctx->line());
          }

'         {
                BEGIN(CHARCONST);
          }

<SCOMMENT>{

      \n      {
                    ctx->incline();
                    BEGIN(INITIAL);
              }

      .      /* ignore */


      <<EOF>>     {
                        ctx->message(cecko::errors::EOFINCMT, ctx->line());
                        return cecko::parser::make_EOF(ctx->line());
                  }
}

<INITIAL,MCOMMENT>{

      "/*"      {
                      if (nesting_level == 0) {
                          BEGIN(MCOMMENT);
                      }
                      nesting_level++;
                }

      "*/"      {
                      if (nesting_level == 0) {
                          ctx->message(cecko::errors::UNEXPENDCMT, ctx->line());
                      } else if (nesting_level == 1) {
                          BEGIN(INITIAL);
                          nesting_level--;
                      } else {
                          nesting_level--;
                      }
                }
}

<MCOMMENT>{

      \n      ctx->incline();

      .       /* ignore */

      <<EOF>>     {
                          ctx->message(cecko::errors::EOFINCMT, ctx->line());
                          return cecko::parser::make_EOF(ctx->line());
                  }
}

<STRING>{

      \\'       buffer += "\x27";

      \\\"      buffer += "\x22";

      \\n       buffer += "\x0a";

      \\\?      buffer += "\x3f";

      \\\\      buffer += "\x5c";

      \\a       buffer += "\x07";

      \\b       buffer += "\x08";

      \\f       buffer += "\x0c";

      \\r       buffer += "\x0d";

      \\t       buffer += "\x09";

      \\v       buffer += "\x0b";

      \\x{HEXDIGIT}       {
                              std::string tempstr(yytext);

                              if (tempstr.length() > 2) {
                                tempstr = tempstr.substr(2, tempstr.length());
                                if (tempstr.length() == 1) {
                                  buffer += "\\x" + tempstr;
                                } else if (tempstr.length() == 2) {
                                  buffer += "\\x" + tempstr;
                                } else {
                                  auto trimmed = tempstr.substr(tempstr.length() - 2, tempstr.length());
                                  ctx->message(cecko::errors::BADESCAPE, ctx->line(), tempstr);
                                  buffer += "\\x" + trimmed;
                                }
                              } else {
                                ctx->message(cecko::errors::BADESCAPE, ctx->line(), yytext);
                              }

                            }

      \\[^\n\"]? {
                      ctx->message(cecko::errors::BADESCAPE, ctx->line(), yytext);
                      std::string tempstr(yytext);
                      buffer += tempstr.substr(1, tempstr.length());
                 }

      [^\n\"]     buffer += yytext;


      \n          {
                          BEGIN(INITIAL);
                          ctx->message(cecko::errors::EOLINSTRCHR, ctx->line());
                          ctx->incline();
                          std::string to_return = buffer;
                          return cecko::parser::make_STRLIT(to_return, ctx->line());

                  }

      \"          {
                          BEGIN(INITIAL);
                          std::string to_return = buffer;
                          return cecko::parser::make_STRLIT(to_return, ctx->line());
                  }

      <<EOF>>     {
                          BEGIN(INITIAL);
                          ctx->message(cecko::errors::EOFINSTRCHR, ctx->line());
                          return cecko::parser::make_STRLIT(buffer, ctx->line());
                  }
}

<CHARCONST>{

    '             {
                          BEGIN(INITIAL);
                          int num = 0;
                          if (buffer.length() > 0) {
                            num = (valbuffer << 8 ) | char_to_int(buffer);
                          } else {
                            num = valbuffer;
                          }

                          return cecko::parser::make_INTLIT(num, ctx->line());
                  }

    \\x{HEXDIGIT}?          {
                                  std::string tempstr(yytext);

                                  if (tempstr.length() > 2) {
                                    tempstr = tempstr.substr(2, tempstr.length());
                                    if (tempstr.length() <= 2) {
                                      valbuffer = char_to_hex(tempstr);
                                    } else {
                                      ctx->message(cecko::errors::BADESCAPE, ctx->line(), tempstr);
                                      valbuffer = char_to_hex(tempstr);
                                    }
                                  } else {
                                      ctx->message(cecko::errors::BADESCAPE, ctx->line(), yytext);
                                  }
                            }

    \\[^\n']?      {
                          std::string tempstr(yytext);

                          if (tempstr.length() > 1) {
                            ctx->message(cecko::errors::BADESCAPE, ctx->line(), yytext);
                            valbuffer = char_to_hex(tempstr.substr(1, tempstr.length()));
                          } else {
                            ctx->message(cecko::errors::BADESCAPE, ctx->line(), yytext);
                          }
                   }


    \n            {
                          BEGIN(INITIAL);
                          ctx->message(cecko::errors::EOLINSTRCHR, ctx->line());
                          ctx->incline();

                          int num = 0;
                          if (buffer.length() > 0) {
                            num = (valbuffer << 8 ) | char_to_int(buffer);
                          } else {
                            num = valbuffer;
                          }

                          return cecko::parser::make_INTLIT(num, ctx->line());
                  }

    .             {
                          buffer += yytext;
                  }

    <<EOF>>       {
                          BEGIN(INITIAL);
                          ctx->message(cecko::errors::EOFINSTRCHR, ctx->line());
                          int num = 0;
                          if (buffer.length() > 0) {
                            num = (valbuffer << 8 ) | char_to_int(buffer);
                          } else {
                            num = valbuffer;
                          }
                          return cecko::parser::make_INTLIT(num, ctx->line());
                  }

}


break     return cecko::parser::make_BREAK(ctx->line());

const     return cecko::parser::make_CONST(ctx->line());

continue      return cecko::parser::make_CONTINUE(ctx->line());

do      return cecko::parser::make_DO(ctx->line());

else      return cecko::parser::make_ELSE(ctx->line());

enum      return cecko::parser::make_ENUM(ctx->line());

for     return cecko::parser::make_FOR(ctx->line());

goto      return cecko::parser::make_GOTO(ctx->line());

if      return cecko::parser::make_IF(ctx->line());

char      return cecko::parser::make_ETYPE(cecko::gt_etype::CHAR, ctx->line());

int     return cecko::parser::make_ETYPE(cecko::gt_etype::INT, ctx->line());

return      return cecko::parser::make_RETURN(ctx->line());

sizeof      return cecko::parser::make_SIZEOF(ctx->line());

struct      return cecko::parser::make_STRUCT(ctx->line());

typedef     return cecko::parser::make_TYPEDEF(ctx->line());

void      return cecko::parser::make_VOID(ctx->line());

while     return cecko::parser::make_WHILE(ctx->line());

_Bool     return cecko::parser::make_ETYPE(cecko::gt_etype::BOOL, ctx->line());

"["      return cecko::parser::make_LBRA(ctx->line());

"]"     return cecko::parser::make_RBRA(ctx->line());

"("      return cecko::parser::make_LPAR(ctx->line());

")"      return cecko::parser::make_RPAR(ctx->line());

"{"      return cecko::parser::make_LCUR(ctx->line());

"}"      return cecko::parser::make_RCUR(ctx->line());

"."      return cecko::parser::make_DOT(ctx->line());

"->"     return cecko::parser::make_ARROW(ctx->line());

"++"      return cecko::parser::make_INCDEC(cecko::gt_incdec::INC, ctx->line());

"--"      return cecko::parser::make_INCDEC(cecko::gt_incdec::DEC, ctx->line());

&     return cecko::parser::make_AMP(ctx->line());

"*"      return cecko::parser::make_STAR(ctx->line());

"+"      return cecko::parser::make_ADDOP(cecko::gt_addop::ADD, ctx->line());

"-"      return cecko::parser::make_ADDOP(cecko::gt_addop::SUB, ctx->line());

!     return cecko::parser::make_EMPH(ctx->line());

"/"      return cecko::parser::make_DIVOP(cecko::gt_divop::DIV, ctx->line());

%     return cecko::parser::make_DIVOP(cecko::gt_divop::MOD, ctx->line());

"<"      return cecko::parser::make_CMPO(cecko::gt_cmpo::LT, ctx->line());

>     return cecko::parser::make_CMPO(cecko::gt_cmpo::GT, ctx->line());

"<="     return cecko::parser::make_CMPO(cecko::gt_cmpo::LE, ctx->line());

>=      return cecko::parser::make_CMPO(cecko::gt_cmpo::GE, ctx->line());

==      return cecko::parser::make_CMPE(cecko::gt_cmpe::EQ, ctx->line());

!=      return cecko::parser::make_CMPE(cecko::gt_cmpe::NE, ctx->line());

&&      return cecko::parser::make_DAMP(ctx->line());

"||"    return cecko::parser::make_DVERT(ctx->line());

;     return cecko::parser::make_SEMIC(ctx->line());

:     return cecko::parser::make_COLON(ctx->line());

,     return cecko::parser::make_COMMA(ctx->line());

=     return cecko::parser::make_ASGN(ctx->line());

"*="     return cecko::parser::make_CASS(cecko::gt_cass::MULA, ctx->line());

"/="     return cecko::parser::make_CASS(cecko::gt_cass::DIVA, ctx->line());

%=      return cecko::parser::make_CASS(cecko::gt_cass::MODA, ctx->line());

"+="     return cecko::parser::make_CASS(cecko::gt_cass::ADDA, ctx->line());

"-="     return cecko::parser::make_CASS(cecko::gt_cass::SUBA, ctx->line());

{IDENT}     {
                if(ctx->is_typedef(yytext)){
                  return cecko::parser::make_TYPEIDF(yytext, ctx->line());
                } else {
                  return cecko::parser::make_IDF(yytext, ctx->line());
                }
            }
0[xX]{HEXDIGIT}[_g-zG-Z]*     {
                                    std::string tempstr(yytext);
                                    tempstr = tempstr.substr(2, tempstr.length());
                                    auto num_str = get_leading_hex(tempstr);

                                    if (num_str.length() != tempstr.length()) {
                                          ctx->message(cecko::errors::BADINT, ctx->line(), yytext);
                                    }

                                    auto converted_trunc = str_to_hex(num_str);
                                    auto num = std::get<0>(converted_trunc);
                                    auto trunc = std::get<1>(converted_trunc);

                                    if (trunc) {
                                          ctx->message(cecko::errors::INTOUTRANGE, ctx->line(), yytext);
                                    }

                                    return cecko::parser::make_INTLIT(num, ctx->line());
                              }

{DIGIT}{IDENT}?     {
                          auto num_str = get_leading_number(yytext);

                          if (num_str.length() != strlen(yytext)) {
                                ctx->message(cecko::errors::BADINT, ctx->line(), yytext);
                          }

                          auto converted_trunc = str_to_int(num_str);
                          auto num = std::get<0>(converted_trunc);
                          auto trunc = std::get<1>(converted_trunc);

                          if (trunc) {
                                ctx->message(cecko::errors::INTOUTRANGE, ctx->line(), yytext);
                          }

                          return cecko::parser::make_INTLIT(num, ctx->line());
                    }

{WS}+     /* ignore whitespaces */

\n				ctx->incline();

.				ctx->message(cecko::errors::UNCHAR, ctx->line(), yytext);

<<EOF>>			return cecko::parser::make_EOF(ctx->line());

%%

namespace cecko {

	yyscan_t lexer_init(FILE * iff)
	{
		yyscan_t scanner;
		yylex_init(&scanner);
		yyset_in(iff, scanner);
		return scanner;
	}

	void lexer_shutdown(yyscan_t scanner)
	{
		yyset_in(nullptr, scanner);
		yylex_destroy(scanner);
	}

}
