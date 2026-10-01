local open=false
local function notify(t,typ)exports.szcore_ui:Notify({description=t,type=typ or 'info'})end
local function refresh()local d=exports.szcore:AwaitCallback('szcore_banking:overview');if d and open then SendNUIMessage({action='data',data=d})end end
local function show()
    if not exports.szcore:IsPlayerLoaded() then return end
    local d,err=exports.szcore:AwaitCallback('szcore_banking:overview');if not d then return notify(err or 'Bank nem elérhető.','error')end
    open=true;SetNuiFocus(true,true);SendNUIMessage({action='open',data=d})
end
local function close()open=false;SetNuiFocus(false,false);SendNUIMessage({action='close'})end
RegisterCommand(SzCoreBankingConfig.command,function()if SzCoreBankingConfig.allowCommandAnywhere then show()end end,false)
RegisterKeyMapping(SzCoreBankingConfig.command,'SzCore Banking','keyboard',SzCoreBankingConfig.key)
RegisterNUICallback('close',function(_,cb)close();cb({ok=true})end)
RegisterNUICallback('action',function(d,cb)local ok,err=exports.szcore:AwaitCallback('szcore_banking:action',d.action,d);if ok then notify('Banki művelet sikeres.','success');refresh()else notify(err or 'Sikertelen művelet.','error')end;cb({ok=ok,error=err})end)
exports('OpenBank',show)
local function addZones()
    if GetResourceState('szcore_interact')~='started' then return end
    for i,b in ipairs(SzCoreBankingConfig.banks) do
        exports.szcore_interact:AddSphereZone({name='szcore_bank_'..i,coords=b.coords,radius=1.6,distance=2.0,options={{label='Bank megnyitása',icon='bank',callback=show}}})
    end
end
AddEventHandler('onClientResourceStart',function(res)if res=='szcore_interact' or res==GetCurrentResourceName() then SetTimeout(600,addZones)end end)
