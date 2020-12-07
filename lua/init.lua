#! /usr/bin/env lua
--
-- init.lua
-- Copyright (C) 2020 romgrk <romgrk@arch>
--
-- Distributed under terms of the MIT license.
--

local sep = package.config:sub(1, 1)
local dirname = string.sub(debug.getinfo(1).source, 2, string.len('/init.lua') * -1)

local original_path = dirname .. sep .. 'original.lua'
local native_path   = dirname .. sep .. 'native.lua'

print('original: ' .. original_path)
print('native:   ' .. native_path)

local implementation = dofile(original_path)

print('Loaded original')

local fn, err = loadfile(native_path)
print('Err: ' .. tostring(err))
if err == nil then
  local ok, result = pcall(fn)
  print('Ok: ' .. tostring(ok))
  print('Result: ' .. tostring(result))
  if ok then
    implementation = result
    print('Loaded native')
  end
end

print('imp: ' .. tostring(implementation))
return implementation
