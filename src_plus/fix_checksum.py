# Recompute the SNES header checksum for a 6 MB ExLoROM (both header copies).
import sys
p = sys.argv[1]
d = bytearray(open(p, 'rb').read())
assert len(d) == 0x600000
for h in (0x007FDC, 0x407FDC):
    d[h:h+4] = b'\xFF\xFF\x00\x00'
s = (sum(d[:0x400000]) + 2 * sum(d[0x400000:])) & 0xFFFF
for h in (0x007FDC, 0x407FDC):
    d[h:h+4] = ((s ^ 0xFFFF).to_bytes(2, 'little') + s.to_bytes(2, 'little'))
open(p, 'wb').write(d)
print('checksum %04X' % s)
