local wezterm = require("wezterm")
local M = {}

---merges two tables
---@param lhs table
---@param rhs table
---@return table
function M.merge(lhs, rhs)
	if lhs == nil then
		wezterm.log_warn("Left-hand Side table (lhs) was nil.")
		return rhs
	end
	if rhs == nil then
		wezterm.log_warn("Right-hand Side table (rhs) was nil.")
		return lhs
	end

	wezterm.log_info("LHS", lhs, "RHS", rhs)

	for k, v in pairs(rhs) do
		-- merge
		if type(v) == "table" then
			if type(lhs[k] or false) == "table" then
				M.merge(lhs[k] or {}, rhs[k] or {})
			else
				lhs[k] = v
			end
		else
			lhs[k] = v
		end
	end

	wezterm.log_info("returning (updated LHS) -> ", lhs)
	return lhs
end

function M.append_all(old, new)
	wezterm.log_info("[append_all] lhs =>", old, "rhs => ", new)
	if old == nil and new == nil then
		wezterm.log_info("[append_all] both LHS and RHS are nil.  Returning empty table.")
		return {}
	end

	-- If the left hand side is nil, return the right hand side
	if old == nil then
		wezterm.log_info("[append_all] LHS is nil, using RHS")
		return new
	end

	-- If the left hand side is not nul but the right hand side is nil, return the left hand side
	if old ~= nil and new == nil then
		wezterm.log_info("[append_all] RHS is nil, using LHS")
		return old
	end

	-- Iterate over items in the right hand side and add them to left hand side
	for _, v in ipairs(new) do
		table.insert(old, v)
	end

	-- Return the updated left hand side
	wezterm.log_info("[append_all] final => ", old)
	return old
end

return M
