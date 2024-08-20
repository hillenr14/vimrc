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
call plug#begin(plugin_dir)
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' } " autocompletion framework
Plug 'zchee/deoplete-jedi' " autocompletion source
Plug 'w0rp/ale' " using flake8
if v:version >= 800
    Plug 'ludovicchabant/vim-gutentags' " create, maintain tags (using universal-ctags)
endif
Plug 'majutsushi/tagbar', { 'on': 'TagbarToggle' }
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
call plug#end()

" General settings ---------------------- {{{
    set path+=**
    set encoding=utf-8
    set expandtab
    set fileformats=unix,dos
    set shiftwidth=4
    set showmatch
    set softtabstop=4
    set tabstop=4
    set number
    set relativenumber
    set ttyfast
    set undolevels=255
    set visualbell
    set wrap
    set cursorline
    set mouse=a
    set scrolloff=5
    if  has('gui_win32')
        set guifont=Consolas:h9:cANSI
    elseif has('unix') && !has('mac')
"       set guifont=Courier\ 10
    elseif has('mac')
"       set guifont=Courier\ 9
    endif
    set ignorecase
    set smartcase
    set grepprg=grep\ -nH
    syntax on
    set hlsearch incsearch
    set backspace=indent,eol,start
    set guitablabel=\[%N\]\ %t\ %M
    set keymodel=startsel
    set virtualedit=block
    set switchbuf=usetab,newtab
    set guioptions+=A
    set guioptions-=T
" }}}
" key mappings ---------------------- {{{
    if !exists(":Bd")
        command Bd bp | sp | bn | bd
    endif
"   noremap <c-c> <c-Ins>
"   noremap <c-v> <s-Ins>
"   nnoremap / /\v
    let mapleader = ","
    nnoremap <leader>sv :source $MYVIMRC<cr>
    nnoremap <leader>ev :execute ":tabnew " . vimpath . "/my.vimrc"<cr>
"   nnoremap <leader>g :silent execute ":grep! " . shellescape(expand("<cWORD>")) . " '%'"<cr>:copen<cr>
    nnoremap <leader>j :lnext<cr>
    nnoremap <leader>k :lprevious<cr>
    nnoremap <leader>N :setlocal number!<cr>
    nnoremap <silent><C-]> <C-w><C-]><C-w>T
    if  has('mac')
        nnoremap <leader>gd :exe 'silent !open "http://dts.mv.usa.alcatel.com/dts/cgi-bin/viewReport.cgi?report_id="' . 
        \ matchstr(expand("<cword>"), '\v\d{6}')<cr>
    else
        nnoremap <leader>gd :exe 'silent ! start http://dts.mv.usa.alcatel.com/dts/cgi-bin/viewReport.cgi?report_id=' .
        \ matchstr(expand("<cword>"), '\v\d{6}')<cr>
    endif
" }}}
" Status line ---------------------- {{{
    set laststatus=2          " always show status line 
    set statusline=%f         " Path to the file
    set statusline+=\ -\      " Separator
    set statusline+=FileType: " Label
    set statusline+=%y        " Filetype of the file
    set statusline+=%=        " Switch to the right side
    set statusline+=%c        " Column
    set statusline+=-         " Separator
    set statusline+=%l        " Current line
    set statusline+=/         " Separator
    set statusline+=%L        " Total lines
" }}}
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

