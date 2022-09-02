let mapleader=','
let maplocalleader='['
" let g:plug_url_format='ssh://git@github.com:%s.git'

" We don't need the perl provider, ever
let g:loaded_perl_provider = 0

set directory=$HOME/.vim/swap
set backupdir=$HOME/.vim/backups
set rtp+=$HOME/.vim/syntax/zeromicro_api.vim

function! PyEnvVirtEnvCheck()
    let pyenv_virtenv_python3_bin = expand('~/.pyenv/versions/neovim/bin/python3')
    let pyenv_virtenv_python2_bin = expand('~/.pyenv/versions/neovim-python2/bin/python2')

    if !empty(glob(pyenv_virtenv_python3_bin))
        " echom 'Using virtualenv binary for Python3'
        let g:python3_host_prog = pyenv_virtenv_python3_bin
    " else
    "     echom 'Using system binary for Python3'
    endif

    if !empty(glob(pyenv_virtenv_python2_bin))
        " echom 'Using virtualenv binary for Python2'
        let g:python_host_prog = pyenv_virtenv_python2_bin
    " else
    "     echom 'Using system binary for Python2'
    endif
endfunction

" Figure out which Python Install to use
call PyEnvVirtEnvCheck()

call plug#begin('~/.vim/plugged')

" [GENERAL]
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'scrooloose/nerdtree'
"Plug 'tsony-tsonev/nerdtree-git-plugin'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
Plug 'ryanoasis/vim-devicons'
Plug 'airblade/vim-gitgutter'
Plug 'ctrlpvim/ctrlp.vim' " fuzzy find files
Plug 'scrooloose/nerdcommenter'
"Plug 'prettier/vim-prettier', { 'do': 'yarn install' }
Plug 'christoomey/vim-tmux-navigator'
Plug 'tpope/vim-commentary'
Plug 'chentoast/marks.nvim'
Plug 'MattesGroeger/vim-bookmarks'  " FzfPreviewBookmarks
Plug 'glidenote/memolist.vim'       " FzfPreviewMemoList, FzfPreviewMemoListGrep
Plug 'nvim-lua/plenary.nvim'        " (dependency for todo-comments)
Plug 'folke/todo-comments.nvim'     " FzfPreviewTodoComments

" [STATUS LINE]
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" [THEMES]
Plug 'morhetz/gruvbox'
Plug 'google/vim-jsonnet'

" [SYNTAX]
Plug 'HerringtonDarkholme/yats.vim' " Typescript
Plug 'hashivim/vim-consul'          " Hashicorp Consul
Plug 'hashivim/vim-nomadproject'    " Hashicorp Nomad Project
Plug 'hashivim/vim-ottoproject'     " Hashicorp Otto Project
Plug 'hashivim/vim-packer'          " Hashicorp Packer
Plug 'hashivim/vim-terraform'       " Hashicorp Terraform
Plug 'hashivim/vim-vagrant'         " Hashicorp Vagrant
Plug 'hashivim/vim-vaultproject'    " Hashicorp Vault Project
Plug 'farfanoide/vim-kivy'          " Kivy --> https://kivy.org/#home
" Plug 'dense-analysis/ale'                 " (A)synchronus (L)inting (E)ngine
Plug 'elixir-editors/vim-elixir'    " Elixir
Plug 'cespare/vim-toml'             " TOML
Plug 'vim-scripts/openvpn'          " OpenVPN Configs
Plug 'towolf/vim-helm'              " Helm Charts
Plug 'cappyzawa/starlark.vim'       " Starlark (and ...)
Plug 'jparise/vim-graphql'          " GraphQL
Plug 'chr4/nginx.vim'               " Nginx
Plug 'evanleck/vim-svelte', {'branch': 'main'} " Svelte
Plug 'fladson/vim-kitty'            " kitty.conf (Terminal)

" TreeSitter
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" UI goodies
Plug 'kyazdani42/nvim-web-devicons'
Plug 'romgrk/barbar.nvim'
" Requires: npm install -g neovim
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'yuki-yano/fzf-preview.vim', { 'branch': 'release/rpc' }

" Debugger
Plug 'mfussenegger/nvim-dap'
Plug 'rcarriga/nvim-dap-ui'

" Python Goodies
Plug 'mfussenegger/nvim-dap-python'

