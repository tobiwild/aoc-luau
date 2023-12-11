--!strict
-- https://adventofcode.com/2023/day/10
local lib = require('lib')
type Grid = { { string } }

local function grid_start_pos(g: Grid): lib.Position
  for y, row in g do
    for x, c in row do
      if c == 'S' then
        return lib.Position.new(y, x)
      end
    end
  end
  error('no start')
end

local pipes = {
  -- like CSS margin: starting at top + going clockwise; 1 = connectable
  ['|'] = { 1, 0, 1, 0 },
  ['-'] = { 0, 1, 0, 1 },
  ['L'] = { 1, 1, 0, 0 },
  ['J'] = { 1, 0, 0, 1 },
  ['7'] = { 0, 0, 1, 1 },
  ['F'] = { 0, 1, 1, 0 },
  ['S'] = { 1, 1, 1, 1 },
}

return function(lines: () -> string?)
  local g = {}
  for line in lines do
    local row = {}
    for c in line:gmatch('.') do
      table.insert(row, c)
    end
    table.insert(g, row)
  end
  local visited = {}
  local queue = { { pos = grid_start_pos(g), steps = 0 } }
  local max_steps = 0
  while #queue > 0 do
    local entry = table.remove(queue, 1)
    assert(entry)
    local pos, steps = entry.pos, entry.steps
    max_steps = math.max(max_steps, steps)
    local cpipe = pipes[g[pos.row][pos.col]]
    assert(cpipe)
    visited[pos:key()] = true
    for _, d in { { -1, 0, 4, 2 }, { 1, 0, 2, 4 }, { 0, -1, 1, 3 }, { 0, 1, 3, 1 } } do
      local dcol, drow, i1, i2 = unpack(d)
      local n = pos:delta(drow, dcol)
      if not g[n.row] or not g[n.row][n.col] then
        continue
      end
      local npipe = pipes[g[n.row][n.col]]
      if not npipe then
        continue
      end
      if not visited[n:key()] and cpipe[i1] == 1 and npipe[i2] == 1 then
        table.insert(queue, { pos = n, steps = steps + 1 })
      end
    end
  end
  print(max_steps)
end
