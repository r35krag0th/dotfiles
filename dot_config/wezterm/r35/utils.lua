local M = {}

---merges two tables
---@param t1 table
---@param t2 table
---@return table
function M.merge(t1, t2)
	if t1 == nil then
		return t2
	end
	if t2 == nil then
		return t1
	end

	for k, v in pairs(t2) do
		-- merge
		if type(v) == "table" then
			if type(t1[k] or false) == "table" then
				M.merge(t1[k] or {}, t2[k] or {})
			else
				t1[k] = v
			end
		else
			t1[k] = v
		end
	end
	return t1
end

function M.append_all(old, new)
	if old == nil then
		return new
	end
	if old ~= nil and new == nil then
		return old
	end

	for _, v in ipairs(new) do
		table.insert(old, v)
	end

	return old
end

return M
