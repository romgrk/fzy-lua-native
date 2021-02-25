#! /usr/bin/env lua
--
-- test.lua
-- Copyright (C) 2020 romgrk <romgrk@arch>
--
-- Distributed under terms of the MIT license.
--

local export = require'lua.init'

local function print_table(tbl)
  if type(tbl) ~= 'table' then
    print(tbl)
    return
  end
  local result = '{ '
  for k, v in pairs(tbl) do
    result = result .. k .. ' = ' .. tostring(v) .. (i == #tbl and '' or ', ')
  end
  result = result .. ' }'
  print(result)
end

print_table(export)
print_table(export.filter)
