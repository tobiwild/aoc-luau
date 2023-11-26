--!strict
local cache = {}
local function run(list: { [string]: string }, ins: string): number
  if cache[ins] then
    return cache[ins]
  end
  if ins:match('^%d+$') then
    return tonumber(ins) or error('invalid')
  end
  if list[ins] then
    cache[list[ins]] = run(list, list[ins])
    return cache[list[ins]]
  end
  local v = ins:match('^NOT (%w+)')
  if v ~= nil then
    local n = run(list, v)
    return bit32.band(bit32.bnot(n), 65535)
  end

  local v1, op, v2 = ins:match('(%w+) (%u+) (%w+)')
  assert(op ~= nil)
  assert(v1 ~= nil)
  assert(v2 ~= nil)

  local n1 = run(list, v1)
  local n2 = run(list, v2)

  if op == 'AND' then
    return bit32.band(n1, n2)
  end

  if op == 'OR' then
    return bit32.bor(n1, n2)
  end

  if op == 'LSHIFT' then
    return bit32.lshift(n1, n2)
  end

  if op == 'RSHIFT' then
    return bit32.rshift(n1, n2)
  end

  error(`invalid op: {op}`)
end

return function(lines: () -> string?)
  local instructions = {}
  for line in lines do
    local instruction, output = line:match('(.*) %-> (.*)')
    assert(instruction ~= nil)
    assert(output ~= nil)
    instructions[output] = instruction
  end
  local part1 = run(instructions, 'a')
  print(part1)
  cache = {}
  instructions.b = tostring(part1)
  local part2 = run(instructions, 'a')
  print(part2)
end
