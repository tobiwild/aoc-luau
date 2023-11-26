--!strict
return function(lines: () -> string?)
  local x, y = 1, 1
  local visited = { [`{x}_{y}`] = true }
  local houses = 1

  local x1, y1 = 1, 1
  local x2, y2 = 1, 1
  local visited2 = { [`{x}_{y}`] = true }
  local houses2 = 1
  local robo = false

  for c in string.gmatch(lines() or '', '.') do
    local dx, dy = 0, 0
    if c == '<' then
      dx = -1
    elseif c == '>' then
      dx = 1
    elseif c == '^' then
      dy = -1
    elseif c == 'v' then
      dy = 1
    else
      error(`invalid char {c}`)
    end

    -- part 1
    x += dx
    y += dy
    if not visited[`{x}_{y}`] then
      visited[`{x}_{y}`] = true
      houses += 1
    end

    -- part 2
    if robo then
      x1 += dx
      y1 += dy
      if not visited2[`{x1}_{y1}`] then
        visited2[`{x1}_{y1}`] = true
        houses2 += 1
      end
    else
      x2 += dx
      y2 += dy
      if not visited2[`{x2}_{y2}`] then
        visited2[`{x2}_{y2}`] = true
        houses2 += 1
      end
    end
    robo = not robo
  end

  print(houses)
  print(houses2)
end
