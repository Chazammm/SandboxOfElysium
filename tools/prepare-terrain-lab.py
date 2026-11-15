"""Build a separate terrain test profile, never an installed game/profile."""
from pathlib import Path
import argparse, shutil, struct, json, hashlib, stat, configparser

root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--extender',type=Path,required=True)
p.add_argument('--label',required=True)
p.add_argument('--sandbox',action='store_true',help='Enable the current Sandbox UI in this private profile')
p.add_argument('--launcher-nonce',help='Interactive BAT launch with a private startup handshake, no terrain probe')
p.add_argument('--editing-probe',action='store_true',help='Enable own native editor regression in private profile only')
p.add_argument('--placement-probe',action='store_true',help='Enable own large-unit placement regression in private profile only')
p.add_argument('--interface-probe',action='store_true',help='Enable own lifecycle/interface regression in private profile only')
p.add_argument('--inspector-probe',action='store_true',help='Explicit private spell/footprint/native-card regression')
p.add_argument('--inspector-cases',default='',help='Optional comma-separated private regression case names')
p.add_argument('--battlefield-probe',action='store_true',help='Private empty/final/land-terrain regressions')
p.add_argument('--battlefield-cases',default='',help='Comma-separated private case names')
p.add_argument('--terrain-candidates',action='store_true',help='Mark a private terrain candidate build in probe evidence')
p.add_argument('--crabcult',action='store_true',help='Use the already installed private CrabCult copy, never distributed')
p.add_argument('--probe-mode',choices=('baseline','regression'),default='regression')
p.add_argument('--probe-auto',action='store_true',help='Private explicitly selected native probe; no default BAT automation')
a=p.parse_args()
if a.probe_auto and (not a.battlefield_probe or not a.battlefield_cases):
    p.error('--probe-auto requires an explicit battlefield probe/case selection')
assert a.label.replace('-','').replace('.','').isalnum()
base=root/'private/lab'
identity=json.loads((base/'identity.json').read_text())
game=Path(identity['game']);lab=root/'private/terrain-lab'
runtime=lab/'runtime';profile=lab/'profile'
def no_links(path):
    if not path.exists(): return
    if path.lstat().st_file_attributes & stat.FILE_ATTRIBUTE_REPARSE_POINT:
        raise RuntimeError(f'Verknuepfter Testpfad nicht erlaubt: {path}')
    if path.is_dir():
        for child in path.iterdir(): no_links(child)
for parent in (root,root/'private',lab):
    if parent.exists() and parent.lstat().st_file_attributes & stat.FILE_ATTRIBUTE_REPARSE_POINT:
        raise RuntimeError(f'Unsicherer Testpfad: {parent}')
no_links(lab)
if (lab/'identity.json').exists():
    existing=json.loads((lab/'identity.json').read_text())
    if Path(existing['profile']).resolve()!=profile.resolve() or Path(existing['data']).resolve()!=(game/'data').resolve():
        raise RuntimeError('Isoliertes Profil/Datenpfad stimmt nicht; Vorbereitung abgebrochen.')
no_links(root/'mod/SandboxOfElysium')
if a.launcher_nonce:
    if len(a.launcher_nonce)!=32 or any(c not in '0123456789abcdef' for c in a.launcher_nonce):
        raise RuntimeError('Ungueltige Startkennung.')
    a.sandbox=True
    source=root/'mod/SandboxOfElysium';target=profile/'mods/SandboxOfElysium'
    if target.exists():
        extras=[f.relative_to(target) for f in target.rglob('*') if f.is_file() and not (source/f.relative_to(target)).is_file()]
        if extras: raise RuntimeError('Alte Zusatzdateien im Test-Mod; bitte manuell pruefen, nichts geloescht: '+str(extras[0]))
runtime.mkdir(parents=True,exist_ok=True);profile.mkdir(parents=True,exist_ok=True)
if not (runtime/'CoE5.exe').exists():
    for pattern in ('*.dll','CoE5.exe','coe5key'):
        for f in game.glob(pattern): shutil.copy2(f,runtime/f.name)
ext=profile/'mods/CoE5SE';ext.mkdir(parents=True,exist_ok=True)
hashes={}
for name in ('coe5se_loader.dll','coe5se.c5plugin.dll','CoE5SE.c5m','CoE5SE.c5se','banner.tga'):
    shutil.copy2(a.extender/name,ext/name)
    hashes[name]=hashlib.sha256((ext/name).read_bytes()).hexdigest()
shutil.copy2(a.extender/'glu32.dll',runtime/'glu32.dll')
probe=profile/'mods/TerrainProbe';probe.mkdir(parents=True,exist_ok=True)
shutil.copy2(root/'tests/terrain_probe.lua',probe/'TerrainProbe.lua')
shutil.copytree(root/'mod/SandboxOfElysium/sandbox',probe/'sandbox',dirs_exist_ok=True)
shutil.copy2(root/'mod/SandboxOfElysium/banner.tga',probe/'banner.tga')
(probe/'TerrainProbe.c5m').write_text('icon "banner.tga"\ndescription "Private terrain API validation. Not a production sandbox."\n')
if not (profile/'coe5config').exists():
    shutil.copy2(base/'profile/coe5config',lab/'profile-source-backup')
    shutil.copy2(base/'profile/coe5config',profile/'coe5config')
if a.sandbox:
    shutil.copytree(root/'mod/SandboxOfElysium',profile/'mods/SandboxOfElysium',dirs_exist_ok=True)
if a.launcher_nonce:
    check=profile/'mods/SandboxLauncherCheck';check.mkdir(parents=True,exist_ok=True)
    shutil.copy2(root/'tests/launcher_probe.lua',check/'SandboxLauncherCheck.lua')
    shutil.copy2(root/'mod/SandboxOfElysium/banner.tga',check/'banner.tga')
    (check/'SandboxLauncherCheck.c5m').write_text('icon "banner.tga"\ndescription "Private Sandbox startup check. No automatic battles."\n')
    data_folder=profile/'coe5se_data/SandboxLauncherCheck';data_folder.mkdir(parents=True,exist_ok=True)
    (data_folder/'request.ini').write_text('[launch]\nnonce='+a.launcher_nonce+'\n')
    names=('CoE5SE','SandboxOfElysium','SandboxLauncherCheck')
else:
    names=('CoE5SE','TerrainProbe','SandboxOfElysium') if a.sandbox else ('CoE5SE','TerrainProbe')
if a.crabcult:
    source=base/'profile/mods/CrabCult';target=profile/'mods/CrabCult'
    if not (source/'CrabCult.c5m').is_file(): raise RuntimeError('Vorhandene private CrabCult-Kopie fehlt.')
    no_links(source);no_links(target)
    if target.exists():
        for file in target.rglob('*'):
            if file.is_file():
                original=source/file.relative_to(target)
                if not original.is_file() or hashlib.sha256(file.read_bytes()).digest()!=hashlib.sha256(original.read_bytes()).digest():
                    raise RuntimeError('Abweichende private CrabCult-Datei bleibt erhalten: '+str(file))
    shutil.copytree(source,target,dirs_exist_ok=True)
    names+=('CrabCult',)
if a.editing_probe:
    probe=profile/'mods/ZZSandboxEditingProbe';probe.mkdir(parents=True,exist_ok=True)
    shutil.copy2(root/'tests/editing_probe.lua',probe/'ZZSandboxEditingProbe.lua')
    shutil.copytree(root/'mod/SandboxOfElysium/sandbox',probe/'sandbox',dirs_exist_ok=True)
    shutil.copy2(root/'mod/SandboxOfElysium/banner.tga',probe/'banner.tga')
    (probe/'ZZSandboxEditingProbe.c5m').write_text('icon "banner.tga"\ndescription "Private native editing regression."\n')
    baseline=Path((root/'private/editing-baseline-path.txt').read_text())/'SandboxOfElysium/sandbox/runtime.lua'
    (probe/'baseline').mkdir(exist_ok=True);shutil.copy2(baseline,probe/'baseline/runtime.lua')
    data_folder=profile/'coe5se_data/ZZSandboxEditingProbe';data_folder.mkdir(parents=True,exist_ok=True)
    (data_folder/'request.ini').write_text('[run]\nmode='+a.probe_mode+'\ndefer=1\n')
    names+=('ZZSandboxEditingProbe',)
if a.placement_probe:
    probe=profile/'mods/ZZSandboxPlacementProbe';probe.mkdir(parents=True,exist_ok=True)
    shutil.copy2(root/'tests/placement_probe.lua',probe/'ZZSandboxPlacementProbe.lua')
    shutil.copytree(root/'mod/SandboxOfElysium/sandbox',probe/'sandbox',dirs_exist_ok=True)
    shutil.copy2(root/'mod/SandboxOfElysium/banner.tga',probe/'banner.tga')
    (probe/'ZZSandboxPlacementProbe.c5m').write_text('icon "banner.tga"\ndescription "Private native large-unit placement regression."\n')
    baseline=Path((root/'private/placement-baseline-path.txt').read_text())/'sandbox/mod/SandboxOfElysium/sandbox/runtime.lua'
    (probe/'baseline').mkdir(exist_ok=True);shutil.copy2(baseline,probe/'baseline/runtime.lua')
    data_folder=profile/'coe5se_data/ZZSandboxPlacementProbe';data_folder.mkdir(parents=True,exist_ok=True)
    (data_folder/'request.ini').write_text('[run]\nmode='+a.probe_mode+'\n')
    names+=('ZZSandboxPlacementProbe',)

if a.interface_probe:
    probe=profile/'mods/ZZSandboxInterfaceProbe';probe.mkdir(parents=True,exist_ok=True)
    shutil.copy2(root/'tests/interface_probe.lua',probe/'ZZSandboxInterfaceProbe.lua')
    backup=Path((root/'private/interface-baseline-path.txt').read_text())
    source=backup/'sandbox/mod/SandboxOfElysium/sandbox' if a.probe_mode=='baseline' else root/'mod/SandboxOfElysium/sandbox'
    shutil.copytree(source,probe/'sandbox',dirs_exist_ok=True)
    shutil.copy2(root/'mod/SandboxOfElysium/banner.tga',probe/'banner.tga')
    (probe/'ZZSandboxInterfaceProbe.c5m').write_text('icon "banner.tga"\ndescription "Private lifecycle/interface regression."\n')
    data_folder=profile/'coe5se_data/ZZSandboxInterfaceProbe';data_folder.mkdir(parents=True,exist_ok=True)
    (data_folder/'request.ini').write_text('[run]\nmode='+a.probe_mode+'\n')
    replay=backup/'profile-data/recovery-b3534339bc164caaa2af-1.ini'
    if replay.exists(): shutil.copy2(replay,data_folder/'replay.ini')
    names+=('ZZSandboxInterfaceProbe',)

if a.inspector_probe:
    probe=profile/'mods/ZZSandboxInspectorProbe';probe.mkdir(parents=True,exist_ok=True)
    shutil.copy2(root/'tests/inspector_probe.lua',probe/'ZZSandboxInspectorProbe.lua')
    backup=Path((root/'private/inspect-baseline-path.txt').read_text().strip())
    source=backup/'sandbox/mod/SandboxOfElysium/sandbox' if a.probe_mode=='baseline' else root/'mod/SandboxOfElysium/sandbox'
    shutil.copytree(source,probe/'sandbox',dirs_exist_ok=True)
    shutil.copy2(root/'mod/SandboxOfElysium/banner.tga',probe/'banner.tga')
    (probe/'ZZSandboxInspectorProbe.c5m').write_text('icon "banner.tga"\ndescription "Private spell and inspector regression."\n')
    data_folder=profile/'coe5se_data/ZZSandboxInspectorProbe';data_folder.mkdir(parents=True,exist_ok=True)
    (data_folder/'request.ini').write_text('[run]\nmode='+a.probe_mode+'\n')
    if a.inspector_cases:
        assert all(ch.isascii() and (ch.islower() or ch.isdigit() or ch in '_,') for ch in a.inspector_cases)
        with (data_folder/'request.ini').open('a') as request: request.write('only='+a.inspector_cases+'\n')
    shutil.copy2(backup/'profile-data/recovery-9df3eae7c90343999f1d-1.ini',data_folder/'replay.ini')
    names+=('ZZSandboxInspectorProbe',)

