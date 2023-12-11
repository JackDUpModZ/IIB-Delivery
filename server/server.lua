local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('IIB-Delivery:Reward', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local value = math.random(Config.Reward.min,Config.Reward.max)
    Player.Functions.AddMoney("cash", value)
    TriggerClientEvent("QBCore:Notify", src, 'You Received $'..value, 'success')
end)