-- spec/all.lua -- runs every *_spec.lua. Add new suites to the list below.
package.path = "./?.lua;" .. package.path

local runner = require("spec.runner")

local SUITES = {
  "spec.sanity_spec",
  "spec.registry_spec",
  "spec.icons_spec",
  "spec.deck_spec",
  "spec.clock_spec",
  "spec.actions_spec",
}

for _, s in ipairs(SUITES) do require(s) end

os.exit(runner.report())
