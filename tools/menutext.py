#!/usr/bin/env python3
"""Spell a label with Lil' Manster's menu bigrams.
usage: menutext.py "Text one" "Text two" ...
Prints the code words for each label (fewest tiles), or the
first character that can't be reached."""
import json, sys

codes = json.load(open('/root/work/codes108.json'))
MARK = '[]()+'
tok = {}
for k, (s, _) in codes.items():
    if not s or s == 'None' or int(k, 16) > 0x0300: continue
    if any(c in MARK for c in s) and s not in ('[m', ']w', ')W', '(M', '+N'): continue
    plain = ''.join(c for c in s if c not in MARK)
    # keep the variant with fewest markers for each plain text
    if plain not in tok or len(s) < len(tok[plain][1]):
        tok[plain] = (int(k, 16), s)


WIDE = [('G', (0x6682, '{G}')), ('B', (0x6182, '{B}')), ('A', (0x6082, '{A}')), ('H', (0x6782, '{H}')), ('P', (0x6F82, '{P}')), ('im', (0x6D69, '{im}'))]


def cost(seq):
    return sum(1 + (0.6 if s.startswith('{') and s != '{im}' else 0) + (0.1 if any(m in s for m in MARK) else 0) + (0.5 if s.endswith('~') else 0) for _, s in seq)


def spell(text):
    n = len(text); best = [None] * (n + 1); best[0] = []
    for i in range(n):
        if best[i] is None: continue
        for plain, (c, s) in list(tok.items()) + WIDE:
            if plain and text.startswith(plain, i):
                j = i + len(plain); cand = best[i] + [(c, s)]
                if best[j] is None or cost(cand) < cost(best[j]): best[j] = cand
            # widen a space: re-use the previous space
            if plain and plain[0] == ' ' and i > 0 and text[i - 1] == ' ' and text.startswith(plain[1:], i):
                j = i + len(plain) - 1; cand = best[i] + [(c, s + '~')]
                if j > i and (best[j] is None or cost(cand) < cost(best[j])): best[j] = cand
    return best[n]


if __name__ == '__main__':
    for t in sys.argv[1:]:
        r = spell(t)
        if r is None:
            # find longest reachable prefix
            for p in range(len(t), 0, -1):
                if spell(t[:p]) is not None: break
            print('%-24r FAIL at %r' % (t, t[p:p + 3]))
        else:
            print('%-24r %d tiles  %s   %s' % (t, len(r), ' '.join(s for _, s in r), ','.join('%04X' % c for c, _ in r)))
