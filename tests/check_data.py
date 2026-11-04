import json
from pathlib import Path
p = Path(__file__).resolve().parents[1] / 'data/pokemon.json'
mons = json.loads(p.read_text('utf8'))
expected = {25,94,133,103,810,7,79,574,4,9,54,190,473,167,1}
assert len(mons) == len(expected) == 15
assert {m['id'] for m in mons} == expected
for m in mons:
    assert all(k in m for k in ('name','intro','height','weight','types','ability','moves','question','fun'))
    assert m['height'] > 0 and m['weight'] > 0 and len(m['moves']) >= 2
    assert all(a['name'] and a['description'] for a in m['ability'] + m['moves'])
print('PASS: fifteen Pokemon with descriptive attributes, measurements, abilities and moves')
