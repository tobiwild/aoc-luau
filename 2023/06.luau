--!strict
-- https://adventofcode.com/2023/day/6
local lib = require('lib')

local function _solve_simple(times: { number }, distances: { number })
  assert(#times > 0)
  assert(#times == #distances)
  local result = 1
  for i, time in times do
    local distance = distances[i]
    local wins = 0
    for t = 1, time do
      local d = (time - t) * t
      if d > distance then
        wins += 1
      end
    end
    result *= wins
  end
  return result
end

local function solve_binary_search(times: { number }, distances: { number })
  assert(#times > 0)
  assert(#times == #distances)
  local result = 1
  for i, time in times do
    local distance = distances[i]
    local left = 0
    local right = time // 2
    while left <= right do
      local t1 = (left + right) // 2
      local t2 = time - t1
      local d = t1 * t2
      if d <= distance then
        left = t1 + 1
      else
        right = t1 - 1
      end
    end
    local wins = ((time // 2) - right) * 2
    if wins > 0 and time % 2 == 0 then
      wins -= 1
    end
    result *= wins
  end
  return result
end

return function(it: () -> string?)
  local lines = lib.totable(it)

  -- part1
  do
    local times = lib.totable(lib.tonumbers(lines[1]))
    local distances = lib.totable(lib.tonumbers(lines[2]))
    print(solve_binary_search(times, distances))
  end

  -- part2
  do
    local times = lib.totable(lib.tonumbers((select(1, lines[1]:gsub('%s', '')))))
    local distances = lib.totable(lib.tonumbers((select(1, lines[2]:gsub('%s', '')))))
    print(solve_binary_search(times, distances))
  end
end
