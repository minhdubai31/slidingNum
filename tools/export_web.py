#!/usr/bin/env python3
"""Export Godot Web and copy the generated static files to backend/public/preview/."""
import argparse
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parent.parent
TEMPLATE_NAME = 'web_nothreads_release.zip'


class ReleaseArchive(io.RawIOBase):
    """Read only the ZIP directory and Web template from the official multi-platform archive."""
    def __init__(self, asset):
        self.asset, self.position = asset, 0

    def seekable(self):
        return True

    def readable(self):
        return True

    def tell(self):
        return self.position

    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else self.position + offset if whence == 1 else self.asset['size'] + offset
        return self.position

    def read(self, size=-1):
        size = min(self.asset['size'] - self.position, size if size >= 0 else self.asset['size'])
        if size <= 0:
            return b''
        start, end = self.position, self.position + size - 1
        # Separate cache keys prevent a cached byte range being reused for another range.
        url = self.asset['browser_download_url'] + '?segment=' + str(start)
        request = urllib.request.Request(url, headers={'Range': f'bytes={start}-{end}'})
        with urllib.request.urlopen(request, timeout=90) as response:
            if response.status != 206 or not response.headers.get('Content-Range', '').startswith(f'bytes {start}-'):
                raise RuntimeError('Release server did not return the requested byte range')
            data = response.read(size)
        if len(data) != size:
            raise RuntimeError('Incomplete Web template download')
        self.position += len(data)
        return data


def ensure_template(godot, offline):
    version = subprocess.check_output([godot, '--version'], text=True).strip().split('.')
    tag = '.'.join(version[:3]) + '-' + version[3]
    target = ROOT / 'builds/templates' / TEMPLATE_NAME
    marker = target.with_suffix('.version')
    if target.exists() and marker.exists() and marker.read_text().strip() == tag:
        return
    if offline:
        raise RuntimeError(f'Missing matching Web template for {tag}. Run again without --offline to download it.')
    asset_name = f'Godot_v{tag}_export_templates.tpz'
    print(f'Downloading the Web template for Godot {tag}…', flush=True)
    with urllib.request.urlopen(f'https://api.github.com/repos/godotengine/godot-builds/releases/tags/{tag}', timeout=30) as response:
        release = json.load(response)
    asset = next(item for item in release['assets'] if item['name'] == asset_name)
    with zipfile.ZipFile(ReleaseArchive(asset)) as archive:
        name = next(name for name in archive.namelist() if Path(name).name == TEMPLATE_NAME)
        data = archive.read(name)  # zipfile verifies the member's CRC.
    with zipfile.ZipFile(io.BytesIO(data)) as template:
        if 'godot.wasm' not in template.namelist() or template.testzip() is not None:
            raise RuntimeError('Invalid Web template archive')
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
    marker.write_text(tag + '\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default=os.environ.get('GODOT_BIN', 'godot'))
    parser.add_argument('--offline', action='store_true', help='Use an already downloaded template')
    args = parser.parse_args()
    ensure_template(args.godot, args.offline)
    builds = ROOT / 'builds'
    (builds / '.gdignore').touch()
    with tempfile.TemporaryDirectory(prefix='web-export-', dir=builds) as temporary:
        stage = Path(temporary)
        # Keep editor settings and test user data separate from the developer's installation.
        env = {**os.environ, 'XDG_CONFIG_HOME': str(stage / 'config'), 'XDG_DATA_HOME': str(stage / 'data')}
        export = stage / 'output'
        export.mkdir()
        subprocess.run([args.godot, '--headless', '--path', str(ROOT), '--export-release', 'Web', str(export / 'index.html')], env=env, check=True)
        for required in ['index.html', 'index.js', 'index.wasm', 'index.pck']:
            if not (export / required).is_file():
                raise RuntimeError(f'Export did not produce {required}')
        destination = ROOT / 'backend/public/preview'
        destination.mkdir(parents=True, exist_ok=True)
        for old in destination.iterdir():
            if old.is_file():
                old.unlink()
        for file in export.iterdir():
            if file.is_file():
                shutil.copy2(file, destination / file.name)
        (destination / '.gdignore').touch()
        total = sum(file.stat().st_size for file in destination.iterdir() if file.is_file())
        print(f'Web build ready: {destination} ({total / 1024**2:.1f} MiB)')
        print('Publish from backend/ with: vercel deploy --prod --yes')


if __name__ == '__main__':
    main()
