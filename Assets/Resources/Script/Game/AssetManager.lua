
local logChannel = _Engine.logChannel
local channel = "asset_manager"

local new = typesys.new

---------

AssetManager = typesys.AssetManager {
	prefab_creature = typesys.unmanaged,
}

local LoadAsset = UnityEngine.Resources.Load
-- local UnloadAsset = UnityEngine.Resources.UnloadAsset
local Instantiate = UnityEngine.Object.Instantiate

function AssetManager:ctor()
	self.prefab_creature = LoadAsset("creature")
end

function AssetManager:dtor()
end

function AssetManager:newCreature(name)
	return new(GameObjectHandler, Instantiate(self.prefab_creature), name)
end