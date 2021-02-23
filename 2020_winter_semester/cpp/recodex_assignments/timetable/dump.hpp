/*
dump.hpp - dump data into file
*/

#ifndef dump_hpp_
#define dump_hpp_

#include <ostream>
#include <sstream>
#include <iomanip>
#include <string>
#include <array>
#include <type_traits>
#include <vector>
#include <algorithm>
#include <iterator>

namespace dump {

	template< typename TT>
	inline void dump_stopwise(std::ostream & oss, TT && tt)
	{
		static const auto tab = '\t';

		oss << "route_short_name" << tab << "trip_id" << tab << "stop_sequence" << tab << "stop_id" << tab << "stop_name" << tab << "departure_time" << std::endl;

		for (auto && stop : stops(tt))
		{
			auto && stop_name_ = stop_name(stop);

			for (auto && platform : platforms(stop))
			{
				auto && platform_name_ = platform_name(platform);

				for (auto && route : routes(platform))
				{
					auto && route_name_ = route_name(route);

					for (auto && departure : departures(route))
					{
						auto departure_time_ = departure_time(departure);
						auto && departure_trip = trip(departure);
						auto trip_iterator = position_in_trip(departure);

						auto && trip_name_ = trip_name(departure_trip);
						auto stop_sequence_ = sequence_id(departure_trip, trip_iterator);

						oss
							<< route_name_ << tab
							<< trip_name_ << tab
							<< stop_sequence_ << tab
							<< platform_name_ << tab
							<< stop_name_ << tab
							<< std::setw(2) << std::setfill('0') << hours(departure_time_) << ":"
							<< std::setw(2) << std::setfill('0') << minutes(departure_time_) << std::endl;
					}
				}
			}
		}
	}

	template< typename T>
	inline std::enable_if_t< std::is_reference_v<T>, std::remove_reference_t<T>*> pointerize(std::remove_reference_t<T> & v)
	{
		return &v;
	}

	template< typename T>
	inline std::enable_if_t< ! std::is_reference_v<T>, T&> pointerize(T & v)
	{
		return v;
	}

	template< typename T>
	using pointerize_t = std::conditional_t< std::is_reference_v<T>, std::remove_reference_t<T>*, T>;

	template< typename T>
	inline std::enable_if_t< std::is_reference_v<T>, T> depointerize(std::remove_reference_t<T>* v)
	{
		return *v;
	}

	template< typename T>
	inline std::enable_if_t< !std::is_reference_v<T>, T&> depointerize(T& v)
	{
		return v;
	}

	template< typename U>
	inline std::string stringize(U && v)
	{
		std::ostringstream oss;
		oss << v;
		return oss.str();
	}

	template< typename TT>
	inline void dump_tripwise(std::ostream & oss, TT && tt)
	{
		static const auto tab = '\t';

		oss << "route_short_name" << tab << "trip_id" << tab << "stop_sequence" << tab << "stop_id" << tab << "stop_name" << tab << "departure_time" << std::endl;

		using trip_t = decltype(*std::begin(trips(tt)));
		using trip_ptr_t = pointerize_t< trip_t>;

		auto && k_trips = trips(tt);

		std::vector< std::pair< std::string, trip_ptr_t>> v_trips( k_trips.size());

		std::transform(k_trips.begin(), k_trips.end(), v_trips.begin(), [](auto && trip_) {
			auto && trip_name_ = trip_name(trip_);
			return std::make_pair(stringize(trip_name_), pointerize<trip_t>(trip_));
			});

		std::sort(v_trips.begin(), v_trips.end(), [](auto && p1, auto && p2) {
			return p1.first < p2.first;
			});

		for (auto && pair_ : v_trips)
		{
			auto && trip_ = depointerize<trip_t>(pair_.second);
			auto && trip_name_text = pair_.first;
			auto && trip_name_ = trip_name(trip_);
			int seq_id = 1;

			for ( auto trip_iterator = departures(trip_).begin(); trip_iterator != departures(trip_).end(); ++trip_iterator)
			{
				auto && departure = *trip_iterator;
				auto departure_time_ = departure_time(departure);
				auto && departure_stop = stop(departure);
				auto && stop_name_ = stop_name(departure_stop);

				auto stop_sequence_ = sequence_id(trip_, trip_iterator);

				std::string platform_name_;
				std::string route_name_;

				for (auto && platform : platforms(departure_stop))
				{
					for (auto && route : routes(platform))
					{
						for ( auto route_iterator = departure_at(route, departure_time_); 
							route_iterator != departures(route).end()
							&& departure_time( * route_iterator) == departure_time_; 
							++ route_iterator)
						{
							if ( trip_name(trip(*route_iterator)) == trip_name_
								&& position_in_trip(*route_iterator) == trip_iterator)
							{
								if (&trip(*route_iterator) != &trip_)
								{
									throw std::runtime_error("Same route name but different object");
								}
								// this is my trip
								platform_name_ = platform_name(platform);
								route_name_ = route_name(route);
							}
						}
					}
				}

				if (platform_name_.empty() || route_name_.empty())
				{
					oss << "*** Trip departure not found: trip "
						<< trip_name_text << " from stop "
						<< stop_name_ << " at "
						<< std::setw(2) << std::setfill('0') << hours(departure_time_) << ":"
						<< std::setw(2) << std::setfill('0') << minutes(departure_time_) << " sequence " 
						<< stop_sequence_ << std::endl;

					for (auto && platform : platforms(departure_stop))
					{
						for (auto && route : routes(platform))
						{
							for (auto route_iterator = departure_at(route, departure_time_);
								route_iterator != departures(route).end();
								++route_iterator)
							{
								if (departure_time(*route_iterator) != departure_time_)
									break;

								auto pos = position_in_trip(*route_iterator);

								oss << "*** Tried platform " 
									<< platform_name(platform) << " route " 
									<< route_name(route) << " trip " 
									<< trip_name(trip((*route_iterator))) << " at "
									<< std::setw(2) << std::setfill('0') << hours(departure_time(*route_iterator)) << ":"
									<< std::setw(2) << std::setfill('0') << minutes(departure_time(*route_iterator)) << " sequence "
									<< sequence_id(trip_, pos) << std::endl;
							}
						}
					}

//					throw std::runtime_error("Name empty");
				}
				
				oss
					<< route_name_ << tab
					<< trip_name_text << tab
//					<< stop_sequence_ << tab
					<< seq_id << tab
					<< platform_name_ << tab
					<< stop_name_ << tab
					<< std::setw(2) << std::setfill('0') << hours(departure_time_) << ":"
					<< std::setw(2) << std::setfill('0') << minutes(departure_time_) << std::endl;

				++seq_id;
			}
		}
	}
}

#endif
