--
-- example.lua
-- Copyright (C) 2020 romgrk <romgrk@arch>
--
-- Distributed under terms of the MIT license.
--

local native = require'native'

local positions = native.positions('pé', 'spécial')

for i, p in ipairs(positions) do
  print(p)
end
