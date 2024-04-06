--!strict
-- https://adventofcode.com/2016/day/6
return function(lines: () -> string?)
  local nums = {}
  for line in lines do
    local i = 0
    for c in line:gmatch('.') do
      i += 1
      nums[i] = nums[i] or {}
      nums[i][c] = (nums[i][c] or 0) + 1
    end
  end

  local least = ''
  local most = ''
  for _, num in nums do
    local min = math.huge
    local max = 0
    local cur_least = ''
    local cur_most = ''
    for c, i in num do
      if i < min then
        min = i
        cur_least = c
      end
      if i > max then
        max = i
        cur_most = c
      end
    end
    least ..= cur_least
    most ..= cur_most
  end
  print(most)
  print(least)
end
