local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node
local sn = ls.snippet_node

local M = {}

local function generate_calendar_line(prefix_emoji, postfix_emoji)
  return {
    t("- ( ) " .. prefix_emoji .. " "),
    i(1, "[Start-Hour]"),
    t(":"),
    i(2, "[Start-Minute]"),
    t("-"),
    i(3, "[End-Hour]"),
    t(":"),
    i(4, "[End-Minute]"),
    t(" "),
    t(postfix_emoji),
    t(" "),
    i(5, "[Description]"),
  }
end

-- Various Calendar entries
M.calendar_entry = s("meeting-entry", generate_calendar_line("📆", "➡️ "))
M.free_time_entry = s("freetime-entry", generate_calendar_line("🕒", "🆓"))
M.focus_time_entry = s("focustime-entry", generate_calendar_line("🔥", "🧠"))

-- Create a {&jira XX-1234}[🎟️ XX-1234] snippet
-- The "clickable" part will be auto-populated with the Jira ticket number
M.jira_ticket = s("jira-ticket", {
  t("{&jira "),
  i(1, "PE-1234"),
  t("}[🎟️ "),
  d(2, function(args)
    return sn(nil, {
      i(1, args[1]),
    })
  end, { 1 }),
  t("] "),
})

-- Create a {:$/ticket-notes/XX-1234.norg:}[📝 XX-1234] snippet
M.ticket_notes = s("ticket-notes", {
  t("{:$/ticket-notes/"),
  i(1, "XX-1234"),
  t(".norg:}[📝 "),
  d(2, function(args)
    return sn(nil, {
      i(1, args[1]),
    })
  end, { 1 }),
  t("] "),
})

return M
