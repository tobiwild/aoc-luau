--!strict
-- https://adventofcode.com/2023/day/12

local lib = require('../lib')
local function is_valid(springs: string, sizes: { number })
  local i = 0
  for group in springs:gmatch('#+') do
    i += 1
    if sizes[i] ~= #group then
      return false
    end
  end
  return i == #sizes
end

return function(lines: () -> string?)
  local valid_count = 0
  for line in lines do
    local parts = line:split(' ')
    assert(#parts == 2)
    local springs = parts[1]
    local sizes: { number } = lib.totable(lib.tonumbers(parts[2]))

    local variant = 0

    while true do
      local new_springs = springs
      local count = 0
      for i in lib.gfind(springs, '?') do
        local r = '.'
        if bit32.band(variant, 2 ^ count) == 2 ^ count then
          r = '#'
        end
        count += 1
        new_springs = new_springs:sub(1, i - 1) .. r .. new_springs:sub(i + 1)
      end
      if is_valid(new_springs, sizes) then
        -- print(' ', new_springs, 'VALID')
        valid_count += 1
        -- else
        -- print(' ', new_springs, 'INVALID')
      end
      if variant >= 2 ^ count - 1 then
        break
      end
      variant += 1
    end
  end
  print(valid_count)
end
