#!/usr/bin/env python3
"""Minimal 65816 disassembler for the 6MB ExLoROM.
usage: dis.py ROM SNESADDR COUNT [m] [x]   (m/x = 8 for 8-bit, default 16)"""
import sys

ops = {}
def d(op, mn, mode): ops[op] = (mn, mode)
# group 1 (ora and eor adc sta lda cmp sbc)
g1 = ['ora', 'and', 'eor', 'adc', 'sta', 'lda', 'cmp', 'sbc']
modes1 = {0x01: 'dpxi', 0x03: 'sr', 0x05: 'dp', 0x07: 'dpil', 0x09: 'imm_m', 0x0D: 'abs', 0x0F: 'long',
          0x11: 'dpiy', 0x12: 'dpi', 0x13: 'sriy', 0x15: 'dpx', 0x17: 'dpily', 0x19: 'absy', 0x1D: 'absx', 0x1F: 'longx'}
for i, mn in enumerate(g1):
    for lo, mo in modes1.items():
        if mn == 'sta' and lo == 0x09: continue
        d(i * 0x20 + lo, mn, mo)
tbl = """
00 brk imm8;02 cop imm8;04 tsb dp;06 asl dp;08 php imp;0A asl acc;0B phd imp;0C tsb abs;0E asl abs
10 bpl rel;14 trb dp;16 asl dpx;18 clc imp;1A inc acc;1B tcs imp;1C trb abs;1E asl absx
20 jsr abs;22 jsl long;24 bit dp;26 rol dp;28 plp imp;2A rol acc;2B pld imp;2C bit abs;2E rol abs
30 bmi rel;34 bit dpx;36 rol dpx;38 sec imp;3A dec acc;3B tsc imp;3C bit absx;3E rol absx
40 rti imp;42 wdm imm8;44 mvp mv;46 lsr dp;48 pha imp;4A lsr acc;4B phk imp;4C jmp abs;4E lsr abs
50 bvc rel;54 mvn mv;56 lsr dpx;58 cli imp;5A phy imp;5B tcd imp;5C jml long;5E lsr absx
60 rts imp;62 per rell;64 stz dp;66 ror dp;68 pla imp;6A ror acc;6B rtl imp;6C jmp absi;6E ror abs
70 bvs rel;74 stz dpx;76 ror dpx;78 sei imp;7A ply imp;7B tdc imp;7C jmp absxi;7E ror absx
80 bra rel;82 brl rell;84 sty dp;86 stx dp;88 dey imp;89 bit imm_m;8A txa imp;8B phb imp;8C sty abs;8E stx abs
90 bcc rel;94 sty dpx;96 stx dpy;98 tya imp;9A txs imp;9B txy imp;9C stz abs;9E stz absx
A0 ldy imm_x;A2 ldx imm_x;A4 ldy dp;A6 ldx dp;A8 tay imp;AA tax imp;AB plb imp;AC ldy abs;AE ldx abs
B0 bcs rel;B4 ldy dpx;B6 ldx dpy;B8 clv imp;BA tsx imp;BB tyx imp;BC ldy absx;BE ldx absy
C0 cpy imm_x;C2 rep imm8;C4 cpy dp;C6 dec dp;C8 iny imp;CA dex imp;CB wai imp;CC cpy abs;CE dec abs
D0 bne rel;D4 pei dp;D6 dec dpx;D8 cld imp;DA phx imp;DB stp imp;DC jml absil;DE dec absx
E0 cpx imm_x;E2 sep imm8;E4 cpx dp;E6 inc dp;E8 inx imp;EA nop imp;EB xba imp;EC cpx abs;EE inc abs
F0 beq rel;F4 pea abs;F6 inc dpx;F8 sed imp;FA plx imp;FB xce imp;FC jsr absxi;FE inc absx
"""
for ent in tbl.replace('\n', ';').split(';'):
    ent = ent.strip()
    if ent:
        a, b, c = ent.split(); d(int(a, 16), b, c)
assert len(ops) == 256, len(ops)


def f(addr):
    b, o = addr >> 16, addr & 0xFFFF
    if b >= 0x80: return (b - 0x80) * 0x8000 + (o - 0x8000)
    return 0x400000 + b * 0x8000 + (o - 0x8000)


def dis(rom, addr, n, m=16, x=16, out=print):
    for _ in range(n):
        p = f(addr); op = rom[p]; mn, mode = ops[op]
        size = {'imp': 1, 'acc': 1, 'imm8': 2, 'dp': 2, 'dpx': 2, 'dpy': 2, 'dpi': 2, 'dpxi': 2, 'dpiy': 2, 'dpil': 2,
                'dpily': 2, 'sr': 2, 'sriy': 2, 'rel': 2, 'abs': 3, 'absx': 3, 'absy': 3, 'absi': 3, 'absxi': 3,
                'absil': 3, 'rell': 3, 'mv': 3, 'long': 4, 'longx': 4,
                'imm_m': 2 if m == 8 else 3, 'imm_x': 2 if x == 8 else 3}[mode]
        bs = rom[p:p + size]; v = int.from_bytes(bs[1:], 'little')
        fm = {'imp': '', 'acc': 'a', 'imm8': '#$%02X' % v, 'imm_m': '#$%0*X' % (2 * (size - 1), v),
              'imm_x': '#$%0*X' % (2 * (size - 1), v), 'dp': '$%02X' % v, 'dpx': '$%02X,x' % v, 'dpy': '$%02X,y' % v,
              'dpi': '($%02X)' % v, 'dpxi': '($%02X,x)' % v, 'dpiy': '($%02X),y' % v, 'dpil': '[$%02X]' % v,
              'dpily': '[$%02X],y' % v, 'sr': '$%02X,s' % v, 'sriy': '($%02X,s),y' % v, 'abs': '$%04X' % v,
              'absx': '$%04X,x' % v, 'absy': '$%04X,y' % v, 'absi': '($%04X)' % v, 'absxi': '($%04X,x)' % v,
              'absil': '[$%04X]' % v, 'long': '$%06X' % v, 'longx': '$%06X,x' % v,
              }.get(mode)
        if mode == 'mv': fm = '#$%02X,#$%02X' % (bs[2], bs[1])
        if mode == 'rel':
            t = (addr & 0xFF0000) | ((addr + 2 + (v - 256 if v > 127 else v)) & 0xFFFF); fm = '$%06X' % t
        if mode == 'rell':
            t = (addr & 0xFF0000) | ((addr + 3 + (v - 65536 if v > 32767 else v)) & 0xFFFF); fm = '$%06X' % t
        out('%06X  %-12s %s %s' % (addr, bs.hex(' '), mn, fm))
        if mn == 'rep':
            if v & 0x20: m = 16
            if v & 0x10: x = 16
        if mn == 'sep':
            if v & 0x20: m = 8
            if v & 0x10: x = 8
        addr = (addr & 0xFF0000) | ((addr + size) & 0xFFFF)
    return addr


if __name__ == '__main__':
    rom = open(sys.argv[1], 'rb').read()
    a = int(sys.argv[2], 16); n = int(sys.argv[3])
    m = int(sys.argv[4]) if len(sys.argv) > 4 else 16
    x = int(sys.argv[5]) if len(sys.argv) > 5 else 16
    dis(rom, a, n, m, x)
