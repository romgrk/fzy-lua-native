-- The fzy matching algorithm
--
-- by Seth Warn <https://github.com/swarn>
-- a lua port of John Hawthorn's fzy <https://github.com/jhawthorn/fzy>
--
-- > fzy tries to find the result the user intended. It does this by favouring
-- > matches on consecutive letters and starts of words. This allows matching
-- > using acronyms or different parts of the path." - J Hawthorn

local has_path, path = pcall(require, 'telescope.path')
if not has_path then
  path = {
    separator = '/'
  }
end


local ffi = require'ffi'

local native = ffi.load('./libfzy.so')

ffi.cdef[[
int has_match(const char *needle, const char *haystack, int is_case_sensitive);

// typedef double score_t;
// match_positions originally returns score_t;
double match_positions(const char *needle, const char *haystack, uint32_t *positions, int is_case_sensitive);

]]

-- local needle = 'fil'
-- local haystack = '_file_'
-- 
-- print(native.has_match(needle, haystack, false))
-- 
-- local positions_len = #needle
-- local positions = ffi.new('uint32_t[' .. positions_len .. ']', {})
-- 
-- print(native.match_positions(needle, haystack, positions, false))
-- 
-- local positions_string = '{ '
-- for i = 0, positions_len - 1, 1  do
--   positions_string = positions_string .. tostring(positions[i]) .. ', '
-- end
-- positions_string = positions_string .. ' }'
-- print(positions_string)

local SCORE_GAP_LEADING = -0.005
local SCORE_GAP_TRAILING = -0.005
local SCORE_GAP_INNER = -0.01
local SCORE_MATCH_CONSECUTIVE = 1.0
local SCORE_MATCH_SLASH = 0.9
local SCORE_MATCH_WORD = 0.8
local SCORE_MATCH_CAPITAL = 0.7
local SCORE_MATCH_DOT = 0.6
local SCORE_MAX = math.huge
local SCORE_MIN = -math.huge
local MATCH_MAX_LENGTH = 1024

local fzy = {}

function fzy.has_match(needle, haystack)
  local is_case_sensitive = false
  return native.has_match(needle, haystack, is_case_sensitive) == 1
end

function fzy.score(needle, haystack)
  -- TBD
end

local function positions_to_lua(positions, length)
  local result = {}
  for i = 0, length - 1, 1  do
    table.insert(result, positions[i])
  end
  return result
end

function fzy.positions(needle, haystack)
  local length = #needle
  local positions = ffi.new('uint32_t[' .. length .. ']', {})
  local is_case_sensitive = false

  -- TODO: return score
  local score = native.match_positions(needle, haystack, positions, is_case_sensitive)

  local result = positions_to_lua(positions, length)

  return result
end



-- If strings a or b are empty or too long, `fzy.score(a, b) == fzy.get_score_min()`.
function fzy.get_score_min()
  return SCORE_MIN
end

-- For exact matches, `fzy.score(s, s) == fzy.get_score_max()`.
function fzy.get_score_max()
  return SCORE_MAX
end

-- For all strings a and b that
--  - are not covered by either `fzy.get_score_min()` or fzy.get_score_max()`, and
--  - are matched, such that `fzy.has_match(a, b) == true`,
-- then `fzy.score(a, b) > fzy.get_score_floor()` will be true.
function fzy.get_score_floor()
  return (MATCH_MAX_LENGTH + 1) * SCORE_GAP_INNER
end


function fzy.filter(needle, lines)
  results = {}

  for i = 1, #lines do
    local line = lines[i]
    if native.has_match(needle, line, false) == 1 then
      local positions = fzy.positions(needle, line)
      table.insert(results, { line, positions })
    end
  end
  return results
end

return fzy
