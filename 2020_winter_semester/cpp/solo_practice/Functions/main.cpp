#include <iostream>
#include <cmath> // C++ math library
#include <string> // needs to be included, by default string are array of chars

// Function declarations (could be in a header file)
// Function needs to be declared of even defined before being used
int add_one_by_value(int);
void add_one_by_ref(int*);
double power(double, int);

int main() {
  int a = 1;
  int b = 1;

  add_one_by_value(a);
  b = add_one_by_value(b);

  add_one_by_ref(&a);
  add_one_by_ref(&b);

  std::cout << a << std::endl;
  std::cout << b << std::endl;

  std::cout << pow(b, 2) << std::endl;
  std::cout << power(b, 2) << std::endl;

  std::cout << std::endl;

  std::cout << sqrt(9) << std::endl; // Square root
  std::cout << pow(6,2) << std::endl; // Power
  std::cout << remainder(10, 3) << std::endl; // Like modulus but also return floating point values
  std::cout << fmax(12, 8) << std::endl; // Outputs the larger of the two
  std::cout << fmin(12, 8) << std::endl; // Outputs the smaller of the two
  std::cout << floor(1.5) << std::endl; // Round down
  std::cout << ceil(1.5) << std::endl; // Round up
  return 0;
}

// Function definitions
int add_one_by_value(int val) {
  ++val;
  return val;
}

void add_one_by_ref(int* val) {
  ++*val;
}

double power(double base, int exponent) {
  double result = 1;
  for(int i = 0; i<exponent; ++i) {
    result *= base;
  }

  return result;
}
