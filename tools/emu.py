#!/usr/bin/env python3
"""Tiny headless libretro frontend for scripted SNES testing.

usage: emu.py ROM [--load STATE] [--save STATE] [--shot PNG] SCRIPT...

SCRIPT tokens (run in order):
  w<N>            run N frames with no input
  <BTN>[*N][+M]   hold BTN (A,B,X,Y,L,R,START,SELECT,UP,DOWN,LEFT,RIGHT,
                  combine with '&') for N frames (default 2), then release
                  for M frames (default 10)
  shot:<file>     save a screenshot now
"""
import ctypes as C, sys, os, argparse
from PIL import Image

CORE = os.environ.get('CORE', '/usr/lib/x86_64-linux-gnu/libretro/snes9x_libretro.so')
BTN = dict(B=0, Y=1, SELECT=2, START=3, UP=4, DOWN=5, LEFT=6, RIGHT=7, A=8, X=9, L=10, R=11)

ap = argparse.ArgumentParser()
ap.add_argument('rom'); ap.add_argument('--load'); ap.add_argument('--save')
ap.add_argument('--shot'); ap.add_argument('--dump-ram'); ap.add_argument('--poke', default='')
ap.add_argument('--vfill', default='')
ap.add_argument('--dump-vram')
ap.add_argument('--dump-sram'); ap.add_argument('--load-sram')
ap.add_argument('script', nargs='*')
args = ap.parse_args()

lib = C.CDLL(CORE)
sysdir = C.c_char_p(os.path.dirname(os.path.abspath(args.rom)).encode())
state = dict(fmt=0, frame=None, pressed=set())

ENV_CB = C.CFUNCTYPE(C.c_bool, C.c_uint, C.c_void_p)
VID_CB = C.CFUNCTYPE(None, C.c_void_p, C.c_uint, C.c_uint, C.c_size_t)
AUD_CB = C.CFUNCTYPE(None, C.c_int16, C.c_int16)
AUDB_CB = C.CFUNCTYPE(C.c_size_t, C.c_void_p, C.c_size_t)
POLL_CB = C.CFUNCTYPE(None)
IN_CB = C.CFUNCTYPE(C.c_int16, C.c_uint, C.c_uint, C.c_uint, C.c_uint)

def env(cmd, data):
    cmd &= 0xFFFF
    if cmd in (9, 31):  # system / save directory
        C.cast(data, C.POINTER(C.c_char_p))[0] = sysdir.value; return True
    if cmd == 10:       # set pixel format
        state['fmt'] = C.cast(data, C.POINTER(C.c_int))[0]; return True
    if cmd == 3:        # can dupe
        C.cast(data, C.POINTER(C.c_bool))[0] = True; return True
    return False

def vid(data, w, h, pitch):
    if not data: return
    buf = C.string_at(data, pitch * h)
    if state['fmt'] == 2:      # RGB565
        im = Image.frombuffer('RGB', (w, h), buf, 'raw', 'BGR;16', pitch, 1)
    elif state['fmt'] == 1:    # XRGB8888
        im = Image.frombuffer('RGBX', (w, h), buf, 'raw', 'BGRX', pitch, 1).convert('RGB')
    else:                      # 0RGB1555
        im = Image.frombuffer('RGB', (w, h), buf, 'raw', 'BGR;15', pitch, 1)
    state['frame'] = im.copy()

def audb(d, n):
    if state.get('wav') is not None:
        state['wav'] += C.string_at(d, 4 * n)
    if state.get('rec') is not None:
        a = C.cast(d, C.POINTER(C.c_int16))
        state['rec'] += sum(abs(a[i]) for i in range(0, 2 * n, 8)); state['recn'] += (2 * n + 7) // 8
    return n

def inp(port, device, index, bid):
    return 1 if (port == 0 and device == 1 and (bid in state['pressed'] or bid in state.get('held', ()))) else 0

cbs = [ENV_CB(env), VID_CB(vid), AUD_CB(lambda l, r: None),
       AUDB_CB(audb), POLL_CB(lambda: None), IN_CB(inp)]
lib.retro_set_environment(cbs[0]); lib.retro_set_video_refresh(cbs[1])
lib.retro_set_audio_sample(cbs[2]); lib.retro_set_audio_sample_batch(cbs[3])
lib.retro_set_input_poll(cbs[4]); lib.retro_set_input_state(cbs[5])
lib.retro_init()

class GameInfo(C.Structure):
    _fields_ = [('path', C.c_char_p), ('data', C.c_void_p), ('size', C.c_size_t), ('meta', C.c_char_p)]
rom = open(args.rom, 'rb').read()
rbuf = C.create_string_buffer(rom, len(rom))
gi = GameInfo(os.path.abspath(args.rom).encode(), C.cast(rbuf, C.c_void_p), len(rom), None)
assert lib.retro_load_game(C.byref(gi)), 'load failed'

lib.retro_serialize_size.restype = C.c_size_t
if args.load:
    s = open(args.load, 'rb').read()
    sb = C.create_string_buffer(s, len(s))
    assert lib.retro_unserialize(sb, len(s)), 'unserialize failed'

lib.retro_get_memory_data.restype = C.c_void_p
lib.retro_get_memory_size.restype = C.c_size_t
ram = (C.c_uint8 * lib.retro_get_memory_size(2)).from_address(lib.retro_get_memory_data(2))
for pk in filter(None, args.poke.split(',')):
    a, v = pk.split(':'); ram[int(a, 16)] = int(v, 16)

