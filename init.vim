" Install vim-plug
if has('win32') || has('win64')
    set shell=powershell
    let uri = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    if has('nvim')
        let al_dir =  "~/AppData/Local/nvim/autoload"
        let vim_plug_dir = "~/AppData/Local/nvim/autoload/plug.vim"
        let plugin_dir = '~/.local/share/nvim/plugged'
    else
        let al_dir =  "~/vimfiles/autoload"
        let vim_plug_dir = "~/vimfiles/autoload/plug.vim"
        let plugin_dir = '~/.vim/plugged'
    endif
    if empty(glob(vim_plug_dir))
        execute 'silent !md ' . al_dir
        execute 'silent !(New-Object Net.WebClient).DownloadFile(\"' . uri .
            \ '\", $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(\"' .
            \ vim_plug_dir . '\"))'
    endif
else
    if has('nvim')
        let vim_plug_dir = '~/.local/share/nvim/site/autoload/plug.vim'
        let plugin_dir = '~/.local/share/nvim/plugged'
    else
        let vim_plug_dir = '~/.vim/autoload/plug.vim'
        let plugin_dir = '~/.vim/plugged'
    endif
    if empty(glob(vim_plug_dir))
      execute "silent !curl -fLo " . vim_plug_dir . " --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
      autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
    endif
endif


let g:GuiInternalClipboard = 1
" Set Python interpreter
"let g:python3_host_prog = systemlist("which python3")[0]

" Specify a directory for plugins
call plug#begin('~/.local/share/nvim/plugged')

if has('nvim')
    Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' } " autocompletion framework
    Plug 'zchee/deoplete-jedi' " autocompletion source
    Plug 'w0rp/ale' " using flake8
    Plug 'ludovicchabant/vim-gutentags' " create, maintain tags (using universal-ctags)
    Plug 'majutsushi/tagbar', { 'on': 'TagbarToggle' }
endif
Plug 'NLKNguyen/papercolor-theme'
Plug 'hillenr14/tech_support'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

  " TODO: look into these plugins:
  " Explore files
  " Plug 'tpope/vim-vinegar'
  " Plug 'justinmk/vim-dirvish'
  " Plug 'tpope/vim-projectionist'
  
  " Git integration
  " Plug 'airblade/vim-gitgutter'
  " Plug 'tpope/vim-fugitive'

  " Other
  " Plug 'vimwiki/vimwiki'
  " Plug 'tpope/vim-surround'
  " Plug 'wellle/targets.vim'
  " Plug 'justinmk/vim-sneak'
  " Plug 'tpope/vim-unimpaired'
  " Plug 'kein/rainbow_parentheses.vim'
  " Plug 'fisadev/vim-sort'

  " TODO: Find autocompletion, linting plugins for js, React

call plug#end()

" General settings

" Remap leader
let mapleader="\<Space>"

" Finding files (:find), search down into subfolders, tab-completion
set path+=**

" Ignore case when searching unless upper case is used
set ignorecase
set smartcase

" Tab indent, settings
" Not sure exactly what is going on here, but these seem to give me what I
" need for now
" TODO: figure out how to set different tab values for different filetypes
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4

" Set absolute line number for the line under the cursor
set number
" Set relative line number for lines not under the cursor
set relativenumber

" Enable cursorline
set cursorline

" Set number of lines visible above/below the cursor when possible
set scrolloff=5
"
" Enable mouse support
set mouse=a

" Plugin settings

" deoplete.nvim, deoplete-jedi
let g:deoplete#enable_at_startup = 1
let g:deoplete#sources#jedi#show_docstring = 1
let g:deoplete#enable_ignore_case = 1
let g:deoplete#enable_smart_case = 1

" ale, flake8 settings
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_insert_leave = 1

" tagbar
let g:tagbar_autofocus = 1
nnoremap <silent> <F4> :TagbarToggle<CR>

"File type specific settings ---------------------- {{{
    augroup filetype_s
        autocmd!
        autocmd FileType vim setlocal foldmethod=marker | setlocal foldcolumn=2
        "autocmd FileType c setlocal foldmethod=syntax | setlocal foldcolumn=5
        autocmd FileType python setlocal foldmethod=indent | setlocal foldcolumn=5
        autocmd FileType tech_sup setlocal foldcolumn=2
    augroup END
" }}}
" Global auto commands ---------------------- {{{
    augroup global
        autocmd!
        autocmd BufReadPost * if len(tabpagebuflist()) == 1 | :tabmove | endif 
    augroup END
" }}}
" papercolor-theme
set background=dark
colorscheme PaperColor

