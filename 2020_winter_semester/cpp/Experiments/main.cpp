#include <vector>
#include <map>
#include "point.h"
#include <iostream>

using namespace std;

int count_rects(const vector<Point>& points) {
	int answer = 0;
	map<pair<int, int>, int> count;
	for(Point p : points){
		for(Point p_above : points){
			if(p.x == p_above.x && p.y < p_above.y){
				pair<int,int> pair_y{p.y, p_above.y};
				answer += count[pair_y];
				count[pair_y]++;
			}
		}
	}
	return answer;

}

int main(){
	Point p1 {0, 0};
	Point p2 {1, 0};
	Point p3 {2, 0};
	Point p4 {0, 1};
	Point p5 {1, 1};
	Point p6 {2, 1};
	Point p7 {0, 2};
	Point p8 {1, 2};
	Point p9 {2, 2};

	vector<Point> pole {p1,p2,p3,p4,p5,p6, p7,p8,p9};

	int x = count_rects(pole);
	cout << x << endl;
	return 0;
}
