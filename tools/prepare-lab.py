"""Private test copy; never changes the installed game or player's profile."""
from pathlib import Path
import shutil, struct, json, argparse, os

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--game', type=Path, required=True, help='Owned CoE5 installation directory')
parser.add_argument('--profile', type=Path, default=Path(os.environ['APPDATA'])/'coe5')
args = parser.parse_args()
GAME, PROFILE = args.game.resolve(), args.profile.resolve()
LAB = ROOT / 'private/lab'
runtime, profile = LAB / 'runtime', LAB / 'profile'
runtime.mkdir(parents=True, exist_ok=True)
profile.mkdir(parents=True, exist_ok=True)
for pattern in ('*.dll', 'CoE5.exe', 'coe5key'):
    for file in GAME.glob(pattern):
        shutil.copy2(file, runtime / file.name)
upstream = ROOT / 'private/upstream'
ext = profile / 'mods/CoE5SE'
ext.mkdir(parents=True, exist_ok=True)
for name in ('coe5se_loader.dll','coe5se.c5plugin.dll','CoE5SE.c5m','CoE5SE.c5se','banner.tga'):
    shutil.copy2(upstream / name, ext / name)
shutil.copy2(upstream / 'glu32.dll', runtime / 'glu32.dll')
mod = profile / 'mods/SandboxOfElysium'
shutil.copytree(ROOT / 'mod/SandboxOfElysium', mod, dirs_exist_ok=True)
if not (profile / 'coe5config').exists():
    data = (PROFILE / 'coe5config').read_bytes()
    version = struct.unpack_from('<I', data)[0]
    assert 0x7c <= version <= 0x81, f'unsupported config version {version}'
    pos = 48
    while data[pos] != 0x4f:
        pos = data.index(0x4f, pos) + 1
    names = b''.join(bytes(c ^ 0x4f for c in name.encode()) + b'\x4f'
                     for name in ('CoE5SE','SandboxOfElysium'))
    (profile / 'coe5config').write_bytes(data[:48] + names + data[pos:])
    shutil.copy2(PROFILE / 'coe5config', LAB / 'original-config-backup')
(LAB / 'identity.json').write_text(json.dumps({'game':str(GAME),'profile':str(profile),'data':str(GAME/'data')}, indent=2))
print('Private lab prepared:', LAB)
