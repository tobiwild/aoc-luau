--!strict
-- https://adventofcode.com/2023/day/5
local lib = require('lib')

local function get_location(seed: number, maps: { { { number } } })
  local offset = nil
  for _, map in maps do
    for _, vals in map do
      local dest_start, source_start, range = unpack(vals)
      local max = source_start + range - 1
      if seed >= source_start and seed <= max then
        offset = math.min(offset or math.huge, max - seed)
        seed = dest_start + seed - source_start
        break
      end
    end
  end
  return seed, offset or 0
end

local function part1(seeds: { number }, maps: { { { number } } })
  local result = math.huge
  for _, seed in seeds do
    local loc = get_location(seed, maps)
    result = math.min(result, loc)
  end

  return result
end

local function part2(seeds: { number }, maps: { { { number } } })
  local result = math.huge
  for i = 1, #seeds, 2 do
    local min = seeds[i]
    local max = seeds[i] + seeds[i + 1] - 1
    local seed = min
    while seed <= max do
      -- offset = offset to the max seed leading to the same map usages
      -- and therefore all checks before can be skipped as the resulting
      -- location will be higher
      local loc, offset = get_location(seed, maps)
      result = math.min(result, loc)
      seed += offset + 1
    end
  end
  print(result)
end

return function(lines: () -> string?)
  local seeds: { number } = lib.totable(lib.tonumbers(lines() or ''))

  local maps = {}
  for line in lines do
    if line == '' then
      continue
    end
    if line:match(':') then
      table.insert(maps, {})
      continue
    end
    assert(#maps > 0)
    table.insert(maps[#maps], lib.totable(lib.tonumbers(line)))
  end

  print(part1(seeds, maps))
  print(part2(seeds, maps))
end
