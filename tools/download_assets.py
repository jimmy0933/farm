#!/usr/bin/env python3
"""Download reference artwork only for local, private building; never commit art to Git."""
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import URLError
import time
import json

ROOT = Path(__file__).resolve().parents[1]
ids = [int(row['id']) for row in json.loads((ROOT / 'data/pokemon.json').read_text('utf-8'))]
folder = ROOT / 'assets/pokemon'
folder.mkdir(parents=True, exist_ok=True)
urls = [(str(i), f'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/{i}.png', folder / f'{i}.png') for i in ids]
font = ROOT / 'assets/fonts/NotoSansCJKtc-Regular.otf'
font.parent.mkdir(parents=True, exist_ok=True)
urls.append(('NotoSansCJKtc', 'https://raw.githubusercontent.com/googlefonts/noto-cjk/main/Sans/OTF/TraditionalChinese/NotoSansCJKtc-Regular.otf', font))
for name, url, target in urls:
    if target.exists() and target.stat().st_size > 5000:
        print(f'Already present: {name}')
        continue
    for attempt in range(4):
        try:
            with urlopen(Request(url, headers={'User-Agent': 'FarmPokemonKids/1.0'}), timeout=50) as response:
                binary = response.read()
            if name != 'NotoSansCJKtc' and not binary.startswith(b'\x89PNG\r\n\x1a\n'):
                raise ValueError(f'{name} image does not have a PNG signature')
            if len(binary) < 5000:
                raise ValueError(f'{name} download is unexpectedly small')
            target.write_bytes(binary)
            print(f'Downloaded {name}: {len(binary)} bytes')
            break
        except (URLError, TimeoutError, OSError, ValueError) as exc:
            if attempt == 3:
                raise RuntimeError(f'Failed to download {name}: {exc}') from exc
            time.sleep(2 * (attempt + 1))
