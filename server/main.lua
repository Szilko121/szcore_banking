local B={};local rate={}
local function player(source)return exports.szcore:GetPlayer(tonumber(source))end
local function amount(v,max)return exports.szcore:ValidateInteger(v,1,max)end

local function bankAccess(source)
    if SzCoreBankingConfig.allowCommandAnywhere then return true end
    local ped=GetPlayerPed(source);if ped==0 then return false end;local c=GetEntityCoords(ped)
    for _,b in ipairs(SzCoreBankingConfig.banks or{}) do local dx,dy,dz=c.x-b.coords.x,c.y-b.coords.y,c.z-b.coords.z;if dx*dx+dy*dy+dz*dz<=16.0 then return true end end
    return false
end
local function allowed(src,key,ms)local n=GetGameTimer();rate[src]=rate[src] or {};local p=rate[src][key] or 0;if n-p<ms then return false end;rate[src][key]=n;return true end
function B.transfer(source,target,value)
    source=tonumber(source);target=tonumber(target);local n=amount(value,SzCoreBankingConfig.transferLimit);if not n then return false,'invalid_amount' end
    if source==target then return false,'same_account' end
    local a,b=player(source),player(target);if not a or not b then return false,'player_not_found' end
    local ok,err=exports.szcore:TransferMoney({kind='player',id=a.PlayerData.citizenid,account='bank'},
        {kind='player',id=b.PlayerData.citizenid,account='bank'},n,'bank_transfer',a.PlayerData.citizenid)
    if not ok then return false,err end
    exports.szcore:Audit('bank.transfer',source,b.PlayerData.citizenid,{amount=n})
    TriggerClientEvent('szcore_ui:notify',target,{type='success',description=('Átutalás érkezett: $%d'):format(n)})
    return true
end
function B.deposit(source,value)
    local p=player(source);local n=amount(value,100000000);if not p or not n then return false,'invalid_request' end
    return exports.szcore:TransferMoney({kind='player',id=p.PlayerData.citizenid,account='cash'},
        {kind='player',id=p.PlayerData.citizenid,account='bank'},n,'bank_deposit',p.PlayerData.citizenid)
end
function B.withdraw(source,value)
    local p=player(source);local n=amount(value,100000000);if not p or not n then return false,'invalid_request' end
    return exports.szcore:TransferMoney({kind='player',id=p.PlayerData.citizenid,account='bank'},
        {kind='player',id=p.PlayerData.citizenid,account='cash'},n,'bank_withdraw',p.PlayerData.citizenid)
end
function B.statement(citizenid,limit)
    limit=math.max(1,math.min(tonumber(limit) or SzCoreBankingConfig.statementLimit,200))
    return MySQL.query.await('SELECT account,amount,balance,reason,created_at FROM szcore_money_ledger WHERE citizenid=? ORDER BY id DESC LIMIT '..limit,{citizenid}) or {}
end
function B.myStatement(source,limit)local p=player(source);return p and B.statement(p.PlayerData.citizenid,limit) or {}end
local function overview(source)
    if not bankAccess(source) then return nil,'too_far' end
    local p=player(source);if not p then return nil,'player_not_found' end
    return {name=p.PlayerData.name,citizenid=p.PlayerData.citizenid,cash=p.PlayerData.money.cash or 0,bank=p.PlayerData.money.bank or 0,crypto=p.PlayerData.money.crypto or 0,statement=B.statement(p.PlayerData.citizenid,SzCoreBankingConfig.statementLimit)}
end
local function action(source,action,data)
    if not bankAccess(source) then return false,'too_far' end
    if not allowed(source,'action',150) then return false,'rate_limited' end;data=type(data)=='table' and data or {}
    if action=='deposit' then return B.deposit(source,data.amount)
    elseif action=='withdraw' then return B.withdraw(source,data.amount)
    elseif action=='transfer' then return B.transfer(source,data.target,data.amount) end
    return false,'invalid_action'
end
exports('TransferPlayerBank',B.transfer);exports('DepositCash',B.deposit);exports('WithdrawCash',B.withdraw);exports('GetStatement',B.statement);exports('GetMyStatement',B.myStatement)
exports.szcore:CreateCallback('szcore_banking:overview',overview);exports.szcore:CreateCallback('szcore_banking:action',action)
AddEventHandler('playerDropped',function()rate[source]=nil end)
