#include <iostream>
// To show the limits
#include <climits>
// To show precision of float and double
#include <float.h>


#define GLOBAL_CONST 10 // This is a global constant

void constants() {
  const int LOCAL_CONST = 10;
  enum { ENUM_CONST = 10 };

  std::cout << "Printing const from global scope: "<< GLOBAL_CONST << std::endl;
  std::cout << "Printing const from local scope: "<< LOCAL_CONST << std::endl;
  std::cout << "Printing const from enum: "<< ENUM_CONST << std::endl;
  std::cout << std::endl;
}

void int_vs_double_division() {
  // Integer division is used for integers by default
  // Float needs to be specified by a decimal point to return double value
  std::cout << "This operation return an int\n";
  std::cout << "5/2 = " << 5 / 2 << std::endl;
  std::cout << "5/2.0 = " << 5 / 2.0 << std::endl;

  std::cout << std::endl;

  int int_a = 5;
  double double_a = 5;
  int int_b = 2;
  double double_b = 2;

  // When the number is stored in a variable the divison will use the most specific type
  std::cout << "For typed variables the most specific type is used\n";
  std::cout << "int/int = " << int_a / int_b << std::endl;
  std::cout << "int/double = " << int_a / double_b << std::endl;
  std::cout << "double/int = " << double_a / int_b << std::endl;
  std::cout << "double/double = " << double_a / double_b << std::endl;
}

void integral_type_bounds() {
  std::cout << "Maximum value of short: " << SHRT_MAX << std::endl;
  std::cout << "Maximum value of int: " << INT_MAX << std::endl;
  std::cout << "Minimum value of int: " << INT_MIN << std::endl;
  std::cout << "Maximum value of long: " << LONG_MAX << std::endl;
}

void precision_of_floating_point() {
  long BIG_NUMBER = 1e15;
  float prec_float = 10.0 / 3 * BIG_NUMBER;
  double prec_double = 10.0 / 3 * BIG_NUMBER;
  long double prec_ldouble = (long double)10.0 / 3 * BIG_NUMBER;
  // std::fixed for full print of the number instead of scientific notation
  std::cout << "Float precision: " << FLT_DIG << " digits" <<std::endl;
  std::cout << std::fixed << prec_float << std::endl;
  std::cout << "Double precision: " << DBL_DIG << " digits" << std::endl;
  std::cout << std::fixed << prec_double << std::endl;
  std::cout << "Long double precision: " << LDBL_DIG << " digits" << std::endl;
  std::cout << std::fixed << prec_ldouble << std::endl;
}

int main() {
  // Types:
  //    char
  //    short
  //    int
  //    long
  //    float
  //    double
  //    long double
  //    bool

  // There are multiple ways of defining constants in c++
  constants();

  // Int vs double division demonstration
  int_vs_double_division();

  std::cout << std::endl;

  // Max and min values of some basic integral types from climits library
  integral_type_bounds();

  std::cout << std::endl;

  // Float and double precision:
  precision_of_floating_point();

  // Escape characters because they are actually cool
  // Sadly doesn't work from VIM
  std::cout << "\nThis is a cool escape char \\v\n";
  std::cout << "Hey\vwhat\va\vnice\vstaircase!\nAnd\vyet\vanother\vone!\n";

  // Anything but 0 is True if used as boolean
  bool tru = -1;
  bool fooled = 0;

  std::cout << std::endl;

  std::cout << "-1 is true: " << tru << std::endl;
  std::cout << "0 is false: " << fooled << std::endl;

  return 0;
}