" Go Goodies
Plug 'fatih/vim-go', {'do': ':GoUpdateBinaries'}
Plug 'leoluz/nvim-dap-go'

call plug#end()

let g:airline_theme='distinguished'

inoremap jk <ESC>
nmap <C-n> :NERDTreeToggle<CR>
vmap ++ <plug>NERDCommenterToggle
nmap ++ <plug>NERDCommenterToggle

" Open NERDTree Automatically
" autocmd StdinReadPre    * let s:std_in=1
" autocmd VimEnter        * NERDTree

let g:NERDTreeGitStatusWithFlags = 1
let g:WebDevIconsUnicodeDecorateFolderNodes = 1
let g:NERDTreeGitStatusNodeColorization = 1
" let g:NERDTreeColorMapCustom = {
"     \ "Staged"    : "#0ee375",
"     \ "Modified"  : "#d9bf91",
"     \ "Renamed"   : "#51C9FC",
"     \ "Untracked" : "#FCE77C",
"     \ "Unmerged"  : "#FC51E6",
"     \ "Dirty"     : "#FFBD61",
"     \ "Clean"     : "#87939A",
"     \ "Ignored"   : "#808080"
"     \ }

let g:NERDTreeIgnore = ['^node_modules$']

" ==> vim-prettier
" let g:prettier#quickfix_enabled = 0
" let g:prettier#quickfix_auto_focus = 0

" --- prettier command for coc.vim
command! -nargs=0 Prettier :CocCommand prettier.formatFile

" ==> ctrlp
let g:ctrlp_user_command = [
    \ '.git/',
    \ 'git --git-dir=%s/.git ls-files -oc --exclude-standard'
    \ ]

" j/k will move virtual lines (lines that wrap)
noremap <silent> <expr> j (v:count == 0 ? 'gj' : 'j')
noremap <silent> <expr> k (v:count == 0 ? 'gk' : 'k')

set norelativenumber
set number
set smarttab
set cindent
set tabstop=2
set shiftwidth=2
set expandtab

set nobackup			" Don't write a backup when overwriting a file
set nowritebackup		" Don't write a backup when overwriting a file

colorscheme gruvbox

function! IsNERDTreeOpen()
    return exists("t:NERDTreeBufName") && (bufwinnr(t:NERDTreeBufName) != -1)
endfunction

function! SyncTree()
    if &modifiable && IsNERDTreeOpen() && strlen(expand('%')) > 0 && !&diff
        NERDTreeFind
        wincmd p
    endif
endfunction

autocmd BufEnter * call SyncTree()

" A Snippet Solution    - https://github.com/neoclide/coc-snippets
" Auto-pairs            - https://github.com/neoclide/coc-pairs
" TS & JS Support       - https://github.com/neoclide/coc-tsserver
" ESLint Support        - https://github.com/neoclide/coc-eslint
" Fork of vscode ext    - https://github.com/neoclide/coc-prettier
" JSON Support          - https://github.com/neoclide/coc-json
" Go support            - https://github.com/josa42/coc-go
" ======================= Additional things =================================
" Dot completion        - https://github.com/voldikss/coc-dot-complete
" Git Integration       - https://github.com/neoclide/coc-git
" MarkdownLint Support  - https://github.com/fannheyward/coc-markdownlint
" Provides basic lists  - https://github.com/neoclide/coc-lists
" Default Highlighting  - https://github.com/neoclide/coc-highlight
" Python support        - https://github.com/fannheyward/coc-pyright
" .viml support         - https://github.com/iamcco/coc-vimlsp
" .xml support          - https://github.com/fannheyward/coc-xml
" Rust Lang Server      - https://github.com/neoclide/coc-rls
" Emojis                - https://github.com/neoclide/coc-sources (monorepo)
" YAML!                 - https://github.com/neoclide/coc-yaml
" Yank highlighting     - https://github.com/neoclide/coc-YANK

    " \ 'coc-dot-complete',
