local java8RuntimePath = os.getenv('JAVA_HOME')
local configPath = os.getenv('HOME') .. '/.config/nvim'
local wrapperPath = configPath .. '/ftplugin/jdtls-wrapper'

local util = require 'lspconfig.util'

local bundles = {
  vim.fn.glob(configPath .. '/plugins/com.microsoft.java.debug.plugin-*.jar', 1),
};

vim.list_extend(bundles, vim.split(vim.fn.glob(configPath .. '/plugins/*.jar', 1), '\n'))

local root_files = {
  -- Single-module projects
  {
    'gradlew', -- Gradle
    'build.xml', -- Ant
    'pom.xml', -- Maven
    'settings.gradle', -- Gradle
    'settings.gradle.kts', -- Gradle
  },
  -- Multi-module projects
  { 'build.gradle', 'build.gradle.kts' },
}

return function (options)  
  local default_config = require('lspconfig.server_configurations.jdtls').default_config
  -- updates the default_config for keys I need to merge into because I'm lazy and don't know lua.
  default_config.cmd[1] = wrapperPath
  default_config.init_options.bundles = bundles

  local config = {
    root_dir = function(fname)
      for _, patterns in ipairs(root_files) do
        local root = util.root_pattern(unpack(patterns))(fname)
        if root then
          return root
        end
      end
    end,
    on_attach = function(client, bufnr)
      local jdtls = require('jdtls');
      options.default_on_attach(client, bufnr);
    
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
    end
  }

  return setmetatable(config, { __index = default_config })
end