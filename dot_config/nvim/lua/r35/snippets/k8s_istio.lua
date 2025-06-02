local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local c = ls.choice_node
-- local fmt = require("luasnip.extras.fmt").fmt

local M = {}

M.virtual_service = s("istio-virtual-service", {
  t({
    "apiVersion: networking.istio.io/v1",
    "kind: VirtualService",
    "metadata:",
    "  name: ",
  }),
  -- i(1, "my-virtual-service"),
  -- t({
  --   "  namespace: ",
  -- }),
  -- i(2, "my-namespace"),
  -- t({
  --   "spec:",
  --   "  hosts:",
  --   "    - ",
  -- }),
  -- i(3, "service.example.com"),
  -- t({
  --   "  gateways:",
  --   "    - ",
  -- }),
  -- i(4, "ns/gateway-name"),
  -- t({
  --   "  http:",
  --   "    - name: ",
  -- }),
  -- d(5, function(args)
  --   return sn(nil, {
  --     i(1, args[1]),
  --   })
  -- end, { 1 }),
  -- t({
  --   "    match:",
  --   "      - uri:",
  --   "        prefix: /",
  --   "    route:",
  --   "      - destination:",
  --   "        host: ",
  -- }),
  -- d(6, function(args)
  --   return sn(nil, {
  --     i(1, args[1]),
  --     t({ "." }),
  --     i(2, args[2]),
  --     t({
  --       ".svc.cluster.local",
  --     }),
  --   })
  -- end, { 1, 2 }),
  -- t({
  --   "            port:",
  --   "              number: 80",
  -- }),
})

return M
