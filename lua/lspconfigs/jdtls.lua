local java8RuntimePath = os.getenv('JAVA_HOME')
local configPath = os.getenv('HOME') .. '/.config/nvim'
local wrapperPath = configPath .. '/ftplugin/jdtls-wrapper'

local util = require 'lspconfig.util'
local handlers = require 'vim.lsp.handlers'


local bundles = {
  vim.fn.glob(configPath .. '/plugins/com.microsoft.java.debug.plugin-*.jar', 1),
};

vim.list_extend(bundles, vim.split(vim.fn.glob(configPath .. '/plugins/*.jar', 1), '\n'))

-- TextDocument version is reported as 0, override with nil so that
-- the client doesn't think the document is newer and refuses to update
-- See: https://github.com/eclipse/eclipse.jdt.ls/issues/1695
local function fix_zero_version(workspace_edit)
  if workspace_edit and workspace_edit.documentChanges then
    for _, change in pairs(workspace_edit.documentChanges) do
      local text_document = change.textDocument
      if text_document and text_document.version and text_document.version == 0 then
        text_document.version = nil
      end
    end
  end
  return workspace_edit
end

local function on_textdocument_codeaction(err, actions, ctx)
  for _, action in ipairs(actions) do
    -- TODO: (steelsojka) Handle more than one edit?
    if action.command == 'java.apply.workspaceEdit' then -- 'action' is Command in java format
      action.edit = fix_zero_version(action.edit or action.arguments[1])
    elseif type(action.command) == 'table' and action.command.command == 'java.apply.workspaceEdit' then -- 'action' is CodeAction in java format
      action.edit = fix_zero_version(action.edit or action.command.arguments[1])
    end
  end

  handlers[ctx.method](err, actions, ctx)
end

local function on_textdocument_rename(err, workspace_edit, ctx)
  handlers[ctx.method](err, fix_zero_version(workspace_edit), ctx)
end

local function on_workspace_applyedit(err, workspace_edit, ctx)
  handlers[ctx.method](err, fix_zero_version(workspace_edit), ctx)
end

-- Non-standard notification that can be used to display progress
local function on_language_status(_, result)
  local command = vim.api.nvim_command
  command 'echohl ModeMsg'
  command(string.format('echo "%s"', result.message))
  command 'echohl None'
end

local root_files = {
  -- Single-module projects
  {
    'gradlew', -- Gradle
    'settings.gradle', -- Gradle
    'settings.gradle.kts', -- Gradle
  },
  -- Multi-module projects
  { 'build.gradle', 'build.gradle.kts' },
}

local env = {
  HOME = vim.loop.os_homedir(),
  XDG_CACHE_HOME = os.getenv 'XDG_CACHE_HOME',
  JDTLS_JVM_ARGS = os.getenv 'JDTLS_JVM_ARGS',
}

local function get_cache_dir()
  return env.XDG_CACHE_HOME and env.XDG_CACHE_HOME or util.path.join(env.HOME, '.cache')
end

local function get_jdtls_cache_dir()
  return util.path.join(get_cache_dir(), 'jdtls')
end

local function get_jdtls_config_dir()
  return util.path.join(get_jdtls_cache_dir(), 'config')
end

local function get_jdtls_workspace_dir()
  return util.path.join(get_jdtls_cache_dir(), 'workspace')
end

local function get_jdtls_jvm_args()
  local args = {}
  for a in string.gmatch((env.JDTLS_JVM_ARGS or ''), '%S+') do
    local arg = string.format('--jvm-arg=%s', a)
    table.insert(args, arg)
  end
  return unpack(args)
end

local jdtls = require('jdtls');
return function (capabilities, on_attach, settings) 
    return {
        name = 'jdtls',
        cmd = {
          wrapperPath,
          '-configuration',
          get_jdtls_config_dir(),
          '-data',
          get_jdtls_workspace_dir(),
          get_jdtls_jvm_args()
        },
        filetypes = { 'java' },
        -- root_dir = function() vim.fs.dirname(vim.fs.find({ 'gradlew' }, { upward = true })[1]) end,
        root_dir = function(fname)
          for _, patterns in ipairs(root_files) do
            local root = util.root_pattern(unpack(patterns))(fname)
            if root then
              return root
            end
          end
        end,
        single_file_support = true,
        capabilities = capabilities,
        on_attach = function(client, bufnr)
            on_attach(client, bufnr);

            -- Setup extra keybindings for jdtls
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

            map('n', '<leader>vc', jdtls.test_class, 'Test class', 'DAP')
            map('n', '<leader>vm', jdtls.test_nearest_method, 'Test nearest method', 'DAP')
        end,
        settings = settings,
        filetypes = (settings or {}).filetypes,
        init_options = {
          workspace = get_jdtls_workspace_dir(),
          jvm_args = {},
          os_config = nil,
          bundles = bundles
        },
    };
end