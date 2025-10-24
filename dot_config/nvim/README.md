# 💤 r35krag0th's LazyVim

A customized LazyVim configuration optimized for development work with Kubernetes, Go, Python, and web technologies.

## Custom Plugins

### Completion & Snippets

- [blink.cmp](https://github.com/saghen/blink.cmp) - Fast completion with emoji support
- [blink.compat](https://github.com/saghen/blink.compat) - nvim-cmp compatibility layer
- [blink-cmp-copilot](https://github.com/giuxtaposition/blink-cmp-copilot) - Copilot integration for blink.cmp
- [cmp-emoji](https://github.com/hrsh7th/cmp-emoji) - Emoji completion
- [friendly-snippets](https://github.com/rafamadriz/friendly-snippets) - Snippet collection
- [lspkind.nvim](https://github.com/onsails/lspkind.nvim) - VSCode-like pictograms

### Git Integration

- [neogit](https://github.com/NeogitOrg/neogit) - Magit-like Git interface
- [diffview.nvim](https://github.com/sindrets/diffview.nvim) - Advanced diff viewing

### Python Development

- [pymple.nvim](https://github.com/alexpasmantier/pymple.nvim) - Python import management and auto-updates

### UI & Navigation

- [snacks.nvim](https://github.com/folke/snacks.nvim) - Collection of QoL plugins including:
  - bigfile - Better large file handling
  - dashboard - Start screen
  - explorer - File explorer
  - picker - Fuzzy finder (with hidden files enabled by default)
  - notifier - Notifications
  - lazygit - LazyGit integration
  - scroll, indent, statuscolumn, words, etc.

### Language Support

- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) - Configured for:
  - bash, c, cpp, css, dockerfile
  - go, gomod, gosum, gowork
  - hcl, html, java, javascript, json, jsonc
  - lua, markdown, python, regex, rust
  - sql, toml, typescript, yaml

### Markdown & Notes

- [markview.nvim](https://github.com/OXY2DEV/markview.nvim) - Advanced markdown rendering with:
  - Custom checkbox states and rendering
  - Beautiful table rendering with rounded borders
  - Live preview with hybrid mode
  - Custom headings and list markers
- [follow-md-links.nvim](https://github.com/jghauser/follow-md-links.nvim) - Follow markdown links
- [yeahnotes.nvim](https://github.com/r35krag0th/yeahnotes.nvim) - Daily note-taking system with:
  - Navigate between daily notes
  - Task migration between days
  - Find and grep notes
  - Integration with mini.pick

### YAML & Kubernetes

- [schema-companion.nvim](https://github.com/cenk1cenk2/schema-companion.nvim) - YAML schema management
- [kube-schemas.nvim](https://github.com/r35krag0th/kube-schemas.nvim) - Kubernetes schema detection and insertion
  - Auto-detect resource type and apply appropriate schema
  - Search and insert schema modelines
  - Integration with datreeio CRDs catalog

### Other Tools

- [luarocks.nvim](https://github.com/vhyrro/luarocks.nvim) - Lua package management

## Custom Abstractions (lua/r35)

### Language Modules (`lua/r35/langs/`)

A modular system for language-specific configurations:

- **`init.lua`** - Language module registry and loader
- **`markdown.lua`** - Markdown configuration including markview.nvim and yeahnotes.nvim
- **`yaml.lua`** - YAML schema management with CRDs catalog integration
  - Keybindings: `<localleader>ysc` (inject schema), `<localleader>yss` (schema companion)
  - `<localleader>yks` (search k8s schemas), `<localleader>yka` (auto-detect)

### LSP Configuration (`lua/r35/lsp/`)

Centralized LSP setup with 30+ language servers:

- **Shell**: bashls, fish_lsp
- **Web**: cssls, html, jsonls, ts_ls, tailwindcss
- **Go**: gopls, golangci_lint_ls, dagger
- **Python**: pylsp, pyright
- **DevOps**: dockerls, docker_compose_language_service, helmls, terraformls, yamlls
- **Other**: cue, elixirls, gh_actions_ls, jsonnet_ls, kulala_ls, lua_ls, marksman, postgres_lsp

### Theme Management (`lua/r35/themes/`)

Centralized theme configuration with registry system:

- Default: `tokyonight`
- Available: nightfox, rosepine, vague, ayu
- Programmatic theme switching with dependency management

## LazyVim Extras

> [!NOTE]
> Complete extras list stored in [lazyvim.json](lazyvim.json)

### AI

- claudecode - Claude Code integration
- copilot - GitHub Copilot
- copilot-chat - Copilot Chat integration

### Coding

- luasnip - Snippet engine
- mini-surround - Surround text objects
- neogen - Documentation generation

### DAP (Debug Adapter Protocol)

- core - Core DAP functionality
- nlua - Lua debugging

### Editor

- aerial - Code outline
- dial - Enhanced increment/decrement
- inc-rename - LSP rename with preview
- mini-diff - Git diff visualization
- outline - Symbol outline
- refactoring - Code refactoring support
- snacks_explorer - File explorer (Snacks)
- snacks_picker - Fuzzy picker (Snacks)

### Formatting

- prettier - Code formatting

### Languages

- docker - Dockerfile support
- git - Git integration
- go - Go development
- helm - Helm chart support
- json - JSON support
- markdown - Enhanced markdown
- python - Python development
- sql - SQL support
- svelte - Svelte framework
- tailwind - Tailwind CSS
- terraform - Terraform/HCL
- toml - TOML support
- typescript - TypeScript/JavaScript
- vue - Vue.js framework
- yaml - YAML support

### Testing

- core - Test framework integration

### Utilities

- gh - GitHub CLI integration
- mini-hipatterns - Text pattern highlighting

## Features

- **Hidden Files**: File picker shows hidden files by default
- **Git Workflow**: Comprehensive Neogit keybindings for all Git operations
- **Python IDE**: Automatic import management with pymple.nvim
- **Completion**: Fast blink.cmp with emoji support and Copilot integration
- **Modern UI**: Snacks.nvim for enhanced user experience
