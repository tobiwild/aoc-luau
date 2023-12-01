--!strict
-- https://adventofcode.com/2023/day/1
local trans = {
  one = 1,
  two = 2,
  three = 3,
  four = 4,
  five = 5,
  six = 6,
  seven = 7,
  eight = 8,
  nine = 9,
}

local function find_num(line: string): string?
  for name, num in pairs(trans) do
    if line:find(name, 1, true) then
      return num
    end
  end
  return nil
end

local function get_first(line: string): string
  local cur = ''
  for i = 1, #line do
    local c = line:sub(i, i)
    if c:match('%d') then
      return c
    else
      cur ..= c
      local nc = find_num(cur)
      if nc then
        return nc
      end
    end
  end
  return ''
end

local function get_last(line: string): string
  local cur = ''
  for i = #line, 1, -1 do
    local c = line:sub(i, i)
    if c:match('%d') then
      return c
    else
      cur = c .. cur
      local nc = find_num(cur)
      if nc then
        return nc
      end
    end
  end
  return ''
end

return function(lines: () -> string?)
  local part1 = 0
  local part2 = 0
  for line in lines do
    -- part 1
    do
      local first, last
      for c in line:gmatch('%d') do
        first = first or c
        last = c
      end
      part1 += tonumber(`{first}{last}`) or error('invalid')
    end

    -- part 2
    do
      local first = get_first(line)
      local last = get_last(line)

      part2 += tonumber(`{first}{last}`) or error('invalid')
    end
  end
  print(part1)
  print(part2)
end
