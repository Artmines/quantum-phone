--[[
    App: Twitter
]]

Twitter = {}
Twitter.Tweets = {}

function Twitter.Render()
    SetAppUnread('twitter', false)
    local Businesses = CallbackModule.SendCallback('quantum-business/server/get-employed-businesses')
    exports['quantum-ui']:SendUIMessage("Phone", "RenderTwitterApp", {
        Tweets = Twitter.Tweets or {},
        Businesses = Businesses
    })
end

RegisterNUICallback("Twitter/PostTweet", function(Data, Cb)
    EventsModule.TriggerServer("quantum-phone/server/twitter-post", Data)
    Cb('Ok')
end)

RegisterNetEvent('quantum-phone/client/twitter-clear', function()
    Twitter.Tweets = {}

    local Businesses = CallbackModule.SendCallback('quantum-business/server/get-employed-businesses')
    if CurrentApp == 'twitter' then
        exports['quantum-ui']:SendUIMessage("Phone", "RenderTwitterApp", {
            Tweets = Twitter.Tweets or {},
            Businesses = Businesses
        })
    end
end)

RegisterNetEvent("quantum-phone/client/twitter/sync-tweets", function(Tweet)
    table.insert(Twitter.Tweets, Tweet)

    if CurrentApp == 'twitter' then
        exports['quantum-ui']:SendUIMessage("Phone", "RenderNewTweet", {
            Tweet = Tweet,
        })
    else
        SetAppUnread('twitter', true)
    end
end)