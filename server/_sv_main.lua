CallbackModule, PlayerModule, FunctionsModule, DatabaseModule, CommandsModule, EventsModule = nil, nil, nil, nil, nil, nil

_Ready = false
AddEventHandler('Modules/server/ready', function()
    TriggerEvent('Modules/server/request-dependencies', {
        'Callback',
        'Player',
        'Functions',
        'Database',
        'Commands',
        'Events',
    }, function(Succeeded)
        if not Succeeded then return end
        CallbackModule = exports['quantum-base']:FetchModule('Callback')
        PlayerModule = exports['quantum-base']:FetchModule('Player')
        FunctionsModule = exports['quantum-base']:FetchModule('Functions')
        DatabaseModule = exports['quantum-base']:FetchModule('Database')
        CommandsModule = exports['quantum-base']:FetchModule('Commands')
        EventsModule = exports['quantum-base']:FetchModule('Events')
        _Ready = true
    end)
end)

function IsInContacts(Player, ContactNumber)
    local Promise = promise:new()
    DatabaseModule.Execute('SELECT * FROM player_phone_contacts WHERE number = ? AND citizenid = ?', {
        ContactNumber,
        Player.PlayerData ~= nil and Player.PlayerData.CitizenId or Player
    }, function(Contacts)
        if Contacts[1] ~= nil then
            Promise:resolve({true, Contacts[1].name})
        else
            Promise:resolve(false)
        end
    end, true)
    return Citizen.Await(Promise)
end