"
" Author: Ryan Tsien <i@bitbili.net>
"

nnoremap Y Y
set encoding=utf-8
set termencoding=utf-8
set fileencoding=utf-8

set backupdir=~/.cache/nvim/backup

set noexpandtab
set ts=8
set sw=8
set autoindent
set smarttab
set smartindent

set nu
set foldlevel=100
set foldmethod=syntax

set pastetoggle=<F7>

set cursorline
set cursorcolumn
set autoread
set noerrorbells
set novisualbell
set hlsearch
set backspace=start,indent,eol

set mouse=
set textwidth=80
set colorcolumn=+1,+2,+3,+4,+5,+6,+7,+8,+9,+10,+11,+12,+13,+14,+15,+16

map <M-l> :tabnext<CR>
map <M-h> :tabprevious<CR>
map <M-j> :bnext<CR>
map <M-k> :bprevious<CR>
map <M-S-l> :tabm +1<CR>
map <M-S-h> :tabm -1<CR>

syntax on
colorscheme modified_molokai
set termguicolors

call plug#begin()
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
let g:airline_theme = 'lessnoise'
let g:airline#extensions#searchcount#enabled = 0
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#branch#enabled = 1

Plug 'gentoo/gentoo-syntax'
let g:syntastic_ebuild_checkers = ['pkgcheck']
let g:syntastic_sh_checkers = ['sh', 'checkbashisms']

Plug 'windwp/nvim-autopairs'

Plug 'mg979/vim-visual-multi', {'branch': 'master'}
let g:VM_theme = 'ocean'
let @l = '\\c\\>'
let @a = "\\\\c\\\\<=\x1b["

Plug 'neoclide/coc.nvim', { 'branch': 'release' }
source ~/.config/nvim/coc.vim
call plug#end()

lua require('init')

" restore last position
if has("autocmd")
	augroup vimStartup
		au!
		autocmd BufReadPost *
			\ if line("'\"") >= 1 && line("'\"") <= line("$") |
			\   exe "normal! g`\"" |
			\ endif
	augroup END
endif

" workaround to set high priority of cursor line
" https://github.com/neovim/neovim/issues/9019#issuecomment-714806259
function! s:CustomizeColors()
	if has('gui_running') || &termguicolors || exists('g:gonvim_running')
		hi CursorLine ctermfg=white
	else
		hi CursorLine guifg=white
	endif
endfunction

augroup OnColorScheme
	autocmd!
	autocmd ColorScheme,BufEnter,BufWinEnter * call s:CustomizeColors()
augroup END

augroup MarkdownSpecific
	au!
	au FileType markdown,rst,text set
		\ expandtab ts=2 sw=2 tw=0
		\ colorcolumn=81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96
augroup END

augroup ConfigureSpecific
	au!
	au FileType toml,yaml set
		\ expandtab ts=2 sw=2 tw=0
		\ colorcolumn=81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96
augroup END
