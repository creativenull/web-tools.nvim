local utils = require("web.utils")
local lsp_shared = require("web.lsp._shared")
local validator = require("web.validator")
local M = {}

local function register_plugin_cmds()
  require("web.run").setup()
end

local function create_common_on_attach(user_on_attach, user_options)
  return function(client, bufnr)
    user_on_attach(client, bufnr)
    lsp_shared.register_lsp_cmds(bufnr)

    if client.name == "tsserver" and user_options.lsp.tsserver.inlay_hints ~= "" then
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end

    if client.name == "volar" and user_options.lsp.volar.inlay_hints then
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end

    if client.name == "astro_ls" and user_options.lsp.astro.inlay_hints then
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end

    if client.name == "svelte_ls" and user_options.lsp.svelte.inlay_hints ~= "" then
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end
  end
end

local default_user_options = {
  on_attach = nil,
  capabilities = nil,
  format_on_save = false,

  lsp = {
    css = {},
    html = {},
    astro = {
      inlay_hints = vim.fn.has("nvim-0.10") == 1 and "minimal" or "",
    },
    volar = {
      inlay_hints = vim.fn.has("nvim-0.10") == 1,
    },
    svelte = {
      inlay_hints = vim.fn.has("nvim-0.10") == 1 and "minimal" or "",
    },
    tsserver = {
      -- Inlay hints are opt-out feature in nvim >= v0.10
      -- which means they will be enabled by default from v0.10 and onwards
      inlay_hints = vim.fn.has("nvim-0.10") == 1 and "minimal" or "",

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

local function detected(root_files)
  return utils.fs.find_nearest(root_files) ~= nil
end

function M.setup(user_options)
  local valid, mod = pcall(validator.validate_requirements)
  if not valid then
    vim.api.nvim_err_writeln(mod)
    return
  end

  if user_options ~= nil and type(user_options) == "table" then
    user_options = vim.tbl_deep_extend("force", default_user_options, user_options)
  else
    user_options = default_user_options
  end

  user_options.on_attach = create_common_on_attach(user_options.on_attach, user_options)

  -- Register any non-lsp dependent features
  register_plugin_cmds()

  --[[
  Generic project, or no project
    - Detect project
    - Register autocmd to run lsp servers with options
  --]]
  if detected(require("web.lsp.json").root_dirs) then
    require("web.lsp.json").setup(user_options)
  end

  if detected(require("web.lsp.html").root_dirs) then
    require("web.lsp.html").setup(user_options)
  end

  if detected(require("web.lsp.css").root_dirs) then
    require("web.lsp.css").setup(user_options)
  end

  --[[
  Astro Project
    - Detect project
    - Register autocmd to run lsp servers with options
  --]]
  if detected(require("web.lsp.astro").root_dirs) then
    require("web.lsp.astro").setup(user_options)
    require("web.lsp.tsserver").setup(user_options)

    if detected(require("web.lsp.tailwindcss").root_dirs) then
      require("web.lsp.tailwindcss").setup(user_options)
    end

    if detected(require("web.lsp.eslint").root_dirs) then
      require("web.lsp.eslint").setup(user_options, { filetyes = { "astro" } })
    end

    return
  end

  --[[
  Svelte Project
    - Detect project
    - Register autocmd to run lsp servers with options
  --]]
  if detected(require("web.lsp.svelte").root_dirs) then
    require("web.lsp.svelte").setup(user_options)
    require("web.lsp.tsserver").setup(user_options)

    if detected(require("web.lsp.tailwindcss").root_dirs) then
      require("web.lsp.tailwindcss").setup(user_options)
    end

    if detected(require("web.lsp.eslint").root_dirs) then
      require("web.lsp.eslint").setup(user_options, { filetyes = { "svelte" } })
    end

    return
  end

  --[[
  Vue Project
    - Detect project
    - Register autocmd to run lsp servers with options
  --]]
  if detected(require("web.lsp.volar").root_dirs) then
    require("web.lsp.volar").setup(user_options)

    if detected(require("web.lsp.tailwindcss").root_dirs) then
      require("web.lsp.tailwindcss").setup(user_options)
    end

    -- Setup tsserver with vue support
    local location = require("web.lsp.volar").get_server_path()
    if location ~= "" then
      require("web.lsp.tsserver").setup(user_options, {
        filetypes = { "vue" },
        init_options = {
          plugins = {
            { name = "@vue/typescript-plugin", location = location, languages = { "vue" } },
          },
        },
      })
    end

    -- Eslint support
    if detected(require("web.lsp.eslint").root_dirs) then
      require("web.lsp.eslint").setup(user_options, { filetyes = { "vue" } })
    end

    return
  end

  --[[
  TS/JS Project
    - Detect project
    - Register autocmd to run lsp servers with options
  --]]
  if detected(require("web.lsp.tsserver").root_dirs) then
    require("web.lsp.tsserver").setup(user_options)

    if detected(require("web.lsp.tailwindcss").root_dirs) then
      require("web.lsp.tailwindcss").setup(user_options)
    end

    if detected(require("web.lsp.eslint").root_dirs) then
      require("web.lsp.eslint").setup(user_options)
    end

    return
  end
end

M.format = require("web.format")

return M