if a.battlefield_probe:
    if 'loadout_fixture' in a.battlefield_cases.split(','):
        fixture=profile/'mods/ZZZSandboxLoadoutFixture20261115'
        fixture.mkdir(parents=True,exist_ok=True)
        shutil.copy2(root/'tests/loadout-fixture.c5m',fixture/'ZZZSandboxLoadoutFixture20261115.c5m')
        shutil.copy2(root/'mod/SandboxOfElysium/banner.tga',fixture/'banner.tga')
        names+=('ZZZSandboxLoadoutFixture20261115',)
    backup=Path((root/'private/battlefield-baseline-path.txt').read_text().strip())
    for modname,script in (('ZZSandboxBattlefieldProbe','battlefield_probe.lua'),('ZZSandboxFinalProbe','final_probe.lua')):
        probe=profile/'mods'/modname;probe.mkdir(parents=True,exist_ok=True)
        shutil.copy2(root/'tests'/script,probe/(modname+'.lua'))
        source=backup/'sandbox/mod/SandboxOfElysium/sandbox' if a.probe_mode=='baseline' else root/'mod/SandboxOfElysium/sandbox'
        shutil.copytree(source,probe/'sandbox',dirs_exist_ok=True)
        for helper in ('terrain_expansion_probe.lua','empty_probe.lua','loadout_probe.lua','panel_probe.lua','cursed_probe.lua'):
            shutil.copy2(root/'tests'/helper,probe/helper)
        shutil.copy2(root/'mod/SandboxOfElysium/banner.tga',probe/'banner.tga')
        (probe/(modname+'.c5m')).write_text('icon "banner.tga"\ndescription "Private battlefield regression. Not distributed."\n')
        data_folder=profile/'coe5se_data'/modname;data_folder.mkdir(parents=True,exist_ok=True)
        mode=a.probe_mode if modname=='ZZSandboxBattlefieldProbe' else ('final' if a.probe_mode!='baseline' and (not a.battlefield_cases or 'final' in a.battlefield_cases.split(',')) else 'disabled')
        (data_folder/'request.ini').write_text('[run]\nmode='+mode+'\nonly='+a.battlefield_cases+'\nterrain_candidates='+('1' if a.terrain_candidates else '0')+'\ndefer='+('0' if a.probe_auto else '1')+'\n')
        shutil.copy2(backup/'profile-data/repaired-5d092932caf74c588295-1.ini',data_folder/'replay.ini')
        diagnostic=configparser.ConfigParser(interpolation=None)
        diagnostic.read(backup/'profile-data/diagnostics-5bd42749aa2c47d4ba1b-1.ini',encoding='utf-8-sig')
        saved=configparser.ConfigParser(interpolation=None)
        saved['mods']={'1':'CoE5SE','2':'SandboxLauncherCheck','3':'SandboxOfElysium'}
        saved['scenario']={'schema':'1','terrain':'0','size':'Native automatic','count':diagnostic['current']['units'],'a_color':'1','b_color':'2','allow_multiple_unique':diagnostic['current']['allow_multiple_unique']}
        for i in range(1,int(saved['scenario']['count'])+1):
            row=diagnostic['current_unit'+str(i)]
            unit={key:row[key] for key in ('monster','name','team')};unit['x']=row['saved_x'];unit['y']=row['saved_y']
            for source,prefix in (('saved_known','known'),('saved_memorized','spell'),('saved_items','item')):
                values=[v for v in row[source].split('|') if v];unit[prefix+'_count']=str(len(values))
                unit.update({prefix+str(j):value for j,value in enumerate(values,1)})
            saved['unit'+str(i)]=unit
        with (data_folder/'user-replay.ini').open('w',encoding='utf-8') as file:saved.write(file,space_around_delimiters=False)
        names+=(modname,)

data=(profile/'coe5config').read_bytes();assert 0x7c<=struct.unpack_from('<I',data)[0]<=0x81
pos=48
while data[pos]!=0x4f: pos=data.index(0x4f,pos)+1
block=b''.join(bytes(c^0x4f for c in n.encode())+b'\x4f' for n in names)
(profile/'coe5config').write_bytes(data[:48]+block+data[pos:])
out=lab/'builds'/a.label;out.mkdir(parents=True,exist_ok=True)
for name in ('coe5se_loader.dll','coe5se.c5plugin.dll','glu32.dll'): shutil.copy2(a.extender/name,out/name)
(out/'hashes.json').write_text(json.dumps(hashes,indent=2))
(lab/'identity.json').write_text(json.dumps({'game':str(game),'profile':str(profile),'data':str(game/'data'),'label':a.label,'hashes':hashes},indent=2))
print('Prepared isolated terrain lab:',a.label)
