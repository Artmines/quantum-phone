--[[
    App: Calls
]]

Calls = {}
Calls.Log = {}

function Calls.Render()
    SetAppUnread('calls', false)
    exports['quantum-ui']:SendUIMessage("Phone", "RenderCallsApp", {
        Calls = Calls.Log[PlayerModule.GetPlayerData().CitizenId] or {}
    })
end

RegisterNetEvent('quantum-phone/client/calls/add-call-log', function(CallLog)
    local CitizenId = PlayerModule.GetPlayerData().CitizenId
    if Calls.Log[CitizenId] == nil then Calls.Log[CitizenId] = {} end
    table.insert(Calls.Log[CitizenId], CallLog)
    
    if CurrentApp == 'calls' then
        exports['quantum-ui']:SendUIMessage("Phone", "RenderCallsApp", {
            Calls = Calls.Log[CitizenId] or {}
        })
    else
        SetAppUnread('calls', true)
    end
end)