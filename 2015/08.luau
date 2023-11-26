--!strict
return function(lines: () -> string?)
  local part1 = 0
  local part2 = 0
  for line in lines do
    -- Alternative:
    -- local decoded = loadstring(`return {line}`)
    -- if decoded then
    --   print(decoded())
    -- end
    local slash = false
    local dec = ''
    local hex: string? = nil
    part2 += 4
    for i = 2, line:len() - 1 do
      local c = line:sub(i, i)
      if c == '\\' or c == '"' then
        part2 += 1
      end
      if hex then
        if c:match('[0-9a-fA-F]') then
          hex ..= c
          if hex:len() == 2 then
            local code = tonumber(hex, 16) or error('invalid hex')
            dec ..= ('%c'):format(code)
            hex = nil
          end
          continue
        end
        error(`invalid hex char {c}`)
      end
      if slash then
        slash = false
        if c == '\\' then
          dec ..= c
          continue
        end
        if c == '"' then
          dec ..= c
          continue
        end
        if c == 'x' then
          hex = ''
          continue
        end
        error(`unexpected char {c}`)
      end
      if c == '\\' then
        slash = true
        continue
      end
      dec ..= c
    end
    part1 += line:len() - dec:len()
  end
  print(part1)
  print(part2)
end
