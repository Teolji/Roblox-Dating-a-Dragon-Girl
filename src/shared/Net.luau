--[[
	Net
	Explorer: ReplicatedStorage > Hearthscale > Net (ModuleScript)

	Remote names. The server creates them under ReplicatedStorage >
	Hearthscale > Remotes at startup; clients wait for them.

	Request (RemoteFunction, client -> server): every player action goes
	through one validated, rate-limited entry point: Request:InvokeServer(action, args).
	Server -> client RemoteEvents:
	  StateSync   (state)              full copy of the player's own story state
	  Notify      ({ events })         quest/relationship/item notifications
	  SaveStatus  (status, message)    "ok" | "saving" | "failed" | "disabled" | "memory"
	  EndingShown (ending)             { id, title, tone, paragraphs }
	Minigame sessions and dialogue nodes travel in Request's return values.
]]

local Net = {}

Net.FolderName = "Remotes"
Net.Events = { "StateSync", "Notify", "SaveStatus", "EndingShown" }
Net.Functions = { "Request" }

function Net.createServer(parent: Instance)
	local folder = parent:FindFirstChild(Net.FolderName)
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = Net.FolderName
		folder.Parent = parent
	end
	local remotes = {}
	for _, name in ipairs(Net.Events) do
		local remote = folder:FindFirstChild(name) or Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		remotes[name] = remote
	end
	for _, name in ipairs(Net.Functions) do
		local remote = folder:FindFirstChild(name) or Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = folder
		remotes[name] = remote
	end
	return remotes
end

function Net.waitClient(parent: Instance)
	local folder = parent:WaitForChild(Net.FolderName)
	local remotes = {}
	for _, name in ipairs(Net.Events) do
		remotes[name] = folder:WaitForChild(name)
	end
	for _, name in ipairs(Net.Functions) do
		remotes[name] = folder:WaitForChild(name)
	end
	return remotes
end

return Net
