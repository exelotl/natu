local f = io.open(arg[1], "r+b")
assert(f, "File not found, read only, or invalid command line")
local hdr = f:read(0xBD)
assert(#hdr == 0xBD and hdr:sub(5, 8) == "\36\255\174\81"
       and hdr:byte(0xB2) ~= 0x96, "Invalid file format, not a GBA raw ROM")

local sum = 0xE7
for i = 0xA1, 0xBD do
  sum = (sum - hdr:byte(i)) % 256
end
f:write(string.char(sum))
