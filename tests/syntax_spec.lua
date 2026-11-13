for _,name in ipairs({'SandboxOfElysium.lua','sandbox/model.lua','sandbox/catalog.lua','sandbox/runtime.lua','sandbox/report.lua','sandbox/ui.lua'}) do
    assert(loadfile('mod/SandboxOfElysium/'..name));print('PARSE '..name)
end
assert(loadfile('tests/native_probe.lua'));print('All distributed Lua files and native probe parse')
