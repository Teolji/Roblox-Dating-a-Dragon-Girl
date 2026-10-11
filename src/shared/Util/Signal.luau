--[[
	Signal
	Explorer: ReplicatedStorage > Hearthscale > Util > Signal (ModuleScript)

	Minimal synchronous signal for client-side state notifications.
]]

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal:Connect(fn: (...any) -> ())
	local handlers = self._handlers
	local entry = { fn = fn, connected = true }
	table.insert(handlers, entry)
	return {
		Disconnect = function()
			entry.connected = false
			local index = table.find(handlers, entry)
			if index then
				table.remove(handlers, index)
			end
		end,
	}
end

function Signal:Fire(...: any)
	-- Copy so handlers can disconnect while firing.
	local snapshot = table.clone(self._handlers)
	for _, entry in ipairs(snapshot) do
		if entry.connected then
			task.spawn(entry.fn, ...)
		end
	end
end

return Signal
