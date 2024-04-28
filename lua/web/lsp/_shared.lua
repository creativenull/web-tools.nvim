local M = {}

function M.register_lsp_cmds(bufnr)
	vim.api.nvim_buf_create_user_command(bufnr, "WebQuickfixAction", function(cmd)
		vim.lsp.buf.code_action({
			context = { only = { "quickfix" }, triggerKind = 1 },
			range = {
				["start"] = { cmd.line1, 0 },
				["end"] = { cmd.line2, 0 },
			},
		})
	end, { range = true })

	vim.api.nvim_buf_create_user_command(bufnr, "WebRefactorAction", function(cmd)
		vim.lsp.buf.code_action({
			context = { only = { "refactor" }, triggerKind = 1 },
			range = {
				["start"] = { cmd.line1, 0 },
				["end"] = { cmd.line2, 0 },
			},
		})
	end, { range = true })

	vim.api.nvim_buf_create_user_command(bufnr, "WebSourceAction", function(cmd)
		vim.lsp.buf.code_action({
			context = { only = { "source" }, triggerKind = 1 },
			range = {
				["start"] = { cmd.line1, 0 },
				["end"] = { cmd.line2, 0 },
			},
		})
	end, { range = true })

	vim.api.nvim_buf_create_user_command(bufnr, "WebLspFormat", require("web.format"), {})
end

return M
