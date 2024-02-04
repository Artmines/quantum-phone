--[[
    App: Documents
]]

Documents = {}

function Documents.Render()
    local Result = CallbackModule.SendCallback("quantum-phone/server/documents/get-by-citizenid")
    exports['quantum-ui']:SendUIMessage("Phone", "RenderDocumentsApp", {
        Documents = Result
    })
end

RegisterNUICallback("Documents/NewDocument", function(Data, Cb)
    local Result = CallbackModule.SendCallback("quantum-phone/server/documents/new", Data)
    Cb(Result)
end)

RegisterNUICallback("Documents/GetDocumentData", function(Data, Cb)
    local Result = CallbackModule.SendCallback("quantum-phone/server/documents/get-data", Data)
    Cb(Result)
end)

RegisterNUICallback("Documents/GetDocumentsByType", function(Data, Cb)
    local Documents = CallbackModule.SendCallback("quantum-phone/server/documents/get-by-type", Data)
    Cb(Documents)   
end)

RegisterNUICallback("Documents/ShareLocal", function(Data, Cb)
    TriggerServerEvent('quantum-phone/server/documents/share', Data)
end)

RegisterNUICallback("Documents/Save", function(Data, Cb)
    local Documents = CallbackModule.SendCallback("quantum-phone/server/documents/save", Data)
    Cb(Documents)
end)

RegisterNUICallback("Documents/Delete", function(Data, Cb)
    local Documents = CallbackModule.SendCallback("quantum-phone/server/documents/delete", Data)
    Cb(Documents)
end)

-- [ Events ] --

RegisterNetEvent('quantum-phone/client/documents/refresh', function()
    Documents.Render()
end)