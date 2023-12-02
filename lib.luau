local M = {}

M.tonumber = function(value: any, radix: number?): number
  local result = tonumber(value, radix)
  assert(result ~= nil, `"{value}" is not a number`)
  return result
end

return M
