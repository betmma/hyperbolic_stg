local UIHelper={}
local function keyBindValueCalc(self,addKey,subKey,valueName,valueMax)
    if isPressed(addKey)then
        self.currentUI[valueName]=self.currentUI[valueName]%valueMax+1
        SFX:play('select')
    elseif isPressed(subKey)then
        self.currentUI[valueName]=(self.currentUI[valueName]-2)%valueMax+1
        SFX:play('select')
    end
end
local function optionsCalc(self,execFuncs)
    local size=#self.currentUI.options
    keyBindValueCalc(self,'down','up','chosen',size)
    if isPressed('z') then
        local value=self.currentUI.options[self.currentUI.chosen].value
        SFX:play('select')
        if execFuncs[value]then
            execFuncs[value](self)
        end
    end
end
UIHelper.keyBindValueCalc=keyBindValueCalc
UIHelper.optionsCalc=optionsCalc
return UIHelper