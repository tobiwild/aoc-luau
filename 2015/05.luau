--!strict

-- It contains at least three vowels (aeiou only), like aei, xazegov, or aeiouaeiouaeiou.
-- It contains at least one letter that appears twice in a row, like xx, abcdde (dd), or aabbccdd (aa, bb, cc, or dd).
-- It does not contain the strings ab, cd, pq, or xy, even if they are part of one of the other requirements.
local function valid1(line: string)
  local vowels = 0
  local dupl = false
  local prev = ''
  for c in line:gmatch('.') do
    if c:match('[aeiou]') then
      vowels += 1
    end
    if c == prev then
      dupl = true
    end
    prev = c
  end
  if vowels < 3 then
    return false
  end
  if not dupl then
    return false
  end
  for _, pair in { 'ab', 'cd', 'pq', 'xy' } do
    if line:match(pair) then
      return false
    end
  end
  return true
end

-- It contains a pair of any two letters that appears at least twice in the string without overlapping, like xyxy (xy) or aabcdefgaa (aa), but not like aaa (aa, but it overlaps).
-- It contains at least one letter which repeats with exactly one letter between them, like xyx, abcdefeghi (efe), or even aaa.
local function valid2(line: string)
  local dupl_no_overlap = false
  local dupl_one_in_between = false

  local seen = {}
  local pair = ''
  local prev = ''
  local prev2 = ''
  local next_pair = ''
  for c in line:gmatch('.') do
    pair = prev .. c

    if seen[pair] then
      dupl_no_overlap = true
    end
    -- delay insert by one iteration to no overlap
    seen[next_pair] = true
    next_pair = pair

    if c == prev2 then
      dupl_one_in_between = true
    end

    prev2 = prev
    prev = c
  end

  return dupl_no_overlap and dupl_one_in_between
end

return function(lines: () -> string?)
  local part1 = 0
  local part2 = 0
  for line in lines do
    if valid1(line) then
      part1 += 1
    end
    if valid2(line) then
      part2 += 1
    end
  end
  print(part1)
  print(part2)
end
