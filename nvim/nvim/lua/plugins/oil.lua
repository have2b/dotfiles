return {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        require("oil").setup({
            default_file_explorer = true, -- Start nvim with oil instead of netrw
            columns = { },
            keymaps = {
                ["<C-h>"] = false,
                ["<C-c>"] = false, -- Prevent ctrl c from closing out of oil
                ["<M-h>"] = "actions.select_split",
                ["q"] = "actions.close",
            },
            delete_to_trash = true,
            view_options = {
                show_hidden = true,
            },
            skip_confirm_for_simple_edits = true,
        })

        -- Keymap
        vim.keymap.set("n", "-", "<cmd>Oil<CR>", { desc = "Open parent directory" }) -- Open parent dir over current active window
        vim.keymap.set("n", "<leader>-", require("oil").toggle_float, { desc = "Toggle float oil" }) -- Open parent dir over current active window
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "oil",
            callback = function()
                vim.opt_local.cursorline = true
            end,
        })
    end
}
