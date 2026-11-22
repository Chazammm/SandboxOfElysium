local sandbox

local function openSandbox()
    local ok,caps=pcall(coe5.testFieldEditorCapabilities)
    local compatible=ok and type(caps)=='table' and caps.unitRetirement==1 and
        caps.initialDeploymentVersion==1 and caps.exactDeploymentVersion==1 and caps.configuration==1 and
        type(coe5.setTestFieldDeployment)=='function' and type(coe5.testFieldInitialDeployment)=='function' and
        type(coe5.testFieldLoadoutState)=='function' and type(coe5.setTestFieldConfiguration)=='function'
    if not compatible then
        local ui=coe5.ui
        ui.screenBegin('SandboxOfElysium requires a compatible CoE5SE build')
        ui.sectionBegin('Editor unavailable')
        ui.text(0,'This beta supports Windows CoE5 5.43 x64 with official CoE5SE 3.8.2.')
        ui.text(0,'The editor needs owned field retirement, exact deployment and actor configuration support.')
        ui.text(0,'See the SandboxOfElysium installation instructions. Existing scenarios and recovery files are kept.')
        ui.sectionEnd()
        ui.buttonRow()
        ui.text(1,'Back')
        ui.bindEscape(1)
        ui.wait()
        return
    end
    if not sandbox then sandbox=require('sandbox.ui').new(coe5)end
    sandbox:setup()
end

coe5.addMainMenuButton('Sandbox',openSandbox)
