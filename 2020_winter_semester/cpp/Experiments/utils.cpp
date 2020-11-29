#include <iostream>
#include <string>
#include <tuple>
#include <cctype>

std::string get_leading_number(const std::string s)
	{
		int first_non_digit_index = -1;
		for (int i = 0; i < s.length(); i++) {
			if (!isdigit(s[i])) {
				first_non_digit_index = i;
        break;
			}
		}

		return first_non_digit_index == -1 ? s : s.substr(0, first_non_digit_index);
	}

int char_to_digit(const char c) {
		return (int)(c - '0');
	}

std::tuple<int, bool> str_to_int(const std::string s)
	{
		int result = 0;
		bool stripped = false;
		for (auto c : s) {
			int new_result = 10 * result + char_to_digit(c);
			if (new_result <= result) {
				stripped = true;
			}
			result = new_result;
		}
		return std::make_tuple(result, stripped);
	}

int main() {
  std::string str("12345678912346xxxxx1");
  std::string str_val("1234x");
  std::string str_zero("0");
  auto x = get_leading_number(str);
  auto x2 = get_leading_number(str_val);
  auto x3 = get_leading_number(str_zero);

  auto y = str_to_int(x);
  auto y2 = str_to_int(x2);
  auto y3 = str_to_int(x3);

  auto num = std::get<0>(y);
  auto stripped = std::get<1>(y);
  auto num2 = std::get<0>(y2);
  auto strip2 = std::get<1>(y2);
  auto num3 = std::get<0>(y3);
  auto strip3 = std::get<1>(y3);

  std::cout << x << std::endl;
  std::cout << num << std::endl;
  std::cout << stripped << std::endl;
  std::cout << x2 << std::endl;
  std::cout << num2 << std::endl;
  std::cout << strip2 << std::endl;
  std::cout << num3 << std::endl;
  std::cout << strip3 << std::endl;
}
