-- For work
local java8RuntimePath = os.getenv('JAVA_HOME')
local configPath = os.getenv('HOME') .. '/.config/nvim'
local wrapperPath = configPath .. '/ftplugin/jdtls-wrapper'

local bundles = {
  vim.fn.glob(configPath .. '/plugins/com.microsoft.java.debug.plugin-*.jar', 1),
};

vim.list_extend(bundles, vim.split(vim.fn.glob(configPath .. '/plugins/*.jar', 1), '\n'))

local jdtls = require 'jdtls'

local config = {
  name = 'jdtls',
  init_options = {
    bundles = bundles
  },
  on_attach = function(client, bufnr)
    jdtls.setup_dap({ hotcodereplace = 'auto' })
  end,
  cmd = { wrapperPath },
  root_dir = vim.fs.dirname(vim.fs.find({ 'gradlew' }, { upward = true })[1]),
  settings = {
    java = {
      format = {
        settings = {
          url = os.getenv('HOME') .. '/.config/nvim/configs/eclipse-code-format.xml',
          profile = "Indeed"
        }
      },
      signatureHelp = { enabled = true },
      contentProvider = { preferred = 'fernflower' },
      configuration = {
        runtimes = {
          {
            name = 'JavaSE-1.8',
            path = java8RuntimePath,
            default = true
          }
        }
      },
      completion = {
        importOrder = {
          '',
          'javax',
          'java',
          '#'
        }
      },
      sources = {
        organizeImports = {
          starThreshold = 9999;
          staticStarThreshold = 9999;
        },
      },
      codeGeneration = {
        toString = {
          template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}"
        },
        hashCodeEquals = {
          useJava7Objects = true,
        },
        useBlocks = true
      },
      import = {
        gradle = {
          enabled = true,
          home = os.getenv('HOME') .. '/.gradle/',
          java = {
            home = java8RuntimePath
          }
        }
      }
    }
  }
}

local map = function(mode, keys, func, desc, prefix)
  if desc then
    desc = prefix .. ': ' .. desc
  end

  vim.keymap.set(mode, keys, func, { desc = desc })
end


-- jdtls recommendations https://github.com/mfussenegger/nvim-jdtls#usage
map('n', '<A-o>', jdtls.organize_imports, 'Organize Imports', 'LSP')
map('v', 'crv', function() jdtls.extract_variable(true) end, 'Extract Variable', 'LSP')
map('n', 'crc', jdtls.extract_constant, 'Extract Constant', 'LSP')
map('v', 'crc', function() jdtls.extract_constant(true) end, 'Extract Constant True', 'LSP')
map('v', 'crm', function() jdtls.extract_method(true) end, 'Extract Method', 'LSP')


local dap = require('dap')
local dapWidgets = require('dap.ui.widgets')

-- nvim-dap
map('n', '<leader>bb', dap.toggle_breakpoint, 'Set Breakpoint', 'DAP')
map('n', '<leader>bc', function() dap.set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, 'Set conditional breakpoint', 'DAP')
map('n', '<leader>bl', function() dap.set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end, 'Set log point', 'DAP')
map('n', '<leader>br', dap.clear_breakpoints, 'Clear breakpoints', 'DAP')
map('n', '<leader>ba', '<cmd>Telescope dap list_breakpoints<cr>', 'List breakpoints', 'DAP')
map('n', '<leader>dc', dap.continue, 'Continue', 'DAP')
map('n', '<leader>dj', dap.step_over, 'Step over', 'DAP')
map('n', '<leader>dk', dap.step_into, 'Step into', 'DAP')
map('n', '<leader>do', dap.step_out, 'Step out', 'DAP')
map('n', '<leader>dd', dap.disconnect, 'Disconnect', 'DAP')
map('n', '<leader>dt', dap.terminate, 'Terminate', 'DAP')
map('n', '<leader>dr', dap.repl.toggle, 'Open REPL', 'DAP')
map('n', '<leader>dl', dap.run_last, 'Run last', 'DAP')
map('n', '<leader>di', dapWidgets.hover, 'Variables', 'DAP')
map('n', '<leader>d?', function() dapWidgets.centered_float(dapWidgets.scopes) end, 'Scopes', 'DAP')
map('n', '<leader>df', '<cmd>Telescope dap frames<cr>', 'List frames', 'DAP')
map('n', '<leader>dh', '<cmd>Telescope dap commands<cr>', 'List commands', 'DAP')

map('n', '<leader>vc', jdtls.test_class, 'Test class', 'DAP')
map('n', '<leader>vm', jdtls.test_nearest_method, 'Test nearest method', 'DAP')

jdtls.start_or_attach(config)

require('dap.ext.vscode').load_launchjs()
