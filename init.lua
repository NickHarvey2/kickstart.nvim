--[[

=====================================================================
==================== READ THIS BEFORE CONTINUING ====================
=====================================================================

Kickstart.nvim is *not* a distribution.

Kickstart.nvim is a template for your own configuration.
  The goal is that you can read every line of code, top-to-bottom, understand
  what your configuration is doing, and modify it to suit your needs.

  Once you've done that, you should start exploring, configuring and tinkering to
  explore Neovim!

  If you don't know anything about Lua, I recommend taking some time to read through
  a guide. One possible example:
  - https://learnxinyminutes.com/docs/lua/


  And then you can explore or search through `:help lua-guide`
  - https://neovim.io/doc/user/lua-guide.html


Kickstart Guide:

I have left several `:help X` comments throughout the init.lua
You should run that command and read that help section for more information.

In addition, I have some `NOTE:` items throughout the file.
These are for you, the reader to help understand what is happening. Feel free to delete
them once you know what you're doing, but they should serve as a guide for when you
are first encountering a few different constructs in your nvim config.

I hope you enjoy your Neovim journey,
- TJ

P.S. You can delete this when you're done too. It's your config now :)
--]]
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Function to capture and return the output of a command
-- this is used later to get config values that are sensitive
-- and should not be kept in source code or env vars
-- instead allows you to get them from a cli secret manager
-- such as 1password or bitwarden cli
function os.capture(cmd, raw)
    local f = assert(io.popen(cmd .. ' 2>&1', 'r'))
    local s = assert(f:read('*a'))
    f:close()
    if raw then return s end
    s = string.gsub(s, '^%s+', '')
    s = string.gsub(s, '%s+$', '')
    s = string.gsub(s, '[\n\r]+', ' ')
    return s
end

-- Install package manager
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system {
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable', -- latest stable release
        lazypath,
    }
end
vim.opt.rtp:prepend(lazypath)

