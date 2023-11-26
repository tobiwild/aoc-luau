# Advent of Code in [Luau](https://luau-lang.org/)

## Usage

```sh
# Compile
git clone https://github.com/luau-lang/luau
make -C luau config=release luau luau-analyze
cmake -S . -B build
make -C build

# Solve puzzle
./build/solve 2015/01.luau 2015/01.my.in

# Solve puzzle and check output against 2015/01.my.out
# (automatically using 2015/01.luau)
./test.sh 2015/01.my.in

# Solve puzzle and (w)rite 2015/01.my.out if not available
./test.sh -w 2015/01.my.in

# Solve puzzle and (o)verride 2015/01.my.out
./test.sh -o 2015/01.my.in

# Run tests for all *.in files
./test.sh

# Edit/Create Luau script and download input
./edit 2015 1
```
