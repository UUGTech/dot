local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

M.NEW_SESSION_ID = "__new__"

---@type drover.Agent
local NEW_SESSION_ENTRY = {
	pane_id = M.NEW_SESSION_ID,
	agent = "+ New session",
	agent_status = "",
	cwd = "",
}

---@param agents drover.Agent[]
---@param on_choice fun(choice: drover.Agent)
function M.pick(agents, on_choice)
	local entries = { NEW_SESSION_ENTRY }
	vim.list_extend(entries, agents)

	pickers
		.new({}, {
			prompt_title = "drover: send to",
			finder = finders.new_table({
				results = entries,
				entry_maker = function(entry)
					local label = string.format(
						"%-8s %-12s %s",
						entry.agent_status or "",
						entry.agent or "unknown",
						entry.cwd or ""
					)
					return {
						value = entry,
						display = label,
						ordinal = label,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, _)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if selection then
						on_choice(selection.value)
					end
				end)
				return true
			end,
		})
		:find()
end

return M
