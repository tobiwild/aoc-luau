--!strict
type PositionImpl = {
  __index: PositionImpl,
  new: (row: number, col: number) -> Position,
  unkey: (key: string) -> Position,
  key: (self: Position) -> string,
  delta: (self: Position, row: number, col: number) -> Position,
  manhattan: (self: Position, p: Position) -> number,
  __tostring: (self: Position) -> string,
}

export type Position = typeof(setmetatable({} :: { row: number, col: number }, {} :: PositionImpl))

local Position: PositionImpl = {} :: PositionImpl
Position.__index = Position

local M = {
  Position = Position,
}

function Position.new(row, col)
  local self = {}
  self.row = row
  self.col = col
  return setmetatable(self, Position)
end

function Position.unkey(key: string)
  local row_s, col_s = key:match('(%d+),(%d+)')
  local row = M.tonumber(row_s)
  local col = M.tonumber(col_s)
  return Position.new(row, col)
end

function Position:key()
  return `{self.row},{self.col}`
end

function Position:delta(row, col)
  return Position.new(self.row + row, self.col + col)
end

function Position:manhattan(p: Position)
  return math.abs(self.row - p.row) + math.abs(self.col - p.col)
end

function Position:__tostring()
  return `row={self.row},col={self.col}`
end

M.inspect = function(o: any, prefix: any)
  if type(o) == 'table' and type(o['__tostring']) ~= 'function' then
    for k, v in o do
      M.inspect(v, (prefix or '') .. `[{k}] `)
    end
  else
    print((prefix or '') .. tostring(o))
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
    assert(right)
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
    local res = { string.find(s, p, init, plain) } :: { any }
    init = (res[2] or 0) + 1
    return unpack(res)
  end
end

return M
