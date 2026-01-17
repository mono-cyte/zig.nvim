local M = {}

M.build_steps = {}

function M.get_root()
	local build_file = vim.fs.find("build.zig", {
		upward = true,
		path = vim.fn.expand("%:p:h"),
		type = "file",
	})[1]
	return build_file and vim.fs.dirname(build_file) or vim.fn.getcwd()
end

local function find_build_bufnr()
	local bufs = vim.api.nvim_list_bufs()
	for _, buf in ipairs(bufs) do
		if vim.api.nvim_buf_is_valid(buf) then
			local name = vim.api.nvim_buf_get_name(buf)
			if name:match("build%.zig$") then
				return buf
			end
		end
	end
	return nil
end

function M.fetch_build_steps()
	local steps = { "install", "uninstall" }

	local bufnr = find_build_bufnr()
	if not bufnr then
		return steps
	end

	local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "zig")
	if not ok or not parser then
		return steps
	end

	local tree = parser:parse()[1]

	local query_param = [[
	(function_declaration
	  name: (identifier) @func_name (#eq? @func_name "build")
	  parameters: (parameters
	    (parameter
	      name: (identifier) @b_name)))
	]]

	local param = vim.treesitter.query.parse("zig", query_param)

	local b_name = "b"
	for id, node in param:iter_captures(tree:root(), bufnr, 0, -1) do
		if param.captures[id] == "b_name" then
			b_name = vim.treesitter.get_node_text(node, bufnr)
			break
		end
	end

	local query_step = string.format([[
	(function_definition
	  name: (identifier) @func_name (#eq? @func_name "build")
	  body: (block 
	    (variable_declaration
	      (identifier) @var_name
	      (call_expression
		function: (field_expression
		  object: (identifier) @obj (#eq? @obj "%s")
		  member: (identifier) @method (#eq? @method "step")
		)
		(string (string_content) @step_val)
	      )
	    )
	  )
	)
	]],
		b_name
	)

	local step = vim.treesitter.query.parse("zig", query_step)

	for id, node in step:iter_captures(tree:root(), bufnr, 0, -1) do
		if step.captures[id] == "step_val" then
			table.insert(steps, vim.treesitter.get_node_text(node, bufnr))
		end
	end

	return steps
end

function M.parse_test_units(bufnr)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "zig")
	if not ok or not parser then
		return {}
	end

	local query_test = [[
	(test_declaration (string (string_content) @test_name))
	]]
	local test = vim.treesitter.query.parse("zig", query_test)

	local units = {}
	local tree = parser:parse()[1]
	for _, node in test:iter_captures(tree:root(), bufnr) do
		table.insert(units, vim.treesitter.get_node_text(node, bufnr))
	end
	return units
end

return M