let g:coc_global_extensions = [
    \ 'coc-css',
    \ 'coc-emoji',
    \ 'coc-eslint',
    \ 'coc-elixir',
    \ 'coc-git',
    \ 'coc-go',
    \ 'coc-highlight',
    \ 'coc-json',
    \ 'coc-lists',
    \ 'coc-markdownlint',
    \ 'coc-pairs',
    \ 'coc-prettier',
    \ 'coc-pyright',
    \ 'coc-rls',
    \ 'coc-snippets',
    \ 'coc-tsserver',
    \ 'coc-vimlsp',
    \ 'coc-xml',
    \ 'coc-yaml',
    \ 'coc-yank',
    \ 'coc-fzf-preview',
    \ ]

set hidden
set updatetime=300

" don't give |ins-completion-menu| messages
set shortmess+=c

" always show signcolumns
set signcolumn=yes

inoremap <silent><expr> <TAB>
            \ pumvisible() ? "\<TAB>" :
            \ <SID>check_back_space() ? "\<TAB>" :
            \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1] =~# '\s'
endfunction

inoremap <silent><expr> <c-space> coc#refresh()

"       gd = go to definition
"       gy = go to type definition
"       gi = go to implementation
"       gr = show references (bottom pane)
"       gO = show outline (right pane)
"     <f2> = refactor -> rename
"       ,f = format selected
"       ,a = code action selected (,aap to hit paragraph)
"      ,ac = code action for line
"      ,af = auto-fix problem for current line
" <space>a = (coc) show all diagnostics
" <space>e = (coc) manage extensions
" <space>c = (coc) show commands
" <space>o = (coc) find symbol of current document
" <space>s = (coc) search workspace symbols
" <space>j = (coc) do default action for next item
" <space>k = (coc) do default action for prev item
" <space>p = (coc) resume latest coc list
" <space>w = (coc) grep current word in current buffer

" inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>y\<CR>"
" Use `[g` and `]g` to navigate diagnostics
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Show the outline pane
nmap <silent> gO <Plug>(coc-outline)

" Use K to show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Highlight symbol under cursor on CursorHold
autocmd CursorHold * silent call CocActionAsync('highlight')

" Remap for rename current word
nmap <F2> <Plug>(coc-rename)

" Remap for format selected region
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Remap for do codeAction of selected region, ex: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap for do codeAction of current line
nmap <leader>ac  <Plug>(coc-codeaction)
" Fix autofix problem of current line
nmap <leader>qf  <Plug>(coc-fix-current)

" Create mappings for function text object, requires document symbols feature of languageserver.
xmap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap if <Plug>(coc-funcobj-i)
omap af <Plug>(coc-funcobj-a)

" Use <C-d> for select selections ranges, needs server support, like: coc-tsserver, coc-python
nmap <silent> <C-d> <Plug>(coc-range-select)
xmap <silent> <C-d> <Plug>(coc-range-select)

" Use `:Format` to format current buffer
command! -nargs=0 Format :call CocAction('format')

" Use `:Fold` to fold current buffer
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" use `:OR` for organize import of current buffer
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" add gtj for json tags (golang) and gty tags
autocmd FileType go nmap gtj :CocCommand go.tags.add json<cr>
autocmd FileType go nmap gty :CocCommand go.tags.add yaml<cr>
autocmd FileType go nmap gtx :CocCommand go.tags.clear<cr>

" Add status line support, for integration with other plugin, checkout `:h coc-status`
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Using CocList
" Show all diagnostics
nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions
nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
" Show commands
nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document
nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols
nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list
nnoremap <silent> <space>p  :<C-u>CocListResume<CR>
" Grep current word in current buffer (via coc-lists)
nnoremap <silent> <space>w  :exe 'CocList -I --normal --input='.expand('<cword>').' words'<CR>

" Ruby Provider -> gem install neovim
let g:ruby_host_prog='$HOME/.rbenv/versions/2.6.9/bin/neovim-ruby-host'

