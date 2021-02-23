/*
connection.hpp - fastest connection between two points
*/

#ifndef connection_hpp_
#define connection_hpp_

#include <iterator>
#include <vector>
#include <map>
#include <set>
#include <ostream>
#include <cassert>
#include <algorithm>
#include <iostream>
#include <iomanip>
#include <sstream>
#include <string>

#ifdef DEBUG_CONNECTION
#include <iostream>
#include <iomanip>
#endif

namespace connection {

	namespace implementation {

		template< typename U>
		inline std::string stringize(U && v)
		{
			std::ostringstream oss;
			oss << v;
			return oss.str();
		}

		using std::begin;

		template< typename TT>
		class connection_finder
		{
		public:
			using stop_cr = decltype(get_stop(std::declval<TT>(), std::declval<std::string>()));
			using platform_cr = decltype(get_platform(std::declval<stop_cr>(), std::declval<std::string>()));
			using platform_routes_cr = decltype(routes(std::declval<platform_cr>()));
			using platform_routes_ci = decltype(begin(std::declval<platform_routes_cr>()));
			using platform_route_cr = typename std::iterator_traits< platform_routes_ci>::reference;
			using departures_cr = decltype(departures(std::declval<platform_route_cr>()));
			using departures_ci = decltype(begin(std::declval<departures_cr>()));
			using departure_cr = typename std::iterator_traits< departures_ci>::reference;
			using ptime = std::remove_reference_t< decltype(departure_time(std::declval<departure_cr>()))>;
			using trip_cr = decltype(trip(std::declval<departure_cr>()));
			using trip_departures_ci = decltype(position_in_trip(std::declval<departure_cr>()));

			connection_finder(const TT & tt, stop_cr from_sid, stop_cr to_sid, ptime tm, ptime transfer_tm)
				: tt_{ tt }, from_sid_{ &from_sid }, to_sid_{ &to_sid }, tm_{ tm }, transfer_tm_{ transfer_tm }, last_complete_{ qs_.end() }
			{
				run();
			}

			bool run()
			{
				rm_.clear();
				qs_.clear();
				last_complete_ = qs_.end();

				last_complete_ = insert_reachability(from_sid_, tm_ - transfer_tm_, 0, leg_entry{});	// initial stop

				for (; last_complete_ != qs_.end() && std::get< 1>(*last_complete_)->first != to_sid_; ++last_complete_)
				{
					ptime tm = std::get<0>(*last_complete_);
					ptime tm2 = tm + transfer_tm_;
					auto rmp = std::get<1>(*last_complete_);
					auto sp = rmp->first;

#ifdef DEBUG_CONNECTION
					std::cout << "  " << hours(tm2) << ":" << minutes(tm2);
					std::cout << " '" << qs_.size();
					std::cout << " " << stop_name(*sp);
					if (rmp->second.previous)
					{
						auto && c = rmp->second.leg;
						auto from_tm = departure_time(*c.from_seq);
						auto to_tm = departure_time(*c.to_seq);

						std::cout << " [ "
							<< std::setw(2) << std::setfill('0') << hours(from_tm)
							<< ":"
							<< std::setw(2) << std::setfill('0') << minutes(from_tm)
							<< " "
							<< stop_name(stop(*c.from_seq))
							<< " >>> "
							<< route_name(*c.rp)
							<< " >>> "
							<< stop_name(stop(*c.to_seq))
							<< " "
							<< std::setw(2) << std::setfill('0') << hours(to_tm)
							<< ":"
							<< std::setw(2) << std::setfill('0') << minutes(to_tm)
							<< " ]";
					}
					std::cout << std::endl;
#endif
					for (auto && pdata : platforms(*sp))
					{
						for (auto && prdata : routes(pdata))
						{
#ifdef DEBUG_CONNECTION
							std::cout << "    " << route_name(prdata) << ":";
#endif								
							auto dmit = departure_at(prdata, tm2);
							if (dmit == departures(prdata).end())
							{	// reached midnight - wrap around
								dmit = departures(prdata).begin();
							}
							if (dmit != departures(prdata).end())
							{
#ifdef DEBUG_CONNECTION
								auto tm22 = departure_time(*dmit);
								std::cout << " " << hours(tm22) << ":" << minutes(tm22) << " >";
#endif
								auto && tp = trip(*dmit);
								auto from_seq = position_in_trip(*dmit);
								assert(from_seq != departures(tp).end());
								for (auto it = std::next(from_seq); it != departures(tp).end(); ++it)
								{
									auto sp2 = &stop(*it);
									auto tm3 = departure_time(*it);

									if (tm3 < tm2)
									{
										// wrapped around midnight - shift
										tm3 += 1440;
									}

									insert_reachability(sp2, tm3, rmp,
										leg_entry{ &prdata, &tp, from_seq, it });

#ifdef DEBUG_CONNECTION
									std::cout << " " << hours(tm3) << ":" << minutes(tm3);
#endif
								}
							}
#ifdef DEBUG_CONNECTION
							std::cout << std::endl;
#endif
						}
					}
				}

				return last_complete_ != qs_.end();
			}

