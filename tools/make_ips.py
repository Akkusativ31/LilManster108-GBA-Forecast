# Make an IPS patch from two same-size ROMs, then verify it by applying it.
import sys
src, dst, out = sys.argv[1:4]
a = open(src, 'rb').read(); b = open(dst, 'rb').read()
assert len(a) == len(b) and len(a) < 0x1000000
recs = []; i = 0
while i < len(a):
    if a[i] == b[i]:
        i += 1; continue
    j = i
    # extend over short runs of equal bytes to save record overhead
    while j < len(a) and j - i < 0xFFFF and (a[j] != b[j] or b[j:j+6] != a[j:j+6]):
        j += 1
    if i == 0x454F46:  # 'EOF' offset would end the patch early
        i -= 1
    recs.append((i, b[i:j])); i = j
p = bytearray(b'PATCH')
for off, data in recs:
    p += off.to_bytes(3, 'big') + len(data).to_bytes(2, 'big') + data
p += b'EOF'
open(out, 'wb').write(p)
# verify
r = bytearray(a); k = 5
while p[k:k+3] != b'EOF':
    off = int.from_bytes(p[k:k+3], 'big'); n = int.from_bytes(p[k+3:k+5], 'big'); k += 5
    r[off:off+n] = p[k:k+n]; k += n
print('records', len(recs), 'size', len(p), 'verified', bytes(r) == b)
