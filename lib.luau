local M = {}

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
