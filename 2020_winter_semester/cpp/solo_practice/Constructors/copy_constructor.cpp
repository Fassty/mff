#include <iostream>
#include <vector>
#include <string>

class Block {
    public:
        std::string name;
        int x, y;

        Block(int x, int y, std::string name):
            x(x), y(y), name(name) {}

};

using grid_row = std::vector<Block>;

class Grid {
    public:
        std::string name;
        std::vector<grid_row> data;

        Grid(std::string name, std::vector<grid_row> data):
            name(name), data(data) {}

};

int main() {
    std::vector<grid_row> data;
    for (int i = 0; i < 2; ++i) {
        grid_row row;
        for (int j = 0; j < 2; ++j) {
            row.push_back(Block(i, j, "Block " + std::to_string(i) + "_" + std::to_string(j)));
        }
        data.push_back(row);
    }

    Grid grid("Grid one", data);
    Grid grid2 = grid;

    grid2.name = "Grid two";

    std::cout << grid.name << std::endl;
    std::cout << grid2.name << std::endl;


    return 0;
}
