--
-- benchmark.lua
-- Copyright (C) 2020 romgrk <romgrk@arch>
--
-- Distributed under terms of the MIT license.
--

local original = require'lua.original'
local native   = require'lua.native'

local function lines_from(file)
  lines = {}
  for line in io.lines(file) do 
    lines[#lines + 1] = line
  end
  return lines
end

function benchmark(fn)
  local total = 0
  -- Warmup
  for i = 1, 5 do
    total = total + #fn()
  end

  local start = os.clock()
  total = 0
  for i = 1, 1 do
    total = total + #fn()
  end
  local end_ = os.clock()
  return (end_ - start) * 1000, total
end

function main()

  local lines = lines_from('./tests/files.txt')

  print('Lines: ' .. #lines)
  print('')

  local time, total = benchmark(function() return native.filter('f', lines) end)
  print('Native:')
  print(' -> Total: ' .. total)
  print(' -> Time:  ' .. time .. ' ms')

  local time, total = benchmark(function() return native.filter_many('f', lines) end)
  print('Native (many):')
  print(' -> Total: ' .. total)
  print(' -> Time:  ' .. time .. ' ms')

  local time, total = benchmark(function() return original.filter('f', lines) end)
  print('Original:')
  print(' -> Total: ' .. total)
  print(' -> Time:  ' .. time .. ' ms')
end

main()
