
# fzy-lua-native

Luajit FFI bindings to FZY.

### Building

`make`

### Running

`luajit benchmark.lua`

Results:
```
Lines: 100000

Native:
 -> Total: 34130
 -> Time:  69.418 ms
Original:
 -> Total: 34130
 -> Time:  835.683 ms
```

### Notes

The C version of fzy in that repo contains 2 differences with the original:

 - the functions take a `is_case_sensitive` additional parameters that does
   what you think. It's a parameter rather than computed in the function
   because for our use-case, you want to compute `is_case_sensitive` once
   for needle, instead of on each iteration of the loop.
 - `match_positions` uses `uint32_t` for positions, because `size_t`
   (`uint64_t`) doesn't map well to lua types.
