-- disable netrw at the very start of your init.lua (strongly advised)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true

return {
	'nvim-tree/nvim-tree.lua',
	version = '*',
	dependencies = {
		'nvim-tree/nvim-web-devicons',
	},
	config = function()
		require('nvim-tree').setup {
			view = {
				width = 55
			}
		}
		vim.keymap.set('n', '<leader>,', '<cmd>NvimTreeFindFileToggle<CR>zz', { desc = 'Toggle File Explorer' })
	end,
}
