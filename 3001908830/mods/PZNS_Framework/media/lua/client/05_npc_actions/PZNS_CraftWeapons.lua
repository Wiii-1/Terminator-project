local PZNS_UtilsNPCs = require("02_mod_utils/PZNS_UtilsNPCs")

--- Craft improvised weapons from available materials
---@param npcSurvivor PZNS_NPCSurvivor
---@param weaponType string Type of weapon to craft ("melee", "ranged", "explosive")
function PZNS_CraftWeapons(npcSurvivor, weaponType)
    if not PZNS_UtilsNPCs.IsNPCSurvivorIsoPlayerValid(npcSurvivor) then
        return
    end
    
    local npcIsoPlayer = npcSurvivor.npcIsoPlayerObject
    local inventory = npcIsoPlayer:getInventory()
    
    weaponType = weaponType or "melee"
    
    print("[CraftWeapons] Attempting to craft weapon type:", weaponType)
    
    -- Simple crafting system: check for materials and spawn weapon
    if weaponType == "melee" then
        -- Check for materials like wood, metal, etc.
        local hasMaterials = false
        
        -- Check inventory for common items
        if inventory:contains("TreeBranch") or 
           inventory:contains("Plank") or 
           inventory:contains("Pipe") then
            hasMaterials = true
        end
        
        if hasMaterials or ZombRand(100) < 30 then -- 30% chance to improvise
            -- Spawn improvised melee weapon
            local improvisedWeapons = {
                "Base.TreeBranch",
                "Base.Plank",
                "Base.Pipe",
                "Base.WoodAxe",
                "Base.Crowbar",
                "Base.BaseballBat"
            }
            
            local weapon = improvisedWeapons[ZombRand(#improvisedWeapons) + 1]
            local item = inventory:AddItem(weapon)
            
            if item then
                npcIsoPlayer:setPrimaryHandItem(item)
                npcIsoPlayer:setSecondaryHandItem(item)
                print("[CraftWeapons] Crafted melee weapon:", weapon)
            end
        else
            print("[CraftWeapons] No materials for melee weapon, searching area")
            -- Search nearby for materials
            local square = npcIsoPlayer:getSquare()
            if square then
                -- Try to find items on ground
                local worldItems = square:getWorldObjects()
                for i = 0, worldItems:size() - 1 do
                    local worldItem = worldItems:get(i)
                    local item = worldItem:getItem()
                    if item and item:IsWeapon() then
                        inventory:AddItem(item)
                        square:removeItem(worldItem)
                        npcIsoPlayer:setPrimaryHandItem(item)
                        print("[CraftWeapons] Found weapon on ground:", item:getName())
                        return
                    end
                end
            end
        end
        
    elseif weaponType == "ranged" then
        -- Craft simple ranged weapon
        local rangedWeapons = {
            "Base.Pistol",
            "Base.Shotgun",
            "Base.VarmintRifle"
        }
        
        local weapon = rangedWeapons[ZombRand(#rangedWeapons) + 1]
        local item = inventory:AddItem(weapon)
        
        if item then
            -- Add ammo
            local ammoType = "Base.Bullets9mm"
            if weapon:contains("Shotgun") then
                ammoType = "Base.ShotgunShells"
            elseif weapon:contains("Rifle") then
                ammoType = "Base.223Bullets"
            end
            
            inventory:AddItems(ammoType, 30)
            
            -- Load weapon
            if instanceof(item, "HandWeapon") and item:isRanged() then
                item:setMaxAmmo(item:getMaxAmmo())
                item:setCurrentAmmoCount(item:getMaxAmmo())
            end
            
            npcIsoPlayer:setPrimaryHandItem(item)
            npcIsoPlayer:setSecondaryHandItem(item)
            print("[CraftWeapons] Crafted ranged weapon:", weapon, "with ammo:", ammoType)
        end
        
    elseif weaponType == "explosive" then
        -- Craft/spawn explosive
        local explosives = {
            "Base.Molotov",
            "Base.RemoteCraftedBomb",
            "Base.PipeBomb"
        }
        
        local explosive = explosives[ZombRand(#explosives) + 1]
        local item = inventory:AddItem(explosive)
        
        if item then
            -- Add lighter for molotov
            if explosive == "Base.Molotov" then
                inventory:AddItem("Base.Lighter")
            end
            
            print("[CraftWeapons] Crafted explosive:", explosive)
        end
    else
        print("[CraftWeapons] Unknown weapon type:", weaponType)
    end
end

return { PZNS_CraftWeapons = PZNS_CraftWeapons }
