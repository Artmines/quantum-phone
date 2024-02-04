--[[
    App: Calculator
]]

Calculator = {}

function Calculator.Render()
    SetAppUnread('calculator', false)
    exports['quantum-ui']:SendUIMessage("Phone", "RenderCalculatorApp", {})
end

