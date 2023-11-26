--!strict
return function(lines: () -> string?)
  local paper = 0
  local ribbon = 0
  for line in lines do
    local d: { number } = {}
    for num in line:gmatch('%d+') do
      table.insert(d, tonumber(num) or 0)
    end
    table.sort(d)
    paper += 2 * d[1] * d[2] + 2 * d[1] * d[3] + 2 * d[2] * d[3]
    paper += d[1] * d[2]
    ribbon += 2 * d[1] + 2 * d[2]
    ribbon += d[1] * d[2] * d[3]
  end
  print(paper)
  print(ribbon)
end
