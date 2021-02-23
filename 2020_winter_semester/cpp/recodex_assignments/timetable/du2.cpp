#include "du2.hpp"
#include <bits/c++config.h>
#include <iomanip>
#include <istream>
#include <memory>
#include <ostream>
#include <string>
#include <string_view>

std::istream& operator>>(std::istream& str, CSVRow& data) {
    data.readNextRow(str);
    return str;
}

StopPtr get_or_assign_stop(timetable & tt, CSVRow& row) {
    StopPtr stop;
    std::string s_name(row[col_name::sn]);
    auto sit = tt.stops.find(s_name);

    if (sit != tt.stops.end()) {
        stop = sit->second;
    } else {
        Stop s(s_name);
        stop = std::make_shared<Stop>(s);
        tt.add_stop(stop);
    }

    return stop;
}

PlatformPtr get_or_assign_platform(StopPtr stop, CSVRow& row) {
    PlatformPtr platform;
    std::string p_name(row[col_name::sid]);
    auto pit = stop->platforms.find(p_name);

    if (pit != stop->platforms.end()) {
        platform = pit->second;
    } else {
        Platform p(p_name);
        platform = std::make_shared<Platform>(p);
        stop->add_platform(platform);
    }

    return platform;

}

PlatformRoutePtr get_or_assign_platform_route(PlatformPtr platform, CSVRow& row) {
    PlatformRoutePtr platform_route;
    std::string pr_name(row[col_name::rsn]);
    auto prit = platform->platform_routes.find(pr_name);

    if (prit != platform->platform_routes.end()) {
        platform_route = prit->second;
    } else {
        PlatformRoute pr(pr_name);
        platform_route = std::make_shared<PlatformRoute>(pr);
        platform->add_route(platform_route);
    }

    return platform_route;
}

TripPtr get_or_assign_trip(timetable & tt, CSVRow& row) {
    TripPtr trip;
    std::string t_name(row[col_name::tid]);
    int tid = std::stoi(t_name);
    auto tit = tt.trips.find(tid);

    if (tit != tt.trips.end()) {
        trip = tit->second;
    } else {
        Trip t(tid);
        trip = std::make_shared<Trip>(t);
        tt.add_trip(trip);
    }

    return trip;
}

void read_timetable(timetable &tt, std::istream &ifs) {
    // TODO: check the header consistency
    std::string line;
    std::getline(ifs, line);

    CSVRow row;
    while(ifs >> row) {
        auto stop = get_or_assign_stop(tt, row);

        auto platform = get_or_assign_platform(stop, row);

        auto platform_route = get_or_assign_platform_route(platform, row);

        auto trip = get_or_assign_trip(tt, row);

        // Create departures

        // Parse departure time
        std::string dtime_str(row[col_name::dt]);
        int hh = std::stoi(dtime_str.substr(0, 2));
        int mm = std::stoi(dtime_str.substr(3, 2));
        packed_time dtime = pack_time(hh, mm);

        std::string seq(row[col_name::ss]);
        int position = std::stoi(seq);

        int tid = std::stoi(std::string(row[col_name::tid]));
        auto ttit = tt.trips.find(tid);
        RouteDeparture rd(dtime, &*ttit, position);

        std::string s_name(row[col_name::sn]);
        auto ssit = tt.stops.find(s_name);
        TripDeparture td(dtime, &*ssit);

        platform_route->add_departure(rd);
        trip->add_departure(td, position);
    }

}


// Timetable accessor methods
stops_const_reference stops(timetable_const_reference tt) {
    return tt.stops;
}

stop_const_reference get_stop(timetable_const_reference tt, const std::string & name) {
    return *tt.stops.find(name);
}

trips_const_reference trips(timetable_const_reference tt) {
    return tt.trips;
}


// Stop accessor methods
stop_name_const_reference stop_name(stop_const_reference st) {
    return st.second->name;
}

platforms_const_reference platforms(stop_const_reference st) {
    return st.second->platforms;
}

platform_const_reference get_platform(stop_const_reference st, const std::string &name) {
    return *st.second->platforms.find(name);
}


// Platform accessor methods
platform_name_const_reference platform_name(platform_const_reference pl) {
    return pl.second->id;
}

platform_routes_const_reference routes(platform_const_reference pl) {
    return pl.second->platform_routes;
}

// Platform route accessor methods
route_name_const_reference route_name(platform_route_const_reference pr) {
    return pr.second->name;
}

route_departures_const_reference departures(platform_route_const_reference pr) {
    return pr.second->departures;
}

route_departure_const_iterator departure_at(platform_route_const_reference pr, packed_time tm) {
    for (auto it = pr.second->departures.begin(); it != pr.second->departures.end(); ++it) {
        if ((*it).second.departure_time >= tm) {
            return it;
        }
    }

    return pr.second->departures.end();
}

// Route departure accessor methods
packed_time departure_time(route_departure_const_reference rd) {
    return rd.second.departure_time;
}

trip_const_reference trip(route_departure_const_reference rd) {
    return *rd.second.trip;
}

trip_departure_const_iterator position_in_trip(route_departure_const_reference rd) {
    return rd.second.trip->second->departures.find(rd.second.position);
}

// Trip accessor methods
trip_name_const_reference trip_name(trip_const_reference tr) {
    return tr.second->name;
}

trip_departures_const_reference departures(trip_const_reference tr) {
    return tr.second->departures;
}

seq_id sequence_id(trip_const_reference tr, trip_departure_const_iterator tdit) {
    return (*tdit).first;
}

// Trip departure accessor methods
packed_time departure_time(trip_departure_const_reference td) {
    return td.second.departure_time;
}

stop_const_reference stop(trip_departure_const_reference td) {
    return *td.second.stop;
}

void print_trip(std::ostream &oss, const timetable & tt, trip_const_reference trip) {
    for (auto && dep : trip.second->departures) {
        oss << dep.second.stop->first << std::endl;
    }
}

void print_timetable(std::ostream &oss, const timetable & tt, platform_route_const_reference line) {
    auto it = line.second->departures.begin();
    for (std::size_t i = 0; i < 24; ++i) {
        oss << std::setw(2) << std::setfill('0') << i << ":";
        auto hour_beg = pack_time(i, 0);
        auto hour_end = pack_time(i, 59);
        while (it != line.second->departures.end() && (*it).first >= hour_beg && (*it).first <= hour_end) {
            oss << " " << std::setw(2) << std::setfill('0') << minutes((*it).first);
            ++it;
        }
        oss << std::endl;
    }

}

void print_line(std::ostream &oss, const timetable & tt, platform_route_const_reference line) {
    oss << "*** " << line.first << " ***" << std::endl;
    auto fd = &*line.second->departures.begin();

    for (auto && dep : line.second->departures) {
        if (dep.second.trip->second->departures.size() < (*fd).second.trip->second->departures.size()) {
            fd = &dep;
        }
    }

    auto trip = *(*fd).second.trip;
    print_trip(oss, tt, trip);
    print_timetable(oss, tt, line);

}

void print_platform_timetables(std::ostream &oss, const timetable &tt, const std::string &sid, const std::string &pid) {
    for (auto && line : tt.stops.at(sid)->platforms.at(pid)->platform_routes) {
        print_line(oss, tt, line);
    }
}
