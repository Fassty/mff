#include <iostream>
#include "freq.h"

using namespace std;

void FrequencyCounter::count_occurences(istream& in) {
    string word;
    while(in >> word){
        m[word] += 1;
    }

    for( auto const& [key, val] : m )
    {
        std::cout << key << ':' << val << std::endl ;
    }

}

int main() {
    FrequencyCounter counter;
    counter.count_occurences(cin);
    return 0;
}
