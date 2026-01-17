local M = {}


function M.sync_ui_select(items, opts, fun)
	local select = nil
	local co = coroutine.running()
	vim.ui.select(items, opts, function(choice)
		if fun ~= nil then
			fun(choice)
		end
		select = choice
		if co then
			coroutine.resume(co)
		end
	end)
	if co then
		coroutine.yield()
	end
	return select
end



return M
