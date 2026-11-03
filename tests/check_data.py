#!/usr/bin/env python3
"""Host-side integrity checks for APK-derived data."""
from pathlib import Path
import json
ROOT = Path(__file__).resolve().parents[1]
expected = {"animals":43,"birds":12,"monsters":12,"levels":43,"pokemon":13}
for name,count in expected.items():
    records=json.loads((ROOT/'data'/f'{name}.json').read_text(encoding='utf8'))
    assert len(records)==count, (name,len(records),count)
    ids=[x['id'] for x in records]
    assert len(set(ids))==len(ids), f'duplicate id in {name}'
    print(f'{name}: {len(records)} records OK')
animals={x['id'] for x in json.loads((ROOT/'data'/'animals.json').read_text())}
levels=json.loads((ROOT/'data'/'levels.json').read_text())
assert all(l['animal'] in animals for l in levels)
assert all(l['answer'] in l['options'] for l in levels)
print('quiz animal references and correct answers OK')
