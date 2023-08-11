--[[

	THIS MODULE MADE MY CAT SUS

			   LOG
  Discord: https://discord.gg/Y6SKaGvnEm
  Cr. Sythivo
--]]

local SETTINGS = {
	HearingPlayerWalkSpeed = 16,
	HearingRange = 50,
	HearingDelay = 10,
}

local PathfindingService = game:GetService('PathfindingService')
local Players = game:GetService('Players') 
local Thread = coroutine
local RaycastFilterType = Enum.RaycastFilterType
local AIEngine = {}

function AIEngine.Verify_Player(Player : Player)
	if not Player then
		return false
	end
	if Player.Character and Player.Character:FindFirstChildWhichIsA('Humanoid').Health > 0 then
		if Player.Character:FindFirstChild('Humanoid') then
			return Player
		end
	end
	return false
end

function CreateAnimationTrack(self : unknown,String_Id : string,AnimationType : Enum.AnimationPriority) : AnimationTrack
	local Animation = Instance.new('Animation')
	Animation.AnimationId = String_Id
	local AnimationTrack : AnimationTrack = self.Humanoid:LoadAnimation(Animation)
	AnimationTrack.Priority = AnimationType or Enum.AnimationPriority.Core
	return AnimationTrack
end

function AIEngine.Error()
	return ((true - 1) + false / 9)
end

function ShowDebug(Waypoints : Path)
	local debug_=workspace:FindFirstChild('Debug_Path') or Instance.new('Folder',workspace)
	debug_.Name = "Debug_Path"
 	for index,Path : PathWaypoint in ipairs(Waypoints:GetWaypoints()) do
		local PartStart = Instance.new('Part')
		local anti = Instance.new('PathfindingModifier',PartStart)
		anti.PassThrough = true
		PartStart.Color = Color3.fromRGB(255, 200, 0)
		if index == 1 then
			PartStart.Color = Color3.fromRGB(81, 255, 0)
		elseif index >= #Waypoints:GetWaypoints() then
			PartStart.Color = Color3.fromRGB(255, 0, 4)	
		end
		PartStart.Material = Enum.Material.Neon
		PartStart.Name = "Path__"..tostring(index)
		PartStart.Anchored = true
		PartStart.CanCollide = false
		local adds = Vector3.new(0,1,0)
		PartStart.CFrame = CFrame.lookAt(Path.Position + adds,(Waypoints:GetWaypoints()[index + 1] or Path).Position + adds)
		local Distance = ((Path.Position + adds) - ((Waypoints:GetWaypoints()[index + 1] or Path).Position + adds)).Magnitude
		if Distance < 0.1 then
			Distance = 0.1
		end
		PartStart.Size = Vector3.new(0.5,0.5,Distance / 2)
		PartStart.Parent = debug_
		local dis = (Waypoints:GetWaypoints()[1].Position - Path.Position).Magnitude
		game:GetService('Debris'):AddItem(PartStart,dis / 15)
	end
end

