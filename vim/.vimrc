" Show line numbers
set number

" Show relative numbers (great for jumping)
set relativenumber

" Show cursor position (line, column)
set ruler

" Highlight current line
set cursorline

" Highlight matching brackets
set showmatch

" Enable syntax highlighting
syntax on

" Enable filetype detection (python, yaml, json etc.)
filetype plugin indent on

" Indentation rules
set tabstop=4        " tab = 4 spaces
set shiftwidth=4     " indentation = 4 spaces
set expandtab        " use spaces instead of tabs
set autoindent       " copy indentation from previous line
set smartindent      " smarter indentation

" Search improvements
set ignorecase       " case insensitive
set smartcase        " unless uppercase used
set incsearch        " search while typing
set hlsearch         " highlight matches

" Better navigation experience
set scrolloff=5      " keep 5 lines above/below cursor

" Line width guide (THIS is your "line 80")
set colorcolumn=80

" Better splits
set splitbelow
set splitright

" Turn off annoying swap files
set noswapfile

" Clear search highlight with ESC
nnoremap <Esc> :nohlsearch<CR>