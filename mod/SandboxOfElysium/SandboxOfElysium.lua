local UI=require('sandbox.ui')
local sandbox=UI.new(coe5)
coe5.addMainMenuButton('Sandbox',function() sandbox:setup() end)
