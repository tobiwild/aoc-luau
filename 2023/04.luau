--!strict
-- https://adventofcode.com/2023/day/4
local lib = require('../lib')
return function(lines: () -> string?)
  local part1 = 0
  local part2 = 0
  local cards = {}
  local i = 0
  for line in lines do
    i += 1
    local winning_s, own_s = line:match(': (.*) | (.*)')
    assert(winning_s)
    assert(own_s)
    local winning = lib.totable(lib.tonumbers(winning_s))
    local points = 0
    local win_count = 0
    for num in lib.tonumbers(own_s) do
      if table.find(winning, num) then
        win_count += 1
        if points == 0 then
          points = 1
        else
          points *= 2
        end
      end
    end
    part1 += points

    cards[i] = cards[i] or 1
    part2 += cards[i]
    for j = i + 1, i + win_count do
      cards[j] = (cards[j] or 1) + cards[i]
    end
  end
  print(part1)
  print(part2)
end
