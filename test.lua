#! /usr/bin/env luajit
--
-- test.lua
-- Copyright (C) 2020 romgrk <romgrk@arch>
--
-- Distributed under terms of the MIT license.
--

local export = require'lua.native'

local function assert(val, msg)
  if not val then
    error(msg)
  end
end

local prompt = "f"

local CASES = {
  "foo",
  "bar",
  "baz",
  "barf"
}

local results = export.match_many(prompt, CASES, false)

for _, r in ipairs(results) do
  local score = export.score(prompt, r[1])
  assert(r[2] == score, string.format("%s: %s != %s", r[1], tostring(score), tostring(r[2])))
end
