"""Change enabled mods only in the project's isolated test profile."""
from pathlib import Path
import sys, struct
root=Path(__file__).resolve().parents[1]
config=root/'private/lab/profile/coe5config'
data=config.read_bytes()
assert 0x7c <= struct.unpack_from('<I',data)[0] <= 0x81
pos=48
while data[pos]!=0x4f:
    pos=data.index(0x4f,pos)+1
names=sys.argv[1:]
assert all(n and '/' not in n and '\\' not in n for n in names)
block=b''.join(bytes(c^0x4f for c in n.encode())+b'\x4f' for n in names)
config.write_bytes(data[:48]+block+data[pos:])
print('Lab mods:', ', '.join(names))
