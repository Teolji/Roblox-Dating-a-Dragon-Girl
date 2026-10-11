--[[
	Dialogue (aggregator)
	Explorer: ReplicatedStorage > Hearthscale > Content > Dialogue (ModuleScript)

	Merges every child module into one { [conversationId] = conversation }
	table. Add a new ModuleScript here to add conversations; ids must be unique.
]]

local merged = {}

for _, child in ipairs(script:GetChildren()) do
	if child:IsA("ModuleScript") then
		for id, conversation in pairs(require(child)) do
			assert(merged[id] == nil, `Duplicate conversation id '{id}' in {child.Name}`)
			merged[id] = conversation
		end
	end
end

return merged
