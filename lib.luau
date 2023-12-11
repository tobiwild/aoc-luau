local M = {}

type PositionImpl = {
  __index: PositionImpl,
  new: (row: number, col: number) -> Position,
  key: (self: Position) -> string,
  delta: (self: Position, row: number, col: number) -> Position,
  manhattan: (self: Position, p: Position) -> number,
  __tostring: (self: Position) -> string,
}

export type Position = typeof(setmetatable({} :: { row: number, col: number }, {} :: PositionImpl))

local Position: PositionImpl = {} :: PositionImpl
Position.__index = Position

function Position.new(row, col)
  local self = {}
  self.row = row
  self.col = col
  return setmetatable(self, Position)
end

function Position:key()
  return `row={self.row},col={self.col}`
end

function Position:delta(row, col)
  return Position.new(self.row + row, self.col + col)
end

function Position:manhattan(p: Position)
  return math.abs(self.row - p.row) + math.abs(self.col - p.col)
end

function Position:__tostring()
  return self:key()
end

M.Position = Position

M.inspect = function(o, prefix)
  prefix = prefix or ''
  if type(o) == 'table' and type(o['__tostring']) ~= 'function' then
    for k, v in o do
      M.inspect(v, prefix .. `[{k}] `)
    end
  else
    print(prefix .. tostring(o))
  end
end

M.tonumber = function(value: any, radix: number?): number
  local result = tonumber(value, radix)
  assert(result, `"{value}" is not a number`)
  return result
end

M.tonumbers = function(s: string, radix: number?): () -> (number?, number?, number?)
  local init = 1
  return function()
    local left, right, num_s = string.find(s, '(%d+)', init)
    if not num_s then
      return
    end
    init = right + 1
    return M.tonumber(num_s, radix), left, right
  end
end

M.totable = function<T>(it: () -> T?): { T }
  local t = {}
  for v in it do
    table.insert(t, v)
  end
  return t
end

M.gfind = function(s: string, p: string, sinit: number?, plain: boolean?): () -> (number?, number?, ...string)
  local init = sinit or 1
  return function()
    local res = { string.find(s, p, init, plain) }
    if res[2] then
      init = res[2] + 1
    end
    return unpack(res)
  end
end

return M
