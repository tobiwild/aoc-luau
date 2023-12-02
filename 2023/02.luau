--!strict
-- https://adventofcode.com/2023/day/2
local lib = require('lib')

local bag = {
  red = 12,
  green = 13,
  blue = 14,
}

local function is_possible(desc: string)
  for num_s, color in desc:gmatch('(%d+) (%w+)') do
    local num = lib.tonumber(num_s)
    assert(bag[color])
    if num > bag[color] then
      return false
    end
  end

  return true
end

local function get_power(desc: string)
  local required = {}
  for num_s, color in desc:gmatch('(%d+) (%w+)') do
    local num = lib.tonumber(num_s)
    required[color] = math.max(required[color] or 0, num)
  end

  local res = 1
  for _, val in required do
    res *= val
  end
  return res
end

return function(lines: () -> string?)
  local part1 = 0
  local part2 = 0
  for line in lines do
    local game_string, desc = line:match('Game (%d+): (.*)')
    local game = lib.tonumber(game_string)
    assert(desc)
    if is_possible(desc) then
      part1 += game
    end
    part2 += get_power(desc)
  end
  print(part1)
  print(part2)
end