			struct leg_entry
			{
				using platform_route_const_pointer = decltype(&std::declval<platform_route_cr>());
				using trip_const_pointer = decltype(&std::declval<trip_cr>());
				leg_entry()
					: rp{ nullptr }, tp{ nullptr }, from_seq{}, to_seq{}
				{
				}
				leg_entry(platform_route_const_pointer r, trip_const_pointer t, trip_departures_ci from_s, trip_departures_ci to_s)
					: rp{ r }, tp{ t }, from_seq(from_s), to_seq(to_s)
				{}
				platform_route_const_pointer rp;
				trip_const_pointer tp;
				trip_departures_ci from_seq;
				trip_departures_ci to_seq;
			};
			using connection_vector = std::vector< leg_entry>;

			connection_vector get_connection() const
			{
				connection_vector cv;

				if (last_complete_ != qs_.end())
				{
					for (auto rp = std::get< 1>(*last_complete_); rp->second.previous; rp = rp->second.previous)
					{
						cv.push_back(rp->second.leg);
					}

					std::reverse(cv.begin(), cv.end());
				}

				return cv;
			}

		private:
			using stop_const_pointer = decltype(&std::declval< stop_cr>());

			const TT & tt_;
			stop_const_pointer from_sid_;
			stop_const_pointer to_sid_;
			ptime tm_;
			ptime transfer_tm_;

			struct reachability_data;
			using reachability_map = std::map< stop_const_pointer, reachability_data>;
			using reachability_pointer = typename reachability_map::pointer;

			using queue_entry = std::tuple< ptime, reachability_pointer>;
			struct qs_comparator {
				bool operator()(const queue_entry & a, const queue_entry & b) const
				{
					if (std::get<0>(a) < std::get<0>(b))
						return true;
					if (std::get<0>(a) > std::get<0>(b))
						return false;
					return stop_name(*std::get<1>(a)->first) < stop_name(*std::get<1>(b)->first);	// enforce consistent ordering in case of reaching different stops in the same minute
				}
			};
			using queue_set = std::set< queue_entry, qs_comparator>;
			using queue_iterator = typename queue_set::iterator;

			struct reachability_data {
				reachability_data()
					: qp{}, previous{ nullptr }, leg{}
				{}
				queue_iterator qp;
				reachability_pointer previous;
				leg_entry leg;
			};

			reachability_map rm_;
			queue_set qs_;
			queue_iterator last_complete_;

			queue_iterator insert_reachability(stop_const_pointer sid, ptime tm, reachability_pointer previous, leg_entry leg)
			{
				auto rmrv = rm_.emplace(sid, reachability_data{});
				auto rmp = &* rmrv.first;

				if (rmrv.second // new
					|| tm < std::get<0>(*rmp->second.qp) // or faster
					|| ( tm == std::get<0>(*rmp->second.qp) && stringize( trip_name(*leg.tp)) < stringize(trip_name(*rmp->second.leg.tp)) ) )	// or the same minute and lower trip name
				{
					if (!rmrv.second)
					{
						// remove old queue entry
						assert(rmp->second.qp != last_complete_);
						qs_.erase(rmp->second.qp);
					}

					auto qsrv = qs_.emplace(tm, rmp);
					assert(qsrv.second);

					rmp->second.qp = qsrv.first;
					rmp->second.previous = previous;
					rmp->second.leg = leg;
				}

				return rmp->second.qp;
			}
		};
	}

	template< typename TT, typename PT>
	inline void print_shortest_connection(std::ostream & oss, const TT & tt, const std::string & from_sid, const std::string & to_sid, PT tm, int transfer_tm)
	{
		auto && from_sp = get_stop(tt, from_sid);
		auto && to_sp = get_stop(tt, to_sid);

		std::cout
			<< std::setw(2) << std::setfill('0') << hours(tm)
			<< ":"
			<< std::setw(2) << std::setfill('0') << minutes(tm)
			<< " "
			<< from_sid
			<< " >>> "
			<< to_sid
			<< " (transfer "
			<< transfer_tm
			<< " min):"
			<< std::endl;

		implementation::connection_finder< TT> cf{ tt, from_sp, to_sp, tm, pack_time( 0, transfer_tm) };
		auto connection = cf.get_connection();

		for (auto && c : connection)
		{
			auto from_tm = departure_time(*c.from_seq);
			auto to_tm = departure_time(*c.to_seq);

			oss << "  "
				<< std::setw(2) << std::setfill('0') << hours(from_tm)
				<< ":"
				<< std::setw(2) << std::setfill('0') << minutes(from_tm)
				<< " "
				<< stop_name(stop(*c.from_seq))
				<< " >>> "
				<< route_name(*c.rp)
				<< " >>> "
				<< stop_name(stop(*c.to_seq))
				<< " "
				<< std::setw(2) << std::setfill('0') << hours(to_tm)
				<< ":"
				<< std::setw(2) << std::setfill('0') << minutes(to_tm)
				<< std::endl;
		}
	}
}

#endif
