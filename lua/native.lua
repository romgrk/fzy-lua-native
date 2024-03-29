-- The fzy matching algorithm
--
-- by Seth Warn <https://github.com/swarn>
-- a lua port of John Hawthorn's fzy <https://github.com/jhawthorn/fzy>
--
-- > fzy tries to find the result the user intended. It does this by favouring
-- > matches on consecutive letters and starts of words. This allows matching
-- > using acronyms or different parts of the path." - J Hawthorn

local os_aliases = {
  ['osx'] = 'darwin',
}

local arch_aliases = {
  ['x64'] = 'x86_64',

  -- Linux `uname -m` returns 'aarch64'
  -- macOS `uname -m` returns 'arm64'
  -- jit.arch returns 'arm64' always
  -- Therefore let's use 'arm64'
  -- ['arm64'] = 'aarch64',
}

local ffi = require'ffi'

local os   = (os_aliases[jit.os:lower()] or jit.os:lower())
local arch = (arch_aliases[jit.arch:lower()] or jit.arch:lower())


-- ffi.load() doesn't respect anything but the actual path OR a system library path
local dirname = string.sub(debug.getinfo(1).source, 2, string.len('/native.lua') * -1)
local library_path = dirname .. '../static/libfzy-' .. os .. '-' .. arch .. '.so'

local native = ffi.load(library_path)

ffi.cdef[[
int has_match(const char *needle, const char *haystack, int is_case_sensitive);

// typedef double score_t;
// match* originally returns score_t;

double match(const char *needle, const char *haystack, int is_case_sensitive);
void match_many(const char *needle,
    const char **haystacks,
    uint32_t length,
    double *scores,
    int is_case_sensitive
  );

double match_positions(const char *needle, const char *haystack, uint32_t *positions, int is_case_sensitive);
void match_positions_many(
  const char *needle,
  const char **haystacks,
  uint32_t length,
  double *scores,
  uint32_t *positions,
  int is_case_sensitive);

]]

-- @param positions - the C positions object
-- @param length - length of positions
-- @returns - lua array of positions, 1-indexed
local function positions_to_lua(positions, length)
  local result = {}
  for i = 0, length - 1, 1  do
    result[i + 1] = positions[i] + 1
  end
  return result
end

local function positions_to_lua_many(numbers, length, n)
  local result = {}
  local current = {}
  for i = 0, length - 1, 1  do
    table.insert(current, numbers[i] + 1)
    if #current == n then
      table.insert(result, current)
      current = {}
    end
  end
  return result
end

-- @param scores - the C positions object
-- @param length - length of scores
-- @returns - lua array of scores, 1-indexed
local function scores_to_lua_many(scores, length)
  local result = {}
  for i = 0, length - 1, 1  do
    result[i + 1] = scores[i] + 1
  end
  return result
end

-- Constants

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

function fzy.has_match(needle, haystack, is_case_sensitive)
  is_case_sensitive = is_case_sensitive or false
  return native.has_match(needle, haystack, is_case_sensitive) == 1
end

function fzy.score(needle, haystack, is_case_sensitive)
  is_case_sensitive = is_case_sensitive or false
  local score = native.match(needle, haystack, is_case_sensitive)
  return score + 1
end

function fzy.match_many(needle, lines, is_case_sensitive)
  is_case_sensitive = is_case_sensitive or false
  local filtered_lines = {}

  for i = 1, #lines do
    local line = lines[i]
    if native.has_match(needle, line, is_case_sensitive) == 1 then
      filtered_lines[#filtered_lines + 1] = line
    end
  end

  local length = #filtered_lines
  local scores = ffi.new('double[' .. (length) .. ']', {})
  local haystacks_arg = ffi.new("const char*[" .. (length + 1) .. "]", filtered_lines)
  native.match_many(
    needle,
    haystacks_arg,
    length,
    scores,
    is_case_sensitive)

  -- Now build up the scores / lines array
  for i = 1, length do
    filtered_lines[i] = { filtered_lines[i], scores[i - 1] + 1 }
  end

  return filtered_lines
end

function fzy.positions(needle, haystack, is_case_sensitive)
  local length = #needle
  local positions = ffi.new('uint32_t[' .. length .. ']', {})
  is_case_sensitive = is_case_sensitive or false

  local score = native.match_positions(needle, haystack, positions, is_case_sensitive)

  return positions_to_lua(positions, length), score
end

function fzy.positions_many(needle, haystacks, is_case_sensitive)
  local n = #needle
  local length = #haystacks
  local scores = ffi.new('double[' .. (length) .. ']', {})
  local positions = ffi.new('uint32_t[' .. (n * length) .. ']', {})
  is_case_sensitive = is_case_sensitive or false

  local haystacks_arg = ffi.new("const char*[" .. (length + 1) .. "]", haystacks)

  native.match_positions_many(
    needle,
    haystacks_arg,
    length,
    scores,
    positions,
    is_case_sensitive)

  local result = {}
  for i = 0, length - 1, 1  do
    local current = {}
    for j = 0, n - 1 do
      current[j+1] = positions[i * n + j] + 1
    end
    result[i+1] = { haystacks[i + 1], current, scores[i] + 1 }
  end
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


function fzy.filter(needle, lines, is_case_sensitive)
  is_case_sensitive = is_case_sensitive or false
  local results = {}

  for i = 1, #lines do
    local line = lines[i]
    if native.has_match(needle, line, is_case_sensitive) == 1 then
      local positions, score = fzy.positions(needle, line, is_case_sensitive)
      table.insert(results, { line, positions, score })
    end
  end
  return results
end

function fzy.filter_many(needle, lines, is_case_sensitive)
  is_case_sensitive = is_case_sensitive or false
  local filtered_lines = {}

  for i = 1, #lines do
    local line = lines[i]
    if native.has_match(needle, line, is_case_sensitive) == 1 then
      table.insert(filtered_lines, line)
    end
  end

  return fzy.positions_many(needle, filtered_lines)
end

return fzy
