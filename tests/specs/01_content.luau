-- Static validation of every data table (dialogue graph, quest ids, anchors, flags).
return function(T, root, gameRequire)
	local Config = gameRequire(root.Config)
	local Content = gameRequire(root.Content)
	local Validator = gameRequire(root.Systems.ContentValidator)

	local function ctxWith(overrides)
		local cfg = table.clone(Config)
		for k, v in pairs(overrides or {}) do
			cfg[k] = v
		end
		return { content = Content, config = cfg }
	end

	T.test("content: validator finds no problems", function()
		local errors = Validator.validate(ctxWith())
		if #errors > 0 then
			error("\n        " .. table.concat(errors, "\n        "))
		end
	end)

	T.test("content: every conversation id is unique and indexed by npc", function()
		local count = 0
		for _ in pairs(Content.Conversations) do
			count += 1
		end
		local indexed = 0
		for _, list in pairs(Content.ConversationsByNpc) do
			indexed += #list
		end
		T.eq(indexed, count, "indexed conversations")
		T.ok(count >= 25, "at least 25 conversations")
	end)

	T.test("content: dragon is clearly an adult in dialogue", function()
		-- Romance content requires the love interest to be unambiguously adult.
		local found = false
		for _, conv in pairs(Content.Conversations) do
			for _, node in pairs(conv.nodes) do
				if node.text and string.find(node.text, "twenty-six", 1, true) then
					found = true
				end
			end
		end
		T.ok(found, "age line present")
		T.ok(string.find(Content.Characters.saffron.bio, "twenty-six", 1, true) ~= nil, "bio states adult age")
	end)

	T.test("content: validator catches broken content (mutation check)", function()
		local broken = table.clone(Content)
		broken.Conversations = table.clone(Content.Conversations)
		broken.Conversations.__broken = {
			npc = "nobody",
			start = "a",
			when = { flag = "never_set_anywhere", bogusKey = true },
			nodes = {
				a = { text = "hi", choices = { { text = "x", when = { flag = "y" }, next = "missing" } } },
				orphan = { text = "unreachable" },
			},
			onEnd = { give = "not_an_item", startQuest = "q_nope" },
		}
		local errors = Validator.validate({ content = broken, config = Config })
		local joined = table.concat(errors, "\n")
		for _, expected in ipairs({
			"unknown npc",
			"unknown condition key 'bogusKey'",
			"missing node 'missing'",
			"node is unreachable",
			"always available",
			"unknown item 'not_an_item'",
			"unknown quest 'q_nope'",
			"flag 'never_set_anywhere' is checked but never set",
		}) do
			T.ok(string.find(joined, expected, 1, true) ~= nil, "validator reports: " .. expected)
		end
	end)
end
