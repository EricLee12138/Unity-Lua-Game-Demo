
_Engine = {
	log = LogProxy.log,
	logWarning = LogProxy.logWarning,
	logError = LogProxy.logError,
	logChannel = LogProxy.logChannel,
	logWarningChannel = LogProxy.logWarningChannel,
	logErrorChannel = LogProxy.logErrorChannel,
}

-- 1. header
require("TypeSystemHeader")
-- 2. external type
require("ExternalTypes")
-- 3. my type
require("GameObjectHandler")
require("Ground")
require("MyAssetManager")

-- 4. my ecs
require("ECSHeader")
require("MyComponents")
-- require("Components")
require("Entities")
require("Player")
require("Enemy")
require("Coin")
require("Camera")

require("SystemMove")
require("SystemEnemyAI")
require("SystemAnimation")
require("SystemControl")
require("SystemDamage")
require("SystemCollect")
require("SystemDeath")

require("MyWorld")

local Time = UnityEngine.Time

local new = typesys.new
local delete = typesys.delete

local log = _Engine.log
local logWarning = _Engine.logWarning
local logError = _Engine.logError
local logChannel = _Engine.logChannel
local logWarningChannel = _Engine.logWarningChannel
local logErrorChannel = _Engine.logErrorChannel

local channel = "engine"

local world = new(World)

function _Engine.register(obj)
	world:register(obj)
end

function _Engine.unregister(obj)
	world:unregister(obj)
end

function _Engine.start()
	if nil == world then
		world = new(World)
	end
	world._owner = true
end

function _Engine.update()
	world:update(Time.time, Time.deltaTime)
	typesys.deleteNoOwnerObjects()

	-- logChannel(channel, "gc alloc: {0:N}", collectgarbage("count"))
end

function _Engine.lateupdate()
	world:lateupdate(Time.time, Time.deltaTime)
end

function _Engine.shutdown()
	if nil ~= world then
		world._owner = false
		delete(world)
		world = nil
	end
	typesys.deleteNoOwnerObjects()
end