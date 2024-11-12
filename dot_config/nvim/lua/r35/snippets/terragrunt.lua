local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local c = ls.choice_node
-- local fmt = require("luasnip.extras.fmt").fmt

local M = {}

M.new_line = function()
  return t({ "", "" })
end

M.include_root = s("tg-include-root", {
  t({
    'include "root" {',
    "  path = find_in_parent_folders()",
    "}",
  }),
})

M.include_common = s("tg-include-common", {
  t({
    'include "envcommon" {',
    '  path = "${dirname(find_in_parent_folders())}/_envcommon/iam_policy.hcl"',
    "}",
  }),
})

M.standard_locals = s("tg-standard-locals", {
  t({
    "locals {",
    '  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))',
    '  app_vars     = read_terragrunt_config(find_in_parent_folders("app.hcl"))',
    '  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))',
    '  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))',
    "",
    "  account = local.account_vars.account",
    "  app     = local.app_vars.app",
    "  env     = local.env_vars.env",
    "  region  = local.region_vars.region",
    "}",
  }),
})

return M
