local lsp_shared = require("web.lsp._shared")
local event = require("web.event")
local validator = require("web.validator")
local utils = require("web.utils")
local M = {}

local default_setup_opts = {
	on_attach = nil,
  capabilities = nil,
	format_on_save = false,

	lsp = {
    css = {},
    html = {},
		tsserver = {
			-- Inlay hints are opt-out feature in nvim >= v0.10
			-- which means they will be enabled by default from v0.10 and onwards
			inlay_hints = vim.fn.has("nvim-0.10") == 1,

			-- TODO: wait for nvim PR to be stable/merged (https://github.com/neovim/neovim/pull/22598)
			code_actions_on_save = {
				"source.organizeImports.ts",
				"source.fixAll.ts",
				"source.removeUnused.ts",
				"source.addMissingImports.ts",
				"source.removeUnusedImports.ts",
				"source.sortImports.ts",
			},
		},

		eslint = {
			workspace = true,
			flat_config = false,
			code_actions_on_save = {
				"source.fixAll.eslint",
			},
		},
	},
}

function M.setup(setup_opts)
	local valid, mod = pcall(validator.validate_requirements)
	if not valid then
		vim.api.nvim_err_writeln(mod)
		return
	end

	if type(setup_opts) == "table" then
		setup_opts = vim.tbl_extend("force", default_setup_opts, setup_opts)
	else
		setup_opts = default_setup_opts
	end

	if setup_opts.lsp.tsserver then
		require("web.lsp.tsserver").setup(setup_opts)
	end

	if setup_opts.lsp.eslint then
		require("web.lsp.eslint").setup(setup_opts)
	end

	if setup_opts.lsp.css then
		require("web.lsp.css").setup(setup_opts)
	end

	if setup_opts.lsp.html then
		require("web.lsp.html").setup(setup_opts)
	end

	vim.api.nvim_create_autocmd("LspAttach", {
		group = event.group("default"),
		callback = function(ev)
			lsp_shared.register_common_user_commands(ev.buf)
		end,
	})

	vim.api.nvim_create_user_command("WebRun", function(cmd)
		local script = cmd.fargs[1]
		local pm = utils.fs.get_package_manager()

		if pm == "npm" then
			vim.cmd(string.format("terminal npm run %s", script))
		elseif pm == "yarn" then
			vim.cmd(string.format("terminal yarn %s", script))
		elseif pm == "pnpm" then
			vim.cmd(string.format("terminal pnpm %s", script))
		end
	end, {
		nargs = 1,
		complete = function()
			local packagejson_filepath = string.format("%s/package.json", vim.loop.cwd())
			if vim.fn.filereadable(packagejson_filepath) == 0 then
				return {}
			end

			local json = vim.json.decode(utils.fs.readfile(packagejson_filepath))
			if vim.tbl_isempty(json.scripts) then
				return {}
			end

			return vim.tbl_keys(json.scripts)
		end,
	})
end

M.format = require("web.format").handle

return M
