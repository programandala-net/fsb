" ~/.vim/ftdetect/fsb.vim

" Vim filetype detect for fsb format of Forth source

" By Marcos Cruz (programandala.net)

" This file is part of fsb
" http://programandala.net/en.program.fsb.html

" 2015-03-17

autocmd BufNewFile,BufRead *.fsb setlocal filetype=forth
autocmd BufNewFile,BufRead *.fsb runtime fsb.vim

