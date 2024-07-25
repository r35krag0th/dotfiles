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

M.infisical_secret = s("k8s-infisical-secret", {
  t({
    "apiVersion: secrets.infisical.com/v1alpha1",
    "kind: InfisicalSecret",
    "metadata:",
    "  name: ",
  }),
  i(1, "my-secret"),
  M.new_line(),
  t({
    "  namespace: ",
  }),
  i(2, "default"),
  M.new_line(),
  t({
    "  labels:",
  }),
  M.new_line(),
  t({
    "    tags.datadoghq.com/service: ",
  }),
  i(3, "my-service"),
  M.new_line(),
  t({
    "    tags.datadoghq.com/env: ",
  }),
  c(4, {
    t("dev"),
    t("production"),
  }),
  M.new_line(),
  t({
    "    r35.io/service: ",
  }),
  d(5, function(args)
    return sn(nil, {
      i(1, args[1]),
    })
  end, { 3 }),
  M.new_line(),
  t({
    "    r35.io/env: ",
  }),
  d(6, function(args)
    return sn(nil, {
      i(1, args[1]),
    })
  end, { 4 }),
  M.new_line(),
  t({ "spec:" }),
  M.new_line(),
  t("  authentication:"),
  M.new_line(),
  t("    universalAuth:"),
  M.new_line(),
  t("      secretsScope:"),
  M.new_line(),
  t("        projectSlug: "),
  i(7, "rke2-core-workloads-a-ct6"),
  M.new_line(),
  t("        envSlug: "),
  i(8, "prod"),
  M.new_line(),
  t("        secretsPath: /"),
  d(9, function(args)
    return sn(nil, {
      i(1, args[1]),
    })
  end, { 3 }),
  M.new_line(),
  t("      credentialsRef:"),
  M.new_line(),
  t("        secretName: infisical-universal-auth"),
  M.new_line(),
  t("        secretNamespace: r35-system"),
  M.new_line(),
  t("  managedSecretReference:"),
  M.new_line(),
  t("    secretName: "),
  i(10, "my-secret"),
  M.new_line(),
  t("    secretNamespace: "),
  i(11, "default"),
  M.new_line(),
  t("    creationPolicy: "),
  c(12, {
    t("Owner"),
    t("Orphan"),
  }),
  M.new_line(),
})

return M