-- NOTE: Here is where you install your plugins.
--  You can configure plugins using the `config` key.
--
--  You can also configure plugins after the setup call,
--    as they will be available in your neovim runtime.
require('lazy').setup({
    -- NOTE: First, some plugins that don't require any configuration

    -- Git related plugins
    'tpope/vim-fugitive',
    'tpope/vim-rhubarb',

    -- Detect tabstop and shiftwidth automatically
    'tpope/vim-sleuth',

    -- NOTE: This is where your plugins related to LSP can be installed.
    --  The configuration is done below. Search for lspconfig to find it below.
    {
        -- LSP Configuration & Plugins
        'neovim/nvim-lspconfig',
        dependencies = {
            -- Automatically install LSPs to stdpath for neovim
            'williamboman/mason.nvim',
            'williamboman/mason-lspconfig.nvim',

            -- Useful status updates for LSP
            -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
            { 'j-hui/fidget.nvim', tag = 'legacy', opts = {} },

            -- Additional lua configuration, makes nvim stuff amazing!
            'folke/neodev.nvim',
        },
    },

    {
        -- Autocompletion
        'hrsh7th/nvim-cmp',
        dependencies = {
            -- Snippet Engine & its associated nvim-cmp source
            'L3MON4D3/LuaSnip',
            'saadparwaiz1/cmp_luasnip',

            -- Adds LSP completion capabilities
            'hrsh7th/cmp-nvim-lsp',

            -- Adds a number of user-friendly snippets
            'rafamadriz/friendly-snippets',
        },
    },

    -- Useful plugin to show you pending keybinds.
    { 'folke/which-key.nvim',  opts = {} },
    {
        -- Adds git related signs to the gutter, as well as utilities for managing changes
        'lewis6991/gitsigns.nvim',
        opts = {
            -- See `:help gitsigns.txt`
            signs = {
                add = { text = '+' },
                change = { text = '~' },
                delete = { text = '_' },
                topdelete = { text = '‾' },
                changedelete = { text = '~' },
            },
            on_attach = function(bufnr)
                vim.keymap.set('n', '<leader>hp', require('gitsigns').preview_hunk,
                    { buffer = bufnr, desc = 'Preview git hunk' })

                -- don't override the built-in and fugitive keymaps
                local gs = package.loaded.gitsigns
                vim.keymap.set({ 'n', 'v' }, ']c', function()
                    if vim.wo.diff then
                        return ']c'
                    end
                    vim.schedule(function()
                        gs.next_hunk()
                    end)
                    return '<Ignore>'
                end, { expr = true, buffer = bufnr, desc = 'Jump to next hunk' })
                vim.keymap.set({ 'n', 'v' }, '[c', function()
                    if vim.wo.diff then
                        return '[c'
                    end
                    vim.schedule(function()
                        gs.prev_hunk()
                    end)
                    return '<Ignore>'
                end, { expr = true, buffer = bufnr, desc = 'Jump to previous hunk' })
            end,
        },
    },

    {
        -- Theme inspired by Atom
        'navarasu/onedark.nvim',
        priority = 1000,
        config = function()
            require('onedark').setup({
                transparent = true
            })
            vim.cmd.colorscheme 'onedark'
        end,
    },

    {
        -- Set lualine as statusline
        'nvim-lualine/lualine.nvim',
        dependencies = {
            "nvim-tree/nvim-web-devicons"
        },
        -- See `:help lualine.txt`
        opts = {
            options = {
                icons_enabled = true,
                theme = 'onedark',
                component_separators = '|',
                section_separators = { left = '', right = '' },
            },
        },
    },

    {
        -- Add indentation guides even on blank lines
        'lukas-reineke/indent-blankline.nvim',
        -- Enable `lukas-reineke/indent-blankline.nvim`
        -- See `:help ibl`
        main = 'ibl',
        opts = {},
    },

    -- "gc" to comment visual regions/line--[[ s ]]
    { 'numToStr/Comment.nvim', opts = {} },

    -- Fuzzy Finder (files, lsp, etc)
    {
        'nvim-telescope/telescope.nvim',
        branch = '0.1.x',
        dependencies = {
            'nvim-lua/plenary.nvim',
            -- Fuzzy Finder Algorithm which requires local dependencies to be built.
            -- Only load if `make` is available. Make sure you have the system
            -- requirements installed.
            {
                'nvim-telescope/telescope-fzf-native.nvim',
                -- NOTE: If you are having trouble with this installation,
                --       refer to the README for telescope-fzf-native for more instructions.
                build = 'make',
                cond = function()
                    return vim.fn.executable 'make' == 1
                end,
            },
        },
    },

    {
        -- Highlight, edit, and navigate code
        'nvim-treesitter/nvim-treesitter',
        dependencies = {
            'nvim-treesitter/nvim-treesitter-textobjects',
        },
        build = ':TSUpdate',
    },

    -- NOTE: Next Step on Your Neovim Journey: Add/Configure additional "plugins" for kickstart
    --       These are some example plugins that I've included in the kickstart repository.
    --       Uncomment any of the lines below to enable them.
    -- require 'kickstart.plugins.autoformat',
    -- require 'kickstart.plugins.debug',

    -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
    --    You can use this folder to prevent any conflicts with this init.lua if you're interested in keeping
    --    up-to-date with whatever is in the kickstart repo.
    --    Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
    --
    --    For additional information see: https://github.com/folke/lazy.nvim#-structuring-your-plugins
    -- { import = 'custom.plugins' },
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
            "MunifTanjim/nui.nvim",
            {
                's1n7ax/nvim-window-picker',
                version = '2.*',
                config = function()
                    require 'window-picker'.setup({
                        filter_rules = {
                            include_current_win = false,
                            autoselect_one = true,
                            -- filter using buffer options
                            bo = {
                                -- if the file type is one of following, the window will be ignored
                                filetype = { 'neo-tree', "neo-tree-popup", "notify" },
                                -- if the buffer type is one of following, the window will be ignored
                                buftype = { 'terminal', "quickfix" },
                            },
                        },
                    })
                end,
            }
        },
        config = function()
            vim.keymap.set('n', '<C-\\>', ':Neotree last reveal<CR>', { noremap = true, silent = true })

            require("neo-tree").setup({
                source_selector = {
                    winbar = true,
                },
                close_if_last_window = true,
                enable_git_status = true,
                enable_normal_mode_for_inputs = true,
                open_files_do_not_replace_types = { "terminal", "trouble", "qf" },
                sort_case_insensitive = true,
                default_component_configs = {
                    container = {
                        enable_character_fade = true
                    },
                    name = {
                        trailing_slash = false,
                        use_git_status_colors = true,
                        highlight = "NeoTreeFileName",
                    },
                },
                filesystem = {
                    follow_current_file = {
                        enabled = true,
                        leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
                    },
                    window = {
                        mappings = {
                            ["<bs>"] = false,
                        }
                    }
                },
                buffers = {
                    follow_current_file = {
                        enabled = true, -- This will find and focus the file in the active buffer every time
                        -- the current file is changed while the tree is open.
                        leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
                    },
                    window = {
                        mappings = {
                            ["<bs>"] = false,
                        }
                    }
                },
            })
        end,
    },

    {
        "windwp/nvim-autopairs",
        -- Optional dependency
        dependencies = { 'hrsh7th/nvim-cmp' },
        config = function()
            require("nvim-autopairs").setup {}
            -- If you want to automatically add `(` after selecting a function or method
            local cmp_autopairs = require('nvim-autopairs.completion.cmp')
            local cmp = require('cmp')
            cmp.event:on(
                'confirm_done',
                cmp_autopairs.on_confirm_done()
            )
        end,
    },

    "dhruvasagar/vim-table-mode",

    {
        "robitx/gp.nvim",
        config = function()
            vim.keymap.set('n', '<C-g><C-g>',
                ":lua vim.notify('Plugin not loaded, use :LoadGp to load it', vim.log.levels.ERROR, { title = 'gp.nvim' })<CR>",
                { noremap = true, silent = true })
            vim.keymap.set('n', '<C-g><C-n>',
                ":lua vim.notify('Plugin not loaded, use :LoadGp to load it', vim.log.levels.ERROR, { title = 'gp.nvim' })<CR>",
                { noremap = true, silent = true })
        end,
    },

    {
        "rcarriga/nvim-notify",
        config = function()
            vim.notify = require("notify")
            require("notify").setup({
                background_colour = "#000000",
            })
            require("telescope").load_extension("notify")
        end
    },

    {
        "numToStr/FTerm.nvim",
        config = function()
            require 'FTerm'.setup({
                border     = 'rounded',
                dimensions = {
                    height = 0.8,
                    width = 0.8,
                    x = 0.5,
                    y = 0.5,
                },
            })
            vim.keymap.set('n', '<A-i>', '<CMD>lua require("FTerm").toggle()<CR>')
        end
    },

    { "mg979/vim-visual-multi" },

    {
        "zk-org/zk-nvim",
        config = function()
            require("zk").setup({
                picker = "telescope"
            })
        end
    },

    { "NoahTheDuke/vim-just" }

}, {})

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!

