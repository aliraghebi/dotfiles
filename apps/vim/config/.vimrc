" Settings {{{
syntax on

set encoding=utf-8
scriptencoding utf-8

" Stick unnamed register into system clipboard
if $TMUX ==# ''
  set clipboard+=unnamed
endif

set backspace=eol,start,indent
set autoindent
set smartindent
set wrap
set smarttab
set number
set expandtab
set fileformats=unix,dos

" Eliminate delay when pressing O
set timeout timeoutlen=1000 ttimeoutlen=100

set laststatus=2
set statusline=%f\ %=L:%l/%L\ %c\ (%p%%)

set guioptions-=T

set nobackup
set nowritebackup
set noswapfile

let mapleader = ' '

set ruler
set ignorecase
set smartcase
set autoread

set list listchars=tab:\ \ ,trail:·

set modeline
set modelines=5

set foldmethod=marker
set hlsearch

nmap <C-w>n :tabnext<CR>
nmap <C-w>p :tabprevious<CR>
nmap <C-w>c :tabnew<CR>

" }}}

" FileType Configurations {{{

augroup format
  autocmd!
  autocmd Filetype php        setlocal ts=4 sts=4 sw=4
  autocmd Filetype cpp        setlocal ts=4 sts=4 sw=4 expandtab
  autocmd Filetype json       setlocal ts=2 sts=2 sw=2 expandtab
  autocmd Filetype html       setlocal ts=2 sts=2 sw=2 expandtab
  autocmd Filetype javascript setlocal ts=2 sts=2 sw=2 expandtab
  autocmd Filetype vue.javascript setlocal ts=2 sts=2 sw=2 expandtab
  autocmd Filetype docker-compose setlocal ts=2 sts=2 sw=2 expandtab
  autocmd Filetype gitcommit  setlocal spell textwidth=72
  autocmd BufRead,BufNewFile *.vue   setlocal filetype=vue.javascript
  autocmd BufRead,BufNewFile .babelrc setlocal filetype=json
augroup end

" }}}

" Commands {{{

command Spellcheck setlocal spell spelllang=en_us

" }}}

" Plugins {{{

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'

if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

" Colorscheme
Plug '1995parham/naz.vim', { 'tag': 'v1.0.0' }

" Syntax & language support
Plug 'sheerun/vim-polyglot'
Plug 'pearofducks/ansible-vim'
Plug 'towolf/vim-helm'
Plug 'Joorem/vim-haproxy'

" Git
Plug 'airblade/vim-gitgutter'
Plug 'cohama/agit.vim'

" File explorer
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'

" Navigation & editing
Plug 'jeetsukumaran/vim-buffergator'
Plug 'wellle/targets.vim'

" Status line
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Utilities
Plug 'lambdalisue/suda.vim'
Plug 'wakatime/vim-wakatime'

call plug#end()

" }}}

" Plugin Configuration {{{

" naz.vim {{{
if has('termguicolors')
  set termguicolors
endif
let g:naz_term_italic = 0
colorscheme naz
" }}}

" gitgutter {{{
let g:gitgutter_enabled = 1
let g:gitgutter_eager = 0
highlight clear SignColumn
" }}}

" nerdtree {{{
map <C-n> :NERDTreeToggle<CR>
let g:NERDTreeGitStatusIndicatorMapCustom = {
  \ 'Modified'  : '✹',
  \ 'Staged'    : '✚',
  \ 'Untracked' : '✭',
  \ 'Renamed'   : '➜',
  \ 'Unmerged'  : '═',
  \ 'Deleted'   : '✖',
  \ 'Dirty'     : '✗',
  \ 'Clean'     : '✔︎',
  \ 'Ignored'   : '☒',
  \ 'Unknown'   : '?'
  \ }
" }}}

" airline {{{
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_buffers = 0
let g:airline#extensions#tagbar#enabled = 1
let g:airline_powerline_fonts = 1
let g:airline_theme = 'tomorrow'
let g:airline_section_c = '%{strftime("%c")}'
" }}}

" suda.vim {{{
let g:suda_smart_edit = 1
" }}}

" }}}
