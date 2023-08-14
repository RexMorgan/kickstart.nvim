-- For work
local java8RuntimePath = os.getenv('JAVA_HOME')
local wrapperPath = os.getenv('HOME') .. '/.config/nvim/ftplugin/jdtls-wrapper'

local config = {
  name = 'jdtls',
  cmd = { wrapperPath },
  root_dir = vim.fs.dirname(vim.fs.find({ 'gradlew' }, { upward = true })[1]),
  settings = {
    java = {
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

local map = function(mode, keys, func, desc)
  if desc then
    desc = 'LSP: ' .. desc
  end

  vim.keymap.set(mode, keys, func, { desc = desc })
end

local jdtls = require 'jdtls'

-- jdtls recommendations https://github.com/mfussenegger/nvim-jdtls#usage
map('n', '<A-o>', jdtls.organize_imports, 'Organize Imports')
map('v', 'crv', function() jdtls.extract_variable(true) end, 'Extract Variable')
map('n', 'crc', jdtls.extract_constant, 'Extract Constant')
map('v', 'crc', function() jdtls.extract_constant(true) end, 'Extract Constant True')
map('v', 'crm', function() jdtls.extract_method(true) end, 'Extract Method')

-- copy from kickstart nvim because Mason doesn't control jdtls
map('n', '<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
map('n', '<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

map('n', 'gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
map('n', 'gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
map('n', 'gI', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
map('n', '<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
map('n', '<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
map('n', '<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

-- See `:help K` for why this keymap
map('n', 'K', vim.lsp.buf.hover, 'Hover Documentation')
map('n', '<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

-- Lesser used LSP functionality
map('n', 'gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
map('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
map('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
map('n', '<leader>wl', function()
  print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
end, '[W]orkspace [L]ist Folders')

jdtls.start_or_attach(config)

