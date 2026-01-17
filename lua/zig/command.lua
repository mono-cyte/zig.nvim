local M = {}
local info = require("zig.info")

local function run_in_term(args)
	local cmd = args
	local cwd = info.get_root()
	local buf = vim.api.nvim_create_buf(false, true)

	-- 1. 创建下方水平分割窗口 (高度 12)
	local win = vim.api.nvim_open_win(buf, true, {
		split = 'below', -- 相当于 botright split
		height = 12, -- 窗口高度
	})

	vim.fn.termopen(cmd, {
		cwd = cwd,
		on_exit = function(_, code)
			if code ~= 0 then
				vim.notify("Exited with: " .. code, vim.log.levels.WARN)
			end
		end
	})
end


local handlers = {
	build = function(opts)
		local cmd = { "zig", "build" }
		vim.list_extend(cmd, opts.fargs)
		run_in_term(cmd)
	end,

	release = function(opts)
		local mode = opts.fargs[1] or "fast"
		local cmd = { "zig", "build", "--release=" .. mode }
		run_in_term(cmd)
	end,

	test = function(opts)
		local file = vim.api.nvim_buf_get_name(0)
		local cmd = { "zig", "test", file }
		if opts.args and #opts.args > 0 then
			vim.list_extend(cmd, { "--test-filter", opts.args })
		end
		run_in_term(cmd)
	end,
}

local completers = {
	build = function()
		return info.fetch_build_steps()
	end,
	release = function()
		return { "fast", "small", "safe" }
	end,
	test = function()
		return info.parse_test_units(0)
	end,
}

function M.setup()
	vim.api.nvim_create_user_command("Zbuild", handlers.build, {
		nargs = "*",
		complete = completers.build,
		desc = "Zig build commands",
	})

	vim.api.nvim_create_user_command("Zrelease", handlers.release, {
		nargs = "?",
		complete = completers.release,
		desc = "Zig build with release mode",
	})

	vim.api.nvim_create_user_command("Ztest", handlers.test, {
		nargs = "*",
		complete = completers.test,
		desc = "Zig test current buffer",
	})
end

return M
