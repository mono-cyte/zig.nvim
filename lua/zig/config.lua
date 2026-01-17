local utils = require("zig.utils")
local info = require("zig.info")

local function seclect_program()
	local root = info.root

	local obj = vim.system({ "zig", "build", "install" }, { cwd = root }):wait()
	if obj.code ~= 0 then
		vim.notify("Failed to build zig")
		return nil
	end

	local files = vim.fn.globpath(root .. "/zig-out/bin", "*", false, true)

	local exe = {}
	for _, f in ipairs(files) do
		if vim.fn.executable(f) then
			table.insert(exe, f)
		end
	end

	return utils.sync_ui_select(exe, { prompt = "Select target: " })
end

local zig_dbg_conf = {
	{
		name = "Launch (codelldb)",
		type = "codelldb",
		request = "launch",

		program = function()
			return seclect_program()
		end,
		cwd = "${workspaceFolder}",
		args = {},

		stopOnEntry = false,
	},
}

local ok, dap = pcall(require, "dap")

if not ok then
	vim.notify("zig: Failed to find dap", vim.log.levels.WARN)
	return
end

dap.configurations.zig = zig_dbg_conf
