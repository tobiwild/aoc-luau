--!strict
return function(lines: () -> string?)
  local line = lines()
  assert(line ~= nil)
  local part1 = 0
  local pos = 0
  local part2 = -1
  local t = {
    ['('] = 1,
    [')'] = -1,
  }
  for c in string.gmatch(line, '.') do
    pos += 1
    part1 += t[c] or 0
    if part2 == -1 and part1 == -1 then
      part2 = pos
    end
  end
  print(part1)
  print(part2)
end