vram = (C.c_uint8 * lib.retro_get_memory_size(3)).from_address(lib.retro_get_memory_data(3))
sram_n = lib.retro_get_memory_size(0)
sram = (C.c_uint8 * sram_n).from_address(lib.retro_get_memory_data(0)) if sram_n else None
if args.load_sram:
    d = open(args.load_sram, 'rb').read()
    for k in range(min(len(d), sram_n)): sram[k] = d[k]
for vf in filter(None, args.vfill.split(',')):
    a, n, v = vf.split(':')
    for k in range(int(a, 16), int(a, 16) + int(n, 16)): vram[k] = int(v, 16)

def run(n):
    for _ in range(n): lib.retro_run()

for tok in args.script:
    if tok.startswith('frames:'):
        # frames:N:STEP:file  raw RGB frames (top 120 lines, 2x downsampled) every STEP frames
        _, n, st, fn = tok.split(':', 3)
        with open(fn, 'wb') as f:
            seen = 0
            for k in range(int(n)):
                run(1)
                if (ram[0xD7] | ram[0xD8] << 8) == 0xDC33: seen += 1
                if k % int(st) == 0:
                    f.write(state['frame'].crop((0, 0, 256, 120)).resize((128, 60), 0).tobytes())
        print('battleframes', seen)
        continue
    if tok.startswith('ramlog:'):
        _, n, fn = tok.split(':', 2)
        with open(fn, 'wb') as f:
            for _ in range(int(n)):
                run(1); f.write(bytes(ram))
        continue
    if tok.startswith('hold:'):
        state['held'] = {BTN[b] for b in tok[5:].split('&')} if tok[5:] else set(); continue
    if tok.startswith('poke:'):
        for pk in tok[5:].split(','):
            a, v = pk.split('='); ram[int(a, 16)] = int(v, 16)
        continue
    if tok.startswith('shot:'):
        state['frame'].save(tok[5:]); continue
    if tok.startswith('procwatch:'):
        _, n, typ = tok.split(':')
        typ = int(typ, 16)
        w = lambda a: ram[a] | ram[a + 1] << 8
        for f in range(int(n)):
            run(1)
            for i in range(16):
                if w(0x53D + 2*i) == typ:
                    print(f, 'slot', i, 'bits %04X' % w(0x59D+2*i), 'oncycle %04X sleep %d body0 %04X body1 %d body2 %d body5 %d' % (w(0x5BD+2*i), w(0x5FD+2*i), w(0x63D+2*i), w(0x65D+2*i), w(0x67D+2*i), w(0x6DD+2*i)))
        continue
    if tok.startswith('watch:'):
        # watch:N:addr,addr,...  print words at addrs each frame when they change
        _, n, al = tok.split(':')
        al = [int(a, 16) for a in al.split(',')]
        last = None
        for f in range(int(n)):
            run(1)
            cur = tuple(ram[a] | ram[a + 1] << 8 for a in al)
            if cur != last: print(f, ' '.join('%04X=%04X' % (a, v) for a, v in zip(al, cur))); last = cur
        continue
    if tok.startswith('wav:'):
        _, n, fn = tok.split(':', 2)
        state['wav'] = bytearray(); run(int(n))
        import wave
        w = wave.open(fn, 'wb'); w.setnchannels(2); w.setsampwidth(2); w.setframerate(32040); w.writeframes(bytes(state['wav'])); w.close()
        state['wav'] = None
        continue
    if tok.startswith('audio:'):
        state['rec'] = 0; state['recn'] = 0
        run(int(tok[6:]))
        print('audio level', state['rec'] // max(1, state['recn'])); state['rec'] = None
        continue
    if tok.startswith('trace:'):
        for f in range(int(tok[6:])):
            run(1)
            pos = ram[0x343] | ram[0x344] << 8
            ents = []; k = 0
            while k < 0x100 and ram[0x346 + k] != 0 and len(ents) < 12:
                t = ram[0x346 + k]
                if t == 2:
                    e = bytes(ram[0x346 + k:0x346 + k + 9])
                    ents.append('VRAM src=%02X%02X%02X n=%d dst=%04X' % (e[3], e[2], e[1], e[4] | e[5] << 8, e[7] | e[8] << 8)); k += 9
                else:
                    ents.append('type%d' % t); break
            print(f, 'pos=%d flag=%d' % (pos, ram[0x345]), 'v140=%s v150=%s' % (bytes(vram[0x2800:0x2804]).hex(), bytes(vram[0x2A00:0x2A04]).hex()), ents)
        continue
    if tok[0] == 'w' and tok[1:].isdigit():
        run(int(tok[1:])); continue
    hold, rel = 2, 10
    if '+' in tok: tok, r = tok.split('+'); rel = int(r)
    if '*' in tok: tok, h = tok.split('*'); hold = int(h)
    state['pressed'] = {BTN[b] for b in tok.split('&')}
    run(hold); state['pressed'] = set(); run(rel)

if args.shot: state['frame'].save(args.shot)
if args.dump_vram: open(args.dump_vram, 'wb').write(bytes(vram))
if args.dump_ram: open(args.dump_ram, 'wb').write(bytes(ram))
if args.dump_sram: open(args.dump_sram, 'wb').write(bytes(sram))
if args.save:
    n = lib.retro_serialize_size(); sb = C.create_string_buffer(n)
    assert lib.retro_serialize(sb, n); open(args.save, 'wb').write(sb.raw)
