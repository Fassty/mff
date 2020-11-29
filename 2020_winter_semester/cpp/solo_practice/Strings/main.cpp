#include <iostream>
#include <string>

int main() {
  // std::string nothing; // Defaults to an empty string
  std::string example = "Hello";

  // Basic functionallity
  std::cout << "Simple print: " << example << std::endl;
  std::cout << "Print the first char as string is a list of chars:   " << example[0] << std::endl;
  std::cout << "String length: " << example.length() << std::endl;

  // Appending is done with += operator
  example += " you nerds!";
  std::cout << "Append with +=: " << example << std::endl;

  // C string is very limited but nothing needs to be imported
  char cstring[] = "C strings suck";
  std::cout << "A C string: " << cstring << std::endl;

  std::cout << std::endl;

  // Getting a string from input is a harder task we may try
  std::string uin;
  std::cout << "Enter a string or two or more words" << std::endl;
  std::cin >> uin;
  std::cout << "Only the first word is printed out: " << uin << std::endl;
  std::cout << std::endl;

  getline(std::cin, uin); // Clear the input

  // But that only print the first work
  // Because cin works by words... to get the entire line we have to use the getline function
  uin = "";
  std::cout << "Enter a string or two or more words" << std::endl;
  getline(std::cin, uin);
  std::cout << uin << std::endl;
  return 0;
}