-- Set highlight on search
vim.o.hlsearch = true

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = 'a'

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = 'unnamedplus'

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function()
        vim.highlight.on_yank()
    end,
    group = highlight_group,
    pattern = '*',
})

-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
require('telescope').setup {
    defaults = {
        mappings = {
            i = {
                ['<C-u>'] = false,
                ['<C-d>'] = false,
            },
        },
    },
}

-- Enable telescope fzf native, if installed
pcall(require('telescope').load_extension, 'fzf')

-- See `:help telescope.builtin`
vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', function()
    -- You can pass additional configuration to telescope to change theme, layout, etc.
    require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        winblend = 10,
        previewer = false,
    })
end, { desc = '[/] Fuzzily search in current buffer' })

vim.keymap.set('n', '<leader>gf', require('telescope.builtin').git_files, { desc = 'Search [G]it [F]iles' })
vim.keymap.set('n', '<leader>sf', require('telescope.builtin').find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', require('telescope.builtin').resume, { desc = '[S]earch [R]esume' })

-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`
-- Defer Treesitter setup after first render to improve startup time of 'nvim {filename}'
vim.defer_fn(function()
    require('nvim-treesitter.configs').setup {
        -- Add languages to be installed here that you want installed for treesitter
        ensure_installed = { 'c', 'cpp', 'go', 'lua', 'python', 'rust', 'tsx', 'javascript', 'typescript', 'vimdoc', 'vim', 'bash' },

        -- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
        auto_install = false,

        highlight = {
            enable = true,
            additional_vim_regex_highlighting = { "markdown" }
        },
        indent = { enable = true },
        incremental_selection = {
            enable = true,
            keymaps = {
                init_selection = '<c-space>',
                node_incremental = '<c-space>',
                scope_incremental = '<c-s>',
                node_decremental = '<M-space>',
            },
        },
        textobjects = {
            select = {
                enable = true,
                lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
                keymaps = {
                    -- You can use the capture groups defined in textobjects.scm
                    ['aa'] = '@parameter.outer',
                    ['ia'] = '@parameter.inner',
                    ['af'] = '@function.outer',
                    ['if'] = '@function.inner',
                    ['ac'] = '@class.outer',
                    ['ic'] = '@class.inner',
                },
            },
            move = {
                enable = true,
                set_jumps = true, -- whether to set jumps in the jumplist
                goto_next_start = {
                    [']m'] = '@function.outer',
                    [']]'] = '@class.outer',
                },
                goto_next_end = {
                    [']M'] = '@function.outer',
                    [']['] = '@class.outer',
                },
                goto_previous_start = {
                    ['[m'] = '@function.outer',
                    ['[['] = '@class.outer',
                },
                goto_previous_end = {
                    ['[M'] = '@function.outer',
                    ['[]'] = '@class.outer',
                },
            },
            swap = {
                enable = true,
                swap_next = {
                    ['<leader>a'] = '@parameter.inner',
                },
                swap_previous = {
                    ['<leader>A'] = '@parameter.inner',
                },
            },
        },
    }
end, 0)

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- [[ Configure LSP ]]
--  This function gets run when an LSP connects to a particular buffer.
local on_attach = function(_, bufnr)
    -- NOTE: Remember that lua is a real programming language, and as such it is possible
    -- to define small helper and utility functions so you don't have to repeat yourself
    -- many times.
    --
    -- In this case, we create a function that lets us more easily define mappings specific
    -- for LSP related items. It sets the mode, buffer and description for us each time.
    local nmap = function(keys, func, desc)
        if desc then
            desc = 'LSP: ' .. desc
        end

        vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
    end

    nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

    nmap('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
    nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
    nmap('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
    nmap('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
    nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
    nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

    -- See `:help K` for why this keymap
    nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
    nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

    -- Lesser used LSP functionality
    nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
    nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
    nmap('<leader>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, '[W]orkspace [L]ist Folders')

    -- Create a command `:Format` local to the LSP buffer
    vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
        vim.lsp.buf.format()
    end, { desc = 'Format current buffer with LSP' })
end

-- document existing key chains
require('which-key').register {
    ['<leader>c'] = { name = '[C]ode', _ = 'which_key_ignore' },
    ['<leader>d'] = { name = '[D]ocument', _ = 'which_key_ignore' },
    ['<leader>g'] = { name = '[G]it', _ = 'which_key_ignore' },
    ['<leader>h'] = { name = 'More git', _ = 'which_key_ignore' },
    ['<leader>r'] = { name = '[R]ename', _ = 'which_key_ignore' },
    ['<leader>s'] = { name = '[S]earch', _ = 'which_key_ignore' },
    ['<leader>w'] = { name = '[W]orkspace', _ = 'which_key_ignore' },
}

-- mason-lspconfig requires that these setup functions are called in this order
-- before setting up the servers.
require('mason').setup()
require('mason-lspconfig').setup()

-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--
--  Add any additional override configuration in the following tables. They will be passed to
--  the `settings` field of the server config. You must look up that documentation yourself.
--
--  If you want to override the default filetypes that your language server will attach to you can
--  define the property 'filetypes' to the map in question.
local servers = {
    gopls = {
        gopls = {
            analyses = {
                unusedparams = true,
            },
        },
    },

    omnisharp = {},

    powershell_es = {},

    vale_ls = {},

    jsonls = {},

    yamlls = {},

    zk = {},

    lua_ls = {
        Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
        },
    },
}

-- Setup neovim lua configuration
require('neodev').setup()

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- Ensure the servers above are installed
local mason_lspconfig = require 'mason-lspconfig'

mason_lspconfig.setup {
    ensure_installed = vim.tbl_keys(servers),
}

mason_lspconfig.setup_handlers {
    function(server_name)
        require('lspconfig')[server_name].setup {
            capabilities = capabilities,
            on_attach = on_attach,
            settings = servers[server_name],
            filetypes = (servers[server_name] or {}).filetypes,
        }
    end,
}

-- [[ Configure nvim-cmp ]]
-- See `:help cmp`
local cmp = require 'cmp'
local luasnip = require 'luasnip'
require('luasnip.loaders.from_vscode').lazy_load()
luasnip.config.setup {}

cmp.setup {
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    mapping = cmp.mapping.preset.insert {
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<C-d>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-y>'] = cmp.mapping.close(),
        ['<C-Space>'] = cmp.mapping.complete {},
        ['<CR>'] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = false,
        },
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
                luasnip.expand_or_jump()
            else
                fallback()
            end
        end, { 'i', 's' }),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, { 'i', 's' }),
    },
    sources = {
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
    },
}

-- [[ Various custom config ]]
-- deferred to allow the notify plugin to load
vim.defer_fn(function()
    Custom = {
        gp_is_setup = false,

        open_weekly_note = function()
            local numSecondsInAWeek = 7 * 24 * 60 * 60
            local currentTimeStamp = os.time()
            local timeStampAWeekAgo = currentTimeStamp - numSecondsInAWeek
            local yearAWeekAgo = os.date("%Y", timeStampAWeekAgo)
            local weekAWeekAgo = os.date("%V", timeStampAWeekAgo)
            local yearToday = os.date("%Y", currentTimeStamp)
            local weekToday = os.date("%V", currentTimeStamp)
            local notePath = vim.fn.getcwd() ..
            "/Daily Notes/" .. yearToday .. "/" .. yearToday .. "-W" .. weekToday .. ".md"
            local fallbackPath = vim.fn.getcwd() ..
            "/Daily Notes/" .. yearAWeekAgo .. "/" .. yearAWeekAgo .. "-W" .. weekAWeekAgo .. ".md"
            local f = io.open(notePath, "r")
            if f ~= nil then
                -- If file exists, close it and continue
                io.close(f)
            else
                -- If the file does not exist, create it by copying last week's note
                local result = os.execute("cp \"" .. fallbackPath .. "\" \"" .. notePath .. "\"")
                if result then
                else
                    vim.notify('Failed to create new note', vim.log.levels.ERROR, {
                        title = 'Weekly Note'
                    })
                end
                return
            end
            vim.api.nvim_exec2("Neotree reveal_file=" .. string.gsub(notePath, '%s', '\\ '), {})
        end,

        -- [[ Configure gp.nvim ]]
        -- need to do some fancy shtuff to set it up in the bg
        -- better mutex would be good but for my use case here probably doesn't matter
        load_gp = function(pswd)
            local n = Custom.start_spinning_notify('Loading', vim.log.levels.INFO, { title = 'gp.nvim' })
            local cmd = "bw --nointeraction --cleanexit get notes OPENAI_API_KEY"
            if pswd ~= nil then
                cmd = cmd .. " --session $(bw unlock " .. pswd .. " --raw)"
            end
            vim.fn.jobstart(cmd, {
                on_stdout = function(_, data, _)
                    if Custom.gp_is_setup then return end
                    if data[1] == '' then
                        Custom.stop_spinning_notify(n, 'No API key found, plugin not loaded', vim.log.levels.WARN, {
                            icon = Custom.spinner_cancelled,
                        })
                        return
                    end
                    Custom.gp_is_setup = true
                    require("gp").setup({
                        openai_api_key = data[1],
                        chat_dir = vim.fn.getcwd() .. "/Chats",
                        chat_model = { model = "gpt-4", temperature = 1.1, top_p = 1 },
                        chat_topic_gen_model = "gpt-4",
                        chat_conceal_model_params = true,
                        command_model = { model = "gpt-4", temperature = 1.1, top_p = 1 },
                        chat_shortcut_respond = nil,
                        chat_shortcut_delete = nil,
                        chat_shortcut_new = nil,
                    })
                    vim.keymap.set('n', '<C-g><C-g>', ':GpChatRespond<CR>', { noremap = true, silent = true })
                    vim.keymap.set('n', '<C-g><C-n>', ':GpChatNew<CR>', { noremap = true, silent = true })
                    Custom.stop_spinning_notify(n, 'Loaded', vim.log.levels.INFO, {})
                end
            })
        end,

        table_last = function(T)
            local last = nil
            for k in pairs(T) do last = k end
            return last
        end,

        spinner_frames = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" },
        spinner_complete = "",
        spinner_cancelled = "󰜺",
        spinner_error = "",
        spinning_notifications = {},

        start_spinning_notify = function(msg, level, opts)
            local id = 1
            if Custom.table_last(Custom.spinning_notifications) ~= nil then
                id = Custom.table_last(Custom.spinning_notifications) + 1
            end
            local frame = 1
            Custom.spinning_notifications[id] = vim.notify(msg, level, {
                timeout = false,
                title = opts.title,
                hide_from_history = opts.hide_from_history,
                icon = Custom.spinner_frames[frame],
            })
            vim.defer_fn(function()
                Custom.continue_spinning_notify(id, frame)
            end, 100)
            return id
        end,

        continue_spinning_notify = function(id, frame)
            frame = (frame + 1) % 8
            if Custom.spinning_notifications[id] ~= nil then
                Custom.spinning_notifications[id] = vim.notify(nil, nil, {
                    hide_from_history = true,
                    icon = Custom.spinner_frames[frame],
                    replace = Custom.spinning_notifications[id],
                })
                vim.defer_fn(function()
                    Custom.continue_spinning_notify(id, frame)
                end, 100)
            end
        end,

        stop_spinning_notify = function(id, msg, level, opts)
            if opts.timeout == nil then opts.timeout = 3000 end
            if opts.icon == nil then opts.icon = Custom.spinner_complete end
            Custom.spinning_notifications[id] = vim.notify(msg, level, {
                title = opts.title,
                icon = opts.icon,
                replace = Custom.spinning_notifications[id],
                timeout = opts.timeout,
            })
            Custom.spinning_notifications[id] = nil
        end
    }

    -- if there is a chats directory, attempt to autoload gp.nvim (requires bw vault to be unlocked)
    if os.capture("ls -d " .. vim.fn.getcwd() .. "/Chats") == vim.fn.getcwd() .. "/Chats" then
        Custom.load_gp()
    end

    -- Create a command to take you to the weekly note in Neotree, but only if the Daily Notes directory exists
    if os.capture("ls -d '" .. vim.fn.getcwd() .. "/Daily Notes'") == vim.fn.getcwd() .. "/Daily Notes" then
        vim.api.nvim_create_user_command('Weekly', Custom.open_weekly_note, { desc = 'Open or create weekly note' })
    end

    -- Command to read in the bw master password so that we can grab the API key needed to
    -- load gp.nvim, if the vault wasn't unlocked when we launched
    vim.api.nvim_create_user_command('LoadGp', function()
        Custom.load_gp(vim.fn.inputsecret('Enter your Bitwarden master password: '))
    end, { desc = 'Manually load gp.nvim' })
end, 0)

-- keymaps for wrapping selected text in various things
vim.keymap.set('v', '(', '<esc>`>a)<esc>`<i(<esc>lv`>l', { noremap = true, silent = true })
vim.keymap.set('v', '[', '<esc>`>a]<esc>`<i[<esc>lv`>l', { noremap = true, silent = true })
vim.keymap.set('v', '{', '<esc>`>a}<esc>`<i{<esc>lv`>l', { noremap = true, silent = true })
-- `<` the unindent behavior is more important than wrapping
-- vim.keymap.set('v', '<', '<esc>`>a><esc>`<i<<esc>lv`>l', { noremap = true, silent = true })
vim.keymap.set('v', '"', '<esc>`>a"<esc>`<i"<esc>lv`>l', { noremap = true, silent = true })
vim.keymap.set('v', '_', '<esc>`>a_<esc>`<i_<esc>lv`>l', { noremap = true, silent = true })
vim.keymap.set('v', '*', '<esc>`>a*<esc>`<i*<esc>lv`>l', { noremap = true, silent = true })
vim.keymap.set('v', '=', '<esc>`>a=<esc>`<i=<esc>lv`>l', { noremap = true, silent = true })
vim.keymap.set('v', '\'', '<esc>`>a\'<esc>`<i\'<esc>lv`>l', { noremap = true, silent = true })
vim.keymap.set('v', '~', '<esc>`>a~<esc>`<i~<esc>lv`>l', { noremap = true, silent = true })
vim.keymap.set('v', '`', '<esc>`>a`<esc>`<i`<esc>lv`>l', { noremap = true, silent = true })
vim.keymap.set('v', '<C-k>', '<esc>`<i[<esc>`>la]()<esc>h', { noremap = true, silent = true })

vim.keymap.set('n', '<TAB>', '<S-v>><esc>', { noremap = true, silent = true })
vim.keymap.set('n', '<S-TAB>', '<S-v><<esc>', { noremap = true, silent = true })
vim.keymap.set('v', '<TAB>', '>gv', { noremap = true, silent = true })
vim.keymap.set('v', '<S-TAB>', '<gv', { noremap = true, silent = true })
vim.keymap.set('n', '<A-Up>', '5k', { noremap = true })
vim.keymap.set('n', '<A-Down>', '5j', { noremap = true })

vim.cmd('autocmd FileType markdown setlocal spell spelllang=en_us')
vim.cmd('autocmd FileType markdown set wrap linebreak')
vim.cmd('autocmd FileType markdown setlocal breakat=\\ ')
vim.cmd('autocmd FileType markdown set tabstop=4')
vim.cmd('autocmd FileType markdown set shiftwidth=4')
vim.cmd('autocmd FileType markdown set conceallevel=0')
vim.cmd('highlight CursorLine guibg=#30343c')
vim.opt.cursorline = true
vim.cmd('highlight SpellBad guibg=#550000 gui=underline')

vim.opt.termguicolors = true

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=4 sts=4 sw=4 et
