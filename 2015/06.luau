--!strict
return function(lines: () -> string?)
  local lights = {}
  local brightness = {}
  for line in lines do
    local action, x1s, y1s, x2s, y2s = line:match('(.*) (%d+),(%d+) through (%d+),(%d+)')
    local x1, y1, x2, y2 = tonumber(x1s), tonumber(y1s), tonumber(x2s), tonumber(y2s)
    assert(action ~= nil)
    assert(x1 ~= nil)
    assert(y1 ~= nil)
    assert(x2 ~= nil)
    assert(y2 ~= nil)
    for x = x1, x2 do
      for y = y1, y2 do
        local key = `{x}_{y}`
        local b = brightness[key] or 0
        local on = false
        if action == 'turn on' then
          on = true
          b += 1
        elseif action == 'turn off' then
          on = false
          b -= 1
        elseif action == 'toggle' then
          on = not lights[key]
          b += 2
        else
          error('invalid action')
        end
        lights[key] = on
        if b < 0 then
          b = 0
        end
        brightness[key] = b
      end
    end
  end
  local lights_on = 0
  for _, on in lights do
    if on then
      lights_on += 1
    end
  end
  local total_brightness = 0
  for _, b in brightness do
    total_brightness += b
  end
  print(lights_on)
  print(total_brightness)
end
