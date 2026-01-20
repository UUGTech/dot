return {
	"letieu/jira.nvim",
	event = "VeryLazy",
	opts = {},
	keys = {
		{
			"<leader>jj",
			function()
				local project_key = vim.fn.getenv("JIRA_PROJECT_KEY")
				if project_key ~= vim.NIL and project_key ~= "" then
					vim.cmd("Jira " .. project_key)
				else
					vim.cmd("Jira")
				end
			end,
			desc = "Open Jira",
		},
	},
	config = function()
		require("jira").setup({
			-- Jira connection settings
			jira = {
				base = vim.fn.getenv("JIRA_BASE_URL") or "https://your-domain.atlassian.net", -- Your Jira base URL
				email = vim.fn.getenv("JIRA_EMAIL") or "your-email@example.com", -- Your Jira email (Optional for PAT)
				token = vim.fn.getenv("JIRA_TOKEN") or "your-api-token", -- Your Jira API token or PAT
				type = "basic", -- Authentication type: "basic" (default) or "pat"
				limit = 200, -- Global limit of tasks per view (default: 200)
			},

			active_sprint_query = "project = '%s' AND sprint in openSprints() ORDER BY Rank ASC",

			-- Saved JQL queries for the JQL tab
			-- Use %s as a placeholder for the project key
			queries = {
				["Next sprint"] = "project = '%s' AND sprint in futureSprints() ORDER BY Rank ASC",
				["Backlog"] = "project = '%s' AND (issuetype IN standardIssueTypes() OR issuetype = Sub-task) AND (sprint IS EMPTY OR sprint NOT IN openSprints()) AND statusCategory != Done ORDER BY Rank ASC",
				["My Tasks"] = "project = '%s' AND assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC",
			},

			-- Project-specific overrides
			-- Still think about this config, maybe not good enough
			projects = {
				["DEV"] = {
					story_point_field = "customfield_10035", -- Custom field ID for story points
					custom_fields = { -- Custom field to display in markdown view
						{ key = "customfield_10016", label = "Acceptance Criteria" },
					},
				},
			},
		})
	end,
}