function AIEngine.new(model : Model,Path_data : {})
	if not model then warn("no found model") end
	local XZPlane = Vector3.new(1,0,1);
	local _AI_ = {
		Character = model;
		Path_Controller = PathfindingService:CreatePath(Path_data);
		Path_Data = Path_data;
		Humanoid = model:FindFirstChildWhichIsA('Humanoid');
		RootPart = model.PrimaryPart or model:FindFirstChild('HumanoidRootPart');
		Event = Instance.new('BindableEvent');
		OnJumpscare = Instance.new('BindableEvent');
		CanMove = true;
		SpeedConntroller = {
			WALK = 16;
			RUN = 22;
		};
		Path_Checker = PathfindingService:CreatePath({AgentCanJump = false});
	}
	
	_AI_.Debug = false
	_AI_.Chaseing = false
	_AI_.OnStartValue = false
	_AI_.SoundTarget = {}
	
	local _Raycast_ = RaycastParams.new()
	_Raycast_.FilterDescendantsInstances = {model}
	_Raycast_.FilterType = RaycastFilterType.Blacklist
	_Raycast_.RespectCanCollide = false
	_Raycast_.IgnoreWater = true

	function _AI_:GetPlayers()
		local _Player_ = nil
		local _max_distance_ = math.huge
		for index,Player in ipairs(Players:GetPlayers()) do
			if AIEngine.Verify_Player(Player) then
				local DISTANCE = (Player.Character.PrimaryPart.Position - _AI_.RootPart.Position).Magnitude
				if DISTANCE < _max_distance_ then
					_max_distance_ = DISTANCE
					_Player_ = Player
				end
			end
		end
		return _Player_
	end
	
	function _AI_:SetSpeed(Min,Max)
		_AI_.SpeedConntroller.WALK = Min
		_AI_.SpeedConntroller.RUN = Max
		return nil
	end
	
	function _AI_:CheckingPath(Target)
		_AI_.Path_Checker:ComputeAsync(_AI_.RootPart.Position,Target)
		if _AI_.Path_Checker.Status ~= Enum.PathStatus.NoPath then
			return true
		else
			return false
		end
	end
	
	function _AI_:GetDistance(Position : Vector3)
		local Distance  = (_AI_.RootPart.Position - Position).Magnitude
		return Distance
	end

	function _AI_:Raycast(User : Player,_debug_)
		if not User or not AIEngine.Verify_Player(User) then
			return
		end
		local UserPosition = User.Character.PrimaryPart.Position
		local Diartion = (UserPosition - _AI_.RootPart.Position).Unit * 1000
		local Look = _AI_.RootPart.CFrame.LookVector
		local Raycast = workspace:Raycast(_AI_.RootPart.Position,Diartion,_Raycast_)
		if Raycast and Raycast.Instance:IsDescendantOf(User.Character) then
			local Header = Diartion:Dot(Look)
			if Header > (_debug_ or 0.1) then
				return User
			end
		end
		return false
	end

	function _AI_:FindPlayers()
		local Founds = {}
		local genv = math.huge 
		local Locked = nil
		
		for index,User in ipairs(Players:GetPlayers()) do
			if AIEngine.Verify_Player(User) then
				if _AI_:Raycast(User) then
					table.insert(Founds,User)
				end
			end
		end
		
		for index,Target in ipairs(Founds) do
			if AIEngine.Verify_Player(Target) then
				local ENV = (Target.Character:GetPivot().Position - _AI_.RootPart.Position).Magnitude
				if ENV <= genv then
					genv = ENV
					Locked = Target
				end
			end
		end
		return Locked
	end
	
	function _AI_:GetMonsterWalking()
		return math.floor(_AI_.RootPart.Velocity.Magnitude)
	end
	
	function _AI_:listen_sounds()
		local RootPivot = _AI_.Character:GetPivot();
		local RootPosition = RootPivot.Position;
		local HeardPlayers = {};
		for _, Player in ipairs(Players:GetPlayers()) do
			if (AIEngine.Verify_Player(Player)) then
				local Character = Player.Character;
				if (Character) then
					local RootPart : BasePart = Character:FindFirstChild("HumanoidRootPart");
					if (RootPart and _AI_:CheckingPath(RootPart.Position)) then
						local Range = (Character:GetPivot().Position - RootPosition).Magnitude;
						if (((RootPart.AssemblyLinearVelocity * XZPlane).Magnitude/SETTINGS.HearingPlayerWalkSpeed)/Range * SETTINGS.HearingRange >= 1) then
							table.insert(HeardPlayers, Player);
						end
					end
				end
			end
		end
		if _AI_.Chaseing then
			_AI_.SoundTarget = {}
			return {}
		end
		return HeardPlayers;
	end
	
	function _AI_:MoveToFront()
		if not _AI_.CanMove then
			return
		end
		local RootPart = _AI_.RootPart.CFrame
		local Target = (RootPart * CFrame.new(0,0,-1.5)).Position
		_AI_.Humanoid:MoveTo(Target)
	end
		
	function _AI_:StartDeleteNetwork()
		for index,Object : BasePart | UnionOperation in ipairs(_AI_.Character:GetDescendants()) do
			if (Object:isA('BasePart') or Object:isA('UnionOperation')) then
				if not Object.Anchored then
					Object:SetNetworkOwner(nil)
					Object.Changed:Connect(function()
						if not Object.Anchored then
							Object:SetNetworkOwner(nil)
						end
					end)
				end
			end
		end
	end

	function _AI_:StartChase(Player : Player)
		if not _AI_.CanMove then
			return
		end
		if (AIEngine.Verify_Player(Player) and _AI_.Chaseing) then
			if _AI_:Raycast(Player,-0.5) then
				local PrimaryPart = Player.Character.PrimaryPart
				local Depos = PrimaryPart.Velocity / 5
				_AI_.Humanoid:MoveTo(Player.Character:GetPivot().Position + Depos)
				
			else
	
				_AI_.Path_Controller:ComputeAsync(_AI_.RootPart.Position,Player.Character.PrimaryPart.Position)
				if _AI_.Debug then
					ShowDebug(_AI_.Path_Controller)
				end
				pcall(function()
					for index,PathPoint : PathWaypoint in ipairs(_AI_.Path_Controller:GetWaypoints()) do
						if index > 1 and index <= 5 then
							local Target = PathPoint.Position
							local Action = PathPoint.Action
							local Next = false
							_AI_.Humanoid:MoveTo(Target)
							_AI_.Humanoid.MoveToFinished:Connect(function() Next = true end)
							repeat local Distance = _AI_:GetDistance(Target) task.wait() if Action == Enum.PathWaypointAction.Jump then _AI_.Humanoid.Jump = true end until not AIEngine.Verify_Player(Player) or Next or not _AI_.Chaseing or Distance >= 20 or _AI_:Raycast(Player,-0.5) or not  _AI_.CanMove
							if (not AIEngine.Verify_Player(Player) or not _AI_.Chaseing or _AI_:Raycast(Player,-0.5) or not  _AI_.CanMove) then
								AIEngine.Error()
								return
							end
						else
							if index >= 5 then
								_AI_:MoveToFront()
								AIEngine.Error()
								return
							end
						end
					end
				end)
				if _AI_.Path_Controller.Status == Enum.PathStatus.NoPath then
					_AI_.Chaseing = false
					return false
				end
			end
			return true
		end
	end

	local function MonvementFolder(Folder : Folder)
		if not _AI_.CanMove then
			return
		end
		for index,Target : BasePart in ipairs(Folder:GetChildren()) do
			if Target:isA('BasePart') then
				_AI_.Path_Controller:ComputeAsync(_AI_.RootPart.Position,Target.Position)
				if _AI_.Debug then
					ShowDebug(_AI_.Path_Controller)
				end
				pcall(function()
					for index,PathPoint : PathWaypoint in ipairs(_AI_.Path_Controller:GetWaypoints()) do
						if index > 1 then
							local TargetPoint = PathPoint.Position
							local Action = PathPoint.Action
							local Next = false
							_AI_.Humanoid:MoveTo(TargetPoint)
							_AI_.Humanoid.MoveToFinished:Connect(function() Next = true end)
							repeat local Distance = _AI_:GetDistance(TargetPoint) task.wait() if Action == Enum.PathWaypointAction.Jump then _AI_.Humanoid.Jump = true end until _AI_:FindPlayers() or Next or _AI_.SoundTarget[1] or Distance >= 20 or not _AI_.CanMove

							if (_AI_:FindPlayers() or _AI_.Chaseing or _AI_.SoundTarget[1] or not _AI_.CanMove) then
								AIEngine.Error()
								break
							end
						end
					end
				end)
				if (_AI_:FindPlayers() or _AI_.Chaseing or _AI_.SoundTarget[1] or not _AI_.CanMove) then
					return true
				end
			end
		end
	end

	function _AI_:Movement(Folder : Folder)
		if not _AI_.CanMove then
			return
		end
		if not _AI_.SoundTarget[1] then
			MonvementFolder(Folder)
		else
			if AIEngine.Verify_Player(_AI_.SoundTarget[1]) then
				local Player : Player = _AI_.SoundTarget[1]
				_AI_.Path_Controller:ComputeAsync(_AI_.RootPart.Position,Player.Character.PrimaryPart.Position)
				if _AI_.Debug then
					ShowDebug(_AI_.Path_Controller)
				end
				pcall(function()
					for index,PathPoint : PathWaypoint in ipairs(_AI_.Path_Controller:GetWaypoints()) do
						if index > 1 then
							local TargetPoint = PathPoint.Position
							local Action = PathPoint.Action
							local Next = false
							_AI_.Humanoid:MoveTo(TargetPoint)
							_AI_.Humanoid.MoveToFinished:Connect(function() Next = true end)
							repeat local Distance = _AI_:GetDistance(TargetPoint) task.wait() if Action == Enum.PathWaypointAction.Jump then _AI_.Humanoid.Jump = true end until _AI_:FindPlayers() or Next or Distance >= 20 or not _AI_.CanMove
							if (_AI_:FindPlayers() or _AI_.Chaseing or not _AI_.CanMove) then
								AIEngine.Error()
								break
							end
						end
					end
				end)
				_AI_.SoundTarget = {}
				return true
			else
				MonvementFolder(Folder)
			end
		end
		return true
	end
	
	function _AI_:StartDebugMove()
		Thread.wrap(function()
			local TICK = 0
			local LastPosition = _AI_.RootPart.Position
			while wait(1) do
				pcall(function()
					if _AI_:GetMonsterWalking() <= 0.5 then
						TICK += 1
						if TICK >= 5 then
							if not _AI_.Chaseing then
								_AI_.RootPart.CFrame = CFrame.new(LastPosition)
							end
							TICK = 0
							_AI_.Chaseing = false
						end
					end
					LastPosition = _AI_.RootPart.Position
				end)
			end
		end)()
	end
	
	function _AI_:GetRaycast(Targets)
		local genv = math.huge
		local TargetLocked = nil
		for i,v : Player in ipairs(Targets) do
			if (AIEngine.Verify_Player(v) and _AI_:Raycast(v)) then
				local env = (v.Character:GetPivot().Position - _AI_.RootPart.Position).Magnitude
				if env < genv then
					TargetLocked = v
					genv = env
				end
			end
		end
		return TargetLocked
	end 
	
	
	function _AI_:OnStart(assignment)
		_AI_.OnStartValue = true
		local Folder = assignment.LoopPoints
		local On_listen_sounds = assignment.listen_sounds
		_AI_:StartDeleteNetwork()
		_AI_:StartDebugMove()
		for i,v : BasePart | UnionOperation in ipairs(_AI_.Character:GetDescendants()) do
			if (v:isA('BasePart') or v:isA('UnionOperation')) then
				v.Touched:Connect(function(HIT)
					if _AI_.CanMove then
						local Player = game:GetService('Players'):GetPlayerFromCharacter(HIT.Parent)
						if Player and Player.Character then
							if Player.Character:FindFirstChild('Humanoid').Health > 0 then
								_AI_.OnJumpscare:Fire(Player)
								Player.Character:FindFirstChild('Humanoid').Health = 0
							end
						end
					end
				end)
			end
		end
		
		-- On Loadded --
		Thread.wrap(function() 
			while wait(SETTINGS.HearingDelay) do
				if On_listen_sounds then
					_AI_.SoundTarget = _AI_:listen_sounds()
				else
					_AI_.SoundTarget = {}
				end
			end
		end)()
		
		Thread.wrap(function()
			while true do task.wait()
				local error_,call = pcall(function()
					if _AI_:FindPlayers() then
						_AI_.Chaseing = true
						local Target = _AI_:FindPlayers()
						_AI_.Event:Fire(Target,true)
						local Targets = {Target}
						local TargetLocked = Target
						repeat task.wait()
							_AI_.Humanoid.WalkSpeed = _AI_.SpeedConntroller.RUN
							if _AI_:FindPlayers() then
								if not table.find(Targets,_AI_:FindPlayers()) then
									table.insert(Targets,_AI_:FindPlayers())
									TargetLocked = _AI_:FindPlayers()
									_AI_.Event:Fire(TargetLocked,true)
								end
							end
							TargetLocked = _AI_:GetRaycast(Targets) or Target
							_AI_:StartChase(TargetLocked)
						until not AIEngine.Verify_Player(TargetLocked) or not _AI_.Chaseing
						_AI_.Chaseing = false
						for i,v in ipairs(Targets) do
							_AI_.Event:Fire(v,false)
						end
					else
						_AI_.Humanoid.WalkSpeed = _AI_.SpeedConntroller.WALK
						
						_AI_:Movement(Folder)
					end
				end)
				if call then
					warn(call)
				end
			end
		end)()
	end
	
	function _AI_:StartAnimation(assignment)
		local Anims = {
			walk = CreateAnimationTrack(_AI_,assignment['WALK'],Enum.AnimationPriority.Movement);
			run = CreateAnimationTrack(_AI_,assignment['RUN'],Enum.AnimationPriority.Movement);
			idle = CreateAnimationTrack(_AI_,assignment['IDLE'],Enum.AnimationPriority.Idle);
			Jumpscare = CreateAnimationTrack(_AI_,assignment['JUMPSCARE'],Enum.AnimationPriority.Action4);
		}
		local SPEED_WALK = _AI_.Humanoid.WalkSpeed
		Thread.wrap(function()
			while wait() do
				local CurrentSpeed = _AI_:GetMonsterWalking() / _AI_.SpeedConntroller.WALK
				local Distance = _AI_:GetMonsterWalking()
				Anims.walk:AdjustSpeed(CurrentSpeed)
				Anims.run:AdjustSpeed(CurrentSpeed)
				if Distance > 0.05 then
					if _AI_.Humanoid.WalkSpeed > SPEED_WALK then
						if not Anims.run.IsPlaying then
							Anims.run:Play()
						end 
						task.wait(0.5)
						if _AI_.Humanoid.WalkSpeed > SPEED_WALK then
							Anims.walk:Stop(.5)
						end
					else
						if not Anims.walk.IsPlaying then
							Anims.walk:Play()
						end
						task.wait(0.5)
						if _AI_.Humanoid.WalkSpeed < SPEED_WALK then
							Anims.run:Stop(.5)
						end
					end
				else
					local CurrentSpeed = _AI_:GetMonsterWalking() / _AI_.SpeedConntroller.WALK
					if not Anims.idle.IsPlaying then
						Anims.idle:Play(0.5)
					end
					wait(0.5)
					if CurrentSpeed < 0.05 then
						Anims.run:Stop(0.3)
						Anims.walk:Stop(0.3)
					end
				end
			end
		end)()
		_AI_.OnJumpscare.Event:Connect(function()
			if Anims.Jumpscare.Animation.AnimationId ~= "" then
				_AI_.CanMove = false
				Anims.Jumpscare:Play()
				wait(3)
				Anims.Jumpscare:Stop(
				)
				_AI_.CanMove = true
			end
		end)
	end
	
	return _AI_
end

return AIEngine
