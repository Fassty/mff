#include "du2.hpp"
#include "connection.hpp"
#include "dump.hpp"

#include <iostream>
#include <fstream>
#include <iomanip>

int main(int argc, char * * argv)
{
	std::vector< std::string> arg(argv + 1, argv + argc);

	if (arg.size() < 1)
	{
		return -1;
	}

	try {

		timetable tt;

		{
			//std::cout << "Reading data " << arg[0] << std::endl;

			std::ifstream iff(arg[0]);

			read_timetable(tt, iff);
		}

		auto ita = arg.begin() + 1;

		for (;;)
		{
			if (ita == arg.end())
				break;

			if (*ita == "-sw")
			{
				//std::cout << "Dumping data stop-wise " << fn << std::endl;
				dump::dump_stopwise(std::cout, tt);
				++ita;
				continue;
			}

			if (*ita == "-tw")
			{
				//std::cout << "Dumping data trip-wise " << fn << std::endl;
				dump::dump_tripwise(std::cout, tt);
				++ita;
				continue;
			}

			if (*ita == "-pt" && arg.end() - ita >= 3)
			{
				//print_platform_timetables(std::cout, tt, "Palmovka", "U529Z1");
				//print_platform_timetables(std::cout, tt, "Hellichova", "U138Z2");
				print_platform_timetables(std::cout, tt, ita[1], ita[2]);
				ita += 3;
				continue;
			}

			if (*ita == "-sc" && arg.end() - ita >= 6)
			{
				//connection::print_shortest_connection(std::cout, tt, "Palmovka", "Florenc", pack_time(16, 00), 1);
				//connection::print_shortest_connection(std::cout, tt, "Palmovka", "Hellichova", pack_time(16, 00), 1);
				//connection::print_shortest_connection(std::cout, tt, "Palmovka", "Hellichova", pack_time(16, 00), 5);
				//connection::print_shortest_connection(std::cout, tt, "Motol", "Kobylisy", pack_time(16, 00), 2);
				connection::print_shortest_connection(std::cout, tt, ita[1], ita[2], pack_time(std::stoi(ita[3]), std::stoi(ita[4])), std::stoi(ita[5]));
				ita += 6;
				continue;
			}

			std::cout << "Invalid switch \"" << *ita << "\"" << std::endl;
			break;
		}
	}
	catch (const std::exception & e)
	{
		std::cout << "Exception: " << e.what() << std::endl;
		return -1;
	}

	return 0;
}
