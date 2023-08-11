# AI MIMIC BOOK 2 - MAKE BY CAT_SUS

## ⬇ Module Source ⬇
https://github.com/3345-c-a-t-s-u-s/AI-Mimic-Source/blob/main/AISource.lua

## How to use?
Source
```lua
local MimicEngine = require(game:GetService('ServerScriptService'):WaitForChild('Engine'))

local AI = MimicEngine.new(script.Parent,{
	AgentRadius = 1/10,
	AgentHeight = 6,
	AgentCanJump = true,
})


AI:StartAnimation({
	["WALK"] = "rbxassetid://13686192301";
	["RUN"] = "rbxassetid://13678229946";
	["IDLE"] = "rbxassetid://13686186797";
	["JUMPSCARE"] = "rbxassetid://13757518991";
})

AI.OnJumpscare.Event:Connect(function(Player)
	print("Jumpsare :",Player)
end)

AI.Event.Event:Connect(function(TargetChase,Boolen)
	if Boolen then
		print("Chase :",TargetChase)
	else
		print("Unchase :",TargetChase)
	end
end)

AI.Debug = false
local Assignment = {
	['LoopPoints'] = workspace:WaitForChild('LoopPoints'),
	['listen_sounds'] = true,
}

AI:OnStart(Assignment)
```
