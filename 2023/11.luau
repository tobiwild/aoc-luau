--!strict
-- https://adventofcode.com/2023/day/11
local lib = require('../lib')
local function get_sum(lines: { string }, expand: number)
  local galaxies = {}
  local empty_cols = {}
  for col = 1, #lines[1] do
    local empty = true
    for row = 1, #lines do
      if lines[row]:sub(col, col) == '#' then
        empty = false
        break
      end
    end
    if empty then
      empty_cols[col] = true
    end
  end
  local row_offset = 0
  for row, line in lines do
    local col_offset = 0
    local empty_row = true
    local col = 0
    for c in line:gmatch('.') do
      col += 1
      if empty_cols[col] then
        col_offset += expand
      end
      if c == '#' then
        empty_row = false
        table.insert(galaxies, lib.Position.new(row + row_offset, col + col_offset))
      end
    end
    if empty_row then
      row_offset += expand
    end
  end
  local sum = 0
  for _, g1 in galaxies do
    for _, g2 in galaxies do
      sum += g1:manhattan(g2)
    end
  end
  return sum // 2
end

return function(it: () -> string?)
  local lines: { string } = lib.totable(it)

  print(get_sum(lines, 1))
  print(get_sum(lines, 999_999))
end
