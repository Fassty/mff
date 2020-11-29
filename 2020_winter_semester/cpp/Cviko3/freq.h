#include <iostream>
#include <map>
#include <string>

using namespace std;

class FrequencyCounter
{
private:
    map<string, int> m;
public:
    FrequencyCounter(){};
    void count_occurences(istream& in);
};
