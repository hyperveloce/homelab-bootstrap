" Enable true color support (for better rendering)
set termguicolors

" Enable line numbers
set number

" Enable relative line numbers
set relativenumber

" Enable syntax highlighting
syntax enable

" Enable search highlighting
set hlsearch

" Enable incremental search
set incsearch

" Highlight the current line
set cursorline

" Set the tab stop and indentation
set tabstop=4
set shiftwidth=4
set expandtab

" Enable file type detection, plugins, and indentation
filetype plugin indent on

" Tokyo Night color scheme plugin
call plug#begin('~/.vim/plugged')
Plug 'folke/tokyonight.nvim'
call plug#end()

" Set Tokyo Night color scheme (night version)
let g:tokyonight_style = 'night'
colorscheme tokyonight   " or tokyonight-day for light theme

" Optional: Customize syntax highlighting (example)
highlight Keyword ctermfg=Blue guifg=#FF0000

" Enable clipboard integration (if supported)
set clipboard=unnamedplus

" Auto-indent on new lines
set smartindent
set autoindent
set smarttab

" Enable wrapping of long lines
set wrap

" Enable line numbers
set number

