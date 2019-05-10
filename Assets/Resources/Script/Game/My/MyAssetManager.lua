
local logChannel = _Engine.logChannel
local channel = "asset_manager"

local new = typesys.new

---------

AssetManager = typesys.AssetManager {
	prefab_player = typesys.unmanaged,
	prefab_enemy = typesys.unmanaged,
	prefab_block = typesys.unmanaged,
}

local LoadAsset = UnityEngine.Resources.Load
-- local UnloadAsset = UnityEngine.Resources.UnloadAsset
local Instantiate = UnityEngine.Object.Instantiate

function AssetManager:ctor()
	self.prefab_player = LoadAsset("Prefab/Player")
	self.prefab_enemy = LoadAsset("Prefab/Enemy")
	self.prefab_block = LoadAsset("Prefab/Block")
end

function AssetManager:dtor()
end

function AssetManager:newPlayer(name)
	return new(GameObjectHandler, Instantiate(self.prefab_player), name)
end

function AssetManager:newEnemy(name)
	return new(GameObjectHandler, Instantiate(self.prefab_enemy), name)
end

function AssetManager:newBlock(name)
	return new(GameObjectHandler, Instantiate(self.prefab_block), name)
end