-- Private launch handshake. No battles, world mutation or extra menu entries.
local request=coe5.readIni('request')
if not request or not request.launch or not request.launch.nonce then return end
local nonce=request.launch.nonce
if not nonce:match('^[a-f0-9]+$') or #nonce~=32 then return end
local status={nonce=nonce,sandbox='0',terrain_query='absent',plain='0',forest='0',editor='0',integrity='0',lifecycle='0',multiple_unique='0',inline_input='0',fitted_icons='0',empty_editor='0',final_snapshot_api='0'}
status.configuration='0'
if type(coe5.testFieldEditorCapabilities)=='function' then
    local ok,caps=pcall(coe5.testFieldEditorCapabilities)
    if ok and type(caps)=='table' and caps.uniqueGuard==1 and caps.state==1 and caps.pointerButtons==1 then status.integrity='1' end
    if ok and type(caps)=='table' then
        if caps.lifecycle==1 then status.lifecycle='1' end
        if caps.multipleUnique==1 then status.multiple_unique='1' end
        if caps.emptyEditor==1 then status.empty_editor='1' end
        if caps.configuration==1 and type(coe5.testFieldLoadoutState)=='function' and type(coe5.setTestFieldConfiguration)=='function' then
            status.configuration='1'
            if type(coe5.removeTestFieldUnit)=='function' and type(coe5.battleScreenToCell)=='function' then status.editor='1' end
        end
    end
end
if type(coe5.setTestFieldTextFocus)=='function' and type(coe5.takeTestFieldTextEvents)=='function' then status.inline_input='1' end
if type(coe5.ui.drawMonsterSprite or coe5.ui.drawMonsterIconFit)=='function' then status.fitted_icons='1' end
if type(coe5.testFieldFinalState)=='function' and type(coe5.inspectTestFieldFinalUnit)=='function' then status.final_snapshot_api='1' end
for i=0,coe5.get('modLastIndex') do
    if coe5.get('modName',i)=='SandboxOfElysium' and coe5.get('modEnabled',i)~=0 then status.sandbox='1' end
end
if type(coe5.testFieldTerrains)=='function' then
    local ok,ids=pcall(coe5.testFieldTerrains)
    status.terrain_query=ok and type(ids)=='table' and 'ok' or 'failed'
    local names={}
    if status.terrain_query=='ok' then for _,id in ipairs(ids) do
        names[#names+1]=tostring(coe5.get('terrainName',id))
        if id==0 and coe5.get('terrainName',id)=='Plain' then status.plain='1' end
        if id==2 and coe5.get('terrainName',id)=='Forest' then status.forest='1' end
    end end
    status.terrain_names=table.concat(names,', ')
end
coe5.writeIni('response-'..nonce,{launch=status})