augroup Standard
  au!
  au BufWritePre * :mark `|:%s/\s\+$//e|normal ``      " kill trailing whitespace at the end of lines before writing.
  au BufRead,BufNewFile *.api set filetype=zeromicro_api
augroup END

" Go Stuffs
" ===============================

" disable all linters as that is taken care of by coc.nvim
let g:go_diagnostics_enabled = 0
let g:go_metalinter_enabled = []

" don't jump to errors after metalinter is invoked
let g:go_jump_to_error = 0

" run go imports on file save
let g:go_fmt_command = "goimports"

" automatically highlight variable under cursor
let g:go_auto_sameids = 0

" >>> Syntax Highlighting
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_operators = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_generate_tags = 1

" NOTE: You'll want to run `:GoInstallBinaries` to get started
" NOTE: You'll also want to have a few CoC plugins installed
"       coc-go, coc-html, coc-css, coc-json
" NOTE: `:CocInstall -sync coc-go coc-html coc-css coc-json|q`

" TextEdit might fail if hidden is not set.
set hidden

colorscheme gruvbox
autocmd ColorScheme * highlight CocErrorFloat guifg=#ffffff
autocmd ColorScheme * highlight CocInfoFloat guifg=#ffffff
autocmd ColorScheme * highlight CocWarningFloat guifg=#ffffff
autocmd ColorScheme * highlight SignColumn guibg=#adadad
autocmd ColorScheme * highlight CocWarningSign guibg=#ffffff

" Some servers have issues with backup files, see #649.
set nobackup
set nowritebackup

" Give more space for displaying messages.
set cmdheight=2

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Only show signcolumn on errors
set signcolumn=auto

" function! CheckBackSpace() abort
"   let col = col('.') - 1
"   return !col || getline('.')[col - 1]  =~ '\s'
" endfunction

" " Insert <tab> when previous text is space, refresh completion if not.
" inoremap <silent><expr> <TAB>
"       \ coc#pum#visible() ? coc#pum#next(1):
"       \ CheckBackSpace() ? "\<Tab>" :
"       \ coc#refresh()
" inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
  inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
  inoremap <silent><expr> <C-x><C-z> coc#pum#visible() ? coc#pum#stop() : "\<C-x>\<C-z>"
  " remap for complete to use tab and <cr>
  inoremap <silent><expr> <TAB>
        \ coc#pum#visible() ? coc#pum#next(1):
        \ <SID>check_back_space() ? "\<Tab>" :
        \ coc#refresh()
  inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
  inoremap <silent><expr> <c-space> coc#refresh()

  hi CocSearch ctermfg=12 guifg=#18A3FF
  hi CocMenuSel ctermbg=109 guibg=#13354A

" GoTo code navigation.

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Remap <C-f> and <C-b> for scroll float windows/popups.
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
  inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
  inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
  vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif

" Go Bindings
" ===========

" [leader t] run tests
autocmd BufEnter *.go nmap <leader>t 		<Plug>(go-test)
" [leader tt] run current test
autocmd BufEnter *.go nmap <leader>tt 	<Plug>(go-test-func)
" [leader c] toggle coverage
autocmd BufEnter *.go nmap <leader>c 		<Plug>(go-coverage-toggle)

" [leader i] show func signature
autocmd BufEnter *.go nmap <leader>i		<Plug>(go-info)
" [leader ii] show interfaces a type implements
autocmd BufEnter *.go nmap <leader>ii   <Plug>(go-implements)
" [leader ci] describe the definition of a given type
autocmd BufEnter *.go nmap <leader>ci   <Plug>(go-describe)
" [leader cc] see callers for a given function
autocmd BufEnter *.go nmap <leader>cc   <Plug>(go-callers)
" [leader cr] find all references
autocmd BufEnter *.go nmap <leader>cr   <Plug>(coc-references)
" [CTRL a, CTRL o] go to definition
nmap <C-a>      <C-o>
nmap <C-d>      <Plug>(coc-definition)
" [leader r] refactor code
nmap <leader>r  <Plug>(coc-rename)

" NOTE: Occasionally you will need to `GoUpdateBinaries` and `CocUpdate`
"
" AirLine + CoC STATUS
" Disable vim-airline integration:
let g:airline#extensions#coc#enabled = 0
" Change error symbol:
let airline#extensions#coc#error_symbol = 'Error:'
" Change warning symbol:
let airline#extensions#coc#warning_symbol = 'Warning:'
" Change error format:
let airline#extensions#coc#stl_format_err = '%E{[%e(#%fe)]}'
" Change warning format:
let airline#extensions#coc#stl_format_warn = '%W{[%w(#%fw)]}'

" Register Go DAP
lua require('dap-go').setup()

" barbar configuration
" [Movement]
nnoremap <silent> <A-,> <Cmd>BufferPrevious<CR>
nnoremap <silent> <A-.> <Cmd>BufferNext<CR>

" [Re-Ordering]
nnoremap <silent> <A-<> <Cmd>BufferMovePrevious<CR>
nnoremap <silent> <A->> <Cmd>BufferMoveNext<CR>

" [Go to Buffer in position]
nnoremap <silent> <A-1> <Cmd>BufferGoto 1<CR>
nnoremap <silent> <A-2> <Cmd>BufferGoto 2<CR>
nnoremap <silent> <A-3> <Cmd>BufferGoto 3<CR>
nnoremap <silent> <A-4> <Cmd>BufferGoto 4<CR>
nnoremap <silent> <A-5> <Cmd>BufferGoto 5<CR>
nnoremap <silent> <A-6> <Cmd>BufferGoto 6<CR>
nnoremap <silent> <A-7> <Cmd>BufferGoto 7<CR>
nnoremap <silent> <A-8> <Cmd>BufferGoto 8<CR>
nnoremap <silent> <A-9> <Cmd>BufferGoto 9<CR>
nnoremap <silent> <A-0> <Cmd>BufferLast<CR>

" [Pin/Un-Pin]
nnoremap <silent> <A-p> <Cmd>BufferPin<CR>
nnoremap <silent> <A-c> <Cmd>BufferClose<CR>
" Additional Things
" :BufferCloseAllButCurrent
" :BufferCloseAllButPinned
" :BufferCloseAllButCurrentOrPinned
" :BufferCloseBuffersLeft
" :BufferCloseBuffersRight

" [Magic Buffer-picker]
nnoremap <silent> <C-p> <Cmd>BufferPick<CR>

" [Sorting]
nnoremap <silent> <Space>bb <Cmd>BufferOrderByBufferNumber<CR>
nnoremap <silent> <Space>bd <Cmd>BufferOrderByDirectory<CR>
nnoremap <silent> <Space>bl <Cmd>BufferOrderByLanguage<CR>
nnoremap <silent> <Space>bw <Cmd>BufferOrderByWindowNumber<CR>

" ==> fzf-preview
nmap <Leader>f [fzf-p]
xmap <Leader>f [fzf-p]

nnoremap <silent> [fzf-p]p     :<C-u>CocCommand fzf-preview.FromResources project_mru git<CR>
nnoremap <silent> [fzf-p]gs    :<C-u>CocCommand fzf-preview.GitStatus<CR>
nnoremap <silent> [fzf-p]ga    :<C-u>CocCommand fzf-preview.GitActions<CR>
nnoremap <silent> [fzf-p]b     :<C-u>CocCommand fzf-preview.Buffers<CR>
nnoremap <silent> [fzf-p]B     :<C-u>CocCommand fzf-preview.AllBuffers<CR>
nnoremap <silent> [fzf-p]o     :<C-u>CocCommand fzf-preview.FromResources buffer project_mru<CR>
nnoremap <silent> [fzf-p]<C-o> :<C-u>CocCommand fzf-preview.Jumps<CR>
nnoremap <silent> [fzf-p]g;    :<C-u>CocCommand fzf-preview.Changes<CR>
nnoremap <silent> [fzf-p]/     :<C-u>CocCommand fzf-preview.Lines --add-fzf-arg=--no-sort --add-fzf-arg=--query="'"<CR>
nnoremap <silent> [fzf-p]*     :<C-u>CocCommand fzf-preview.Lines --add-fzf-arg=--no-sort --add-fzf-arg=--query="'<C-r>=expand('<cword>')<CR>"<CR>
nnoremap          [fzf-p]gr    :<C-u>CocCommand fzf-preview.ProjectGrep<Space>
xnoremap          [fzf-p]gr    "sy:CocCommand   fzf-preview.ProjectGrep<Space>-F<Space>"<C-r>=substitute(substitute(@s, '\n', '', 'g'), '/', '\\/', 'g')<CR>"
nnoremap <silent> [fzf-p]t     :<C-u>CocCommand fzf-preview.BufferTags<CR>
nnoremap <silent> [fzf-p]q     :<C-u>CocCommand fzf-preview.QuickFix<CR>
nnoremap <silent> [fzf-p]l     :<C-u>CocCommand fzf-preview.LocationList<CR>

" todo-comments loading & configuration
lua << EOF
  require("todo-comments").setup {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  }
EOF
