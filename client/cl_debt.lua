Debt = {}

function Debt.Render()
    local Data = CallbackModule.SendCallback("quantum-phone/server/debts/get")
    exports['quantum-ui']:SendUIMessage("Phone", "RenderDebtApp", {
        Items = Data,
    })
end

RegisterNUICallback("Debt/GetDebt", function(Data, Cb)
    local Result = CallbackModule.SendCallback("quantum-phone/server/debts/get")
    Cb(Result)
end)

RegisterNUICallback("Debt/PayDebt", function(Data, Cb)
    local Result = CallbackModule.SendCallback("quantum-phone/server/debts/pay", Data)
    Cb(Result)
end)