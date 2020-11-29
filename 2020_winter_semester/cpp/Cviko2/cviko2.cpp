#include <iostream>
#include <cctype>
#include <string>
#include "pocitadlo.hpp"

using namespace std;

void Counter::count(void){
    string current;
	list<int> numbers;
	char c;
	bool was_digit
	bool was_letter = false;
	bool line_terminated = false;

	for(;;){
		c = in_.get();
		++chars_;

		// New row
		if(c == '\n'){
			++rows_;
			line_terminated = true;
			continue;
		}

		// It's a digit
		if(isdigit(c) && !was_letter) {
			current += c;
		} // It was a digit
		else if(is) {
		} // It's a sentence
		else if() {}

		// EOF
		if(in_.fail()){
			if(!line_terminated){
				++rows_;
			}
			return;
		}

		line_terminated = false;
	}
}

void count_all(istream& s){
	Counter c;
}

int main() {
	count_all(cin);
	return 0;
}
