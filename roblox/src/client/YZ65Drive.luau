--[[
	Client-side YZ65 drive.
	WASD is read locally (server never sees Throttle on server-owned seats).
	Requires network ownership on the rider (set by server when you sit).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local YZ65Drive = {}

local MAX_SPEED = 210 -- much faster than run (~20–55)
local ACCEL = 340
local BRAKE = 360
local TURN_RATE = 3.8
local AIR_CONTROL = 0.55

local player = Players.LocalPlayer

local function isGrounded(seat: BasePart): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local model = seat.Parent
	if model then
		params.FilterDescendantsInstances = { model, player.Character }
	end
	local hit = workspace:Raycast(seat.Position, Vector3.new(0, -5, 0), params)
	return hit ~= nil
end

local function getInput(): (number, number)
	local throttle = 0
	local steer = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
		throttle += 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
		throttle -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		steer -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		steer += 1
	end
	-- Mobile / controller via VehicleSeat when available
	return math.clamp(throttle, -1, 1), math.clamp(steer, -1, 1)
end

function YZ65Drive.start()
	RunService.RenderStepped:Connect(function(dt)
		dt = math.clamp(dt, 0, 0.05)
		local char = player.Character
		if not char then
			return
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then
			return
		end

		local seatPart = hum.SeatPart
		if not seatPart or not seatPart:IsA("VehicleSeat") then
			return
		end
		if not seatPart:GetAttribute("IsYZ65") then
			return
		end

		local seat = seatPart :: VehicleSeat
		local throttle, steer = getInput()
		-- Blend with seat floats if Roblox sets them (some platforms)
		if seat.ThrottleFloat ~= 0 then
			throttle = seat.ThrottleFloat
		elseif seat.Throttle ~= 0 then
			throttle = seat.Throttle
		end
		if seat.SteerFloat ~= 0 then
			steer = seat.SteerFloat
		elseif seat.Steer ~= 0 then
			steer = seat.Steer
		end

		local onGround = isGrounded(seat)
		local look = seat.CFrame.LookVector
		local flatLook = Vector3.new(look.X, 0, look.Z)
		if flatLook.Magnitude < 0.05 then
			flatLook = Vector3.new(0, 0, -1)
		else
			flatLook = flatLook.Unit
		end
		local right = Vector3.new(flatLook.Z, 0, -flatLook.X)

		local vel = seat.AssemblyLinearVelocity
		local horiz = Vector3.new(vel.X, 0, vel.Z)
		local speedAlong = horiz:Dot(flatLook)

		local control = onGround and 1 or AIR_CONTROL
		local targetSpeed = throttle * (throttle >= 0 and MAX_SPEED or MAX_SPEED * 0.55)
		local rate = (math.abs(targetSpeed) >= math.abs(speedAlong) and ACCEL or BRAKE) * control
		local newAlong = speedAlong + math.clamp(targetSpeed - speedAlong, -rate * dt, rate * dt)

		local lat = horiz:Dot(right)
		lat *= (1 - math.clamp(6 * dt * control, 0, 0.9))

		local newHoriz = flatLook * newAlong + right * lat
		local softCap = MAX_SPEED * 1.4
		if newHoriz.Magnitude > softCap then
			newHoriz = newHoriz.Unit * softCap
		end

		seat.AssemblyLinearVelocity = Vector3.new(newHoriz.X, vel.Y, newHoriz.Z)

		local moveFactor = math.clamp(math.abs(newAlong) / 16, 0.5, 1)
		if not onGround then
			moveFactor *= 0.55
		end
		local yaw = -steer * TURN_RATE * moveFactor
		if newAlong < -4 then
			yaw = -yaw
		end
		seat.AssemblyAngularVelocity = Vector3.new(
			seat.AssemblyAngularVelocity.X * 0.3,
			yaw,
			seat.AssemblyAngularVelocity.Z * 0.3
		)

		-- Keep mostly upright while rolling
		if onGround and math.abs(newAlong) > 3 then
			local cf = seat.CFrame
			local _, yRot, _ = cf:ToEulerAnglesYXZ()
			local upright = CFrame.new(cf.Position) * CFrame.Angles(0, yRot, 0)
			seat.CFrame = cf:Lerp(upright, math.clamp(5 * dt, 0, 0.4))
		end
	end)
end

return YZ65Drive
