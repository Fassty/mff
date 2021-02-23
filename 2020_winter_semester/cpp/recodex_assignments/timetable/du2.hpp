/*
	du2.hpp - timetable data structures
*/

#ifndef du2_hpp_
#define du2_hpp_

#include <bits/c++config.h>
#include <cstdint>
#include <iterator>
#include <string>
#include <set>
#include <fstream>
#include <utility>
#include <vector>
#include <unordered_set>
#include <map>
#include <memory>
#include <iterator>
#include <sstream>
#include <iostream>
#include <string_view>

using packed_time = std::int_least16_t;

inline packed_time pack_time(int hh, int mm)
{
	return 60 * hh + mm;
}

inline int hours(packed_time tm)
{
	return tm / 60;
}

inline int minutes(packed_time tm)
{
	return tm % 60;
}

// dummy - for demonstration purposes only
struct dummy_object {};
using dummy_container = std::set< dummy_object>;

enum col_name {
    rsn, tid, ss, sid, sn, dt
};

class CSVRow
{
    public:
        std::string_view operator[](std::size_t index) const {
            return std::string_view(&m_line[m_data[index] + 1], m_data[index + 1] -  (m_data[index] + 1));
        }

        std::size_t size() const {
            return m_data.size() - 1;
        }
        void readNextRow(std::istream& str) {
            std::getline(str, m_line);

            m_data.clear();
            m_data.emplace_back(-1);
            std::string::size_type pos = 0;
            while((pos = m_line.find('\t', pos)) != std::string::npos) {                                                                         m_data.emplace_back(pos);
                ++pos;
            }

            pos   = m_line.size();
            m_data.emplace_back(pos);
        }
    private:
        std::string m_line;
        std::vector<int> m_data;
};


class Stop;
class Platform;
class PlatformRoute;
class RouteDeparture;
class TripDeparture;
class Trip;

using StopPtr = std::shared_ptr<Stop>;
using PlatformPtr = std::shared_ptr<Platform>;
using PlatformRoutePtr = std::shared_ptr<PlatformRoute>;
using RouteDeparturePtr = std::unique_ptr<RouteDeparture>;
using TripDeparturePtr = std::unique_ptr<TripDeparture>;
using TripPtr = std::shared_ptr<Trip>;

// containers - replace with appropriate types of containers
using stop_container = std::map<std::string, StopPtr>;
using platform_container = std::map<std::string, PlatformPtr>;
using platform_route_container = std::map<std::string, PlatformRoutePtr>;
using route_departure_container = std::map<packed_time, RouteDeparture>;
using trip_container = std::map<int, TripPtr>;
using trip_departure_container = std::map<int, TripDeparture>;

class TripDeparture {
    public:
        packed_time departure_time;
        std::pair<const std::string, StopPtr> *stop;

        TripDeparture() {}

        TripDeparture(packed_time departure_time, std::pair<const std::string, StopPtr> *stop):
            departure_time(departure_time), stop(stop) {}
};

class Trip {
    public:
        int name;
        trip_departure_container departures;

        Trip() {}

        Trip(int name):
            name(name) {}

        void add_departure(TripDeparture trip_departure, int seq) {
            departures[seq] = trip_departure;
        }
};

class RouteDeparture {
    public:
        packed_time departure_time;
        std::pair<const int, TripPtr> *trip;
        int position;

        RouteDeparture() {}

        RouteDeparture(packed_time departure_time, std::pair<const int, TripPtr> * trip, int position):
            departure_time(departure_time), trip(trip), position(position) {}

};


class PlatformRoute {
    public:
        std::string name;
        route_departure_container departures;

        PlatformRoute() {}

        PlatformRoute(std::string name):
            name(std::move(name)) {}

        PlatformRoute(const PlatformRoute & pr):
            name(pr.name), departures(pr.departures) {}

        void add_departure(RouteDeparture route_departure) {
            departures[route_departure.departure_time] = route_departure;
        }
};

class Platform {
    public:
        std::string id;
        platform_route_container platform_routes;

        Platform() {}

        Platform(std::string id):
            id(std::move(id)) {}

        void add_route(PlatformRoutePtr route) {
            platform_routes[route->name] = route;
        }
};

class Stop {
    public:
        std::string name;
        platform_container platforms;

        Stop() {}

        Stop(std::string name):
            name(name) {}

        void add_platform(PlatformPtr platform) {
            platforms[platform->id] = platform;
        }
};


// main object - put something inside
class timetable {
    public:
        stop_container stops;
        trip_container trips;
        timetable() {}

        void add_stop(StopPtr stop) {
            stops[stop->name] = stop;
        }

        void add_trip(TripPtr trip) {
            trips[trip->name] = trip;
        }

};

// public attribute types - no change required
using platform_name_const_reference = const std::string &;
using stop_name_const_reference = const std::string &;
using trip_name_const_reference = const int &;
using route_name_const_reference = const std::string &;
using seq_id = int;

// public container references - no change required
using stops_const_reference = const stop_container &;
using platforms_const_reference = const platform_container &;
using platform_routes_const_reference = const platform_route_container &;
using route_departures_const_reference = const route_departure_container &;
using trips_const_reference = const trip_container &;
using trip_departures_const_reference = const trip_departure_container &;

// public iterator references - no change required
using trip_departure_const_iterator = trip_departure_container::const_iterator;
using route_departure_const_iterator = route_departure_container::const_iterator;

// public object references - no change required
using timetable_const_reference = const timetable &;
using stop_const_reference = stop_container::const_reference;
using platform_const_reference = platform_container::const_reference;
using platform_route_const_reference = platform_route_container::const_reference;
using route_departure_const_reference = route_departure_container::const_reference;
using trip_const_reference = trip_container::const_reference;
using trip_departure_const_reference = trip_departure_container::const_reference;

// public accessor functions - implement them
stops_const_reference stops(timetable_const_reference tt);
stop_const_reference get_stop(timetable_const_reference tt, const std::string & name);
trips_const_reference trips(timetable_const_reference tt);

stop_name_const_reference stop_name(stop_const_reference st);
platforms_const_reference platforms(stop_const_reference st);
platform_const_reference get_platform(stop_const_reference st, const std::string & name);

platform_name_const_reference platform_name(platform_const_reference pl);
platform_routes_const_reference routes(platform_const_reference pl);

route_name_const_reference route_name(platform_route_const_reference pr);
route_departures_const_reference departures(platform_route_const_reference pr);
route_departure_const_iterator departure_at(platform_route_const_reference pr, packed_time tm);

packed_time departure_time(route_departure_const_reference rd);
trip_const_reference trip(route_departure_const_reference rd);
trip_departure_const_iterator position_in_trip(route_departure_const_reference rd);

trip_name_const_reference trip_name(trip_const_reference tr);
trip_departures_const_reference departures(trip_const_reference tr);
seq_id sequence_id(trip_const_reference tr, trip_departure_const_iterator tdit);

packed_time departure_time(trip_departure_const_reference td);
stop_const_reference stop(trip_departure_const_reference td);

// public functions - implement them
void read_timetable(timetable & tt, std::istream & ifs);

void print_platform_timetables(std::ostream & oss, const timetable & tt, const std::string & sid, const std::string & pid);

#endif

/**/
