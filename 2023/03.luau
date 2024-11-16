--!strict
-- https://adventofcode.com/2023/day/3
local lib = require('../lib')

type Grid = { string }

local function grid_parse(lines: () -> string?): Grid
  local grid = {}
  for line in lines do
    table.insert(grid, line)
  end
  return grid
end

type Num = { val: number, y: number, x1: number, x2: number }

local function grid_nums(g: Grid): { Num }
  local result = {}

  for y, row in g do
    for num, x1, x2 in lib.tonumbers(row) do
      assert(x1)
      assert(x2)
      table.insert(result, { val = lib.tonumber(num), y = y, x1 = x1, x2 = x2 })
    end
  end

  return result
end

local function has_adjacent_symbol(g: Grid, n: Num)
  for _, dy in { -1, 0, 1 } do
    local y = n.y + dy
    if not g[y] then
      continue
    end
    for x = n.x1 - 1, n.x2 + 1 do
      local c = g[y]:sub(x, x)
      if c == '' then
        continue
      end
      -- we check the number itself, but result is still correct
      if not c:match('[%d.]') then
        return true
      end
    end
  end
  return false
end

local function get_nums_adjacent_to(x: number, y: number, nums: { Num }): { Num }
  local result = {}
  for _, num in nums do
    if math.abs(y - num.y) <= 1 and x >= num.x1 - 1 and x <= num.x2 + 1 then
      table.insert(result, num)
    end
  end
  return result
end

local function get_gear_ratio_sum(g: Grid, nums: { Num })
  local result = 0

  for y, row in g do
    local x = 0
    for c in row:gmatch('.') do
      x += 1
      if c == '*' then
        local adj = get_nums_adjacent_to(x, y, nums)
        assert(#adj < 3)
        if #adj == 2 then
          result += adj[1].val * adj[2].val
        end
      end
    end
  end

  return result
end

return function(lines: () -> string?)
  local g = grid_parse(lines)
  local part1 = 0
  local nums = grid_nums(g)
  for _, num in nums do
    if has_adjacent_symbol(g, num) then
      part1 += num.val
    end
  end
  local part2 = get_gear_ratio_sum(g, nums)
  print(part1)
  print(part2)
end
