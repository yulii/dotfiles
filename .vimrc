set number
set autoindent
set tabstop=2
set shiftwidth=2
set expandtab

set hlsearch
nmap <Esc><Esc> :nohlsearch<CR><Esc>

" 保存時に行末の空白を除去する
autocmd BufWritePre * :%s/\s\+$//ge
" 保存時にtabを2スペースに変換する
autocmd BufWritePre * :%s/\t/  /ge
" 保存時の処理後カーソル位置を戻す
function! s:remove_dust()
    let cursor = getpos(".")
    %s/\s\+$//ge
    %s/\t/  /ge
    call setpos(".", cursor)
    unlet cursor
endfunction
autocmd BufWritePre * call <SID>remove_dust()

augroup Binary
  au!
  au BufReadPre  *.bin let &bin=1
  au BufReadPost * if &bin | %!xxd
  au BufReadPost * set ft=xxd | endif
  au BufWritePre * if &bin | %!xxd -r
  au BufWritePre * endif
  au BufWritePost * if &bin | %!xxd
  au BufWritePost * set nomod | endif
augroup END

au BufRead,BufNewFile *.json set filetype=json
au BufRead,BufNewFile *.json.jpbuilder,*.json.jbuilder set filetype=ruby

"" Vundle
"set nocompatible
"filetype plugin indent off
"
"if has('vim_starting')
"  set runtimepath+=~/.vim/bundle/neobundle.vim
"  call neobundle#begin(expand('~/.vim/bundle/'))
"  NeoBundleFetch 'Shougo/neobundle.vim'
"  call neobundle#end()
"endif
"
"NeoBundleFetch 'Shougo/neobundle.vim'
"
"NeoBundle 'Shougo/neocomplcache'
"NeoBundle 'Shougo/neocomplcache-rsense'
"NeoBundle 'elzr/vim-json'
"NeoBundle 'slim-template/vim-slim.git'
"NeoBundle 'mattn/emmet-vim'
"NeoBundle 'tpope/vim-rails'
"
"filetype plugin indent on

"" neocomplcache
"let g:neocomplcache_enable_at_startup = 1
"let g:neocomplcache_max_list = 20
"let g:neocomplcache_manual_completion_start_length = 3
"let g:neocomplcache_enable_ignore_case = 1
"let g:neocomplcache_enable_smart_case = 1
"" demiliter for function compl
"if !exists('g:neocomplcache_delimiter_patterns')
"  let g:neocomplcache_delimiter_patterns = {}
"endif

syntax enable
