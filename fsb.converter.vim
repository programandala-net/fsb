" fsb.converter.vim

" fsb

" A Forth source preprocessor and converter
" for making classic blocks files with the Vim editor

" Version 0.14.0-pre.0+201803252336
" See change log at the end of the file

" ==============================================================
" Author and license

" Copyright (C) 2015,2016,2017,2018 Marcos Cruz (programandala.net)

" You may do whatever you want with this work, so long as you
" retain the copyright notice(s) and this license in all
" redistributed copies and derived works. There is no warranty.

" ==============================================================
" Description

" fsb is a plugin for the Vim editor. It makes it easy to edit
" Forth source, in ordinary text format, for Forth systems that
" need a blocks file.
"
" Some simple layout conventions are used to mark the start of
" Forth blocks and to make metacomments (that will be removed
" from the target blocks file, as well as empty lines).
"
" See the file <README.adoc> for full details.

" ==============================================================
" History

" See at the end of the file

" ==============================================================
" To-do

" 2015-03-25: Try the 32x32 format.
"
" 2015-03-29: Fix: a blank block is added when the last one has
" 16 lines.
"
" 2015-05-14: New: `#block` directive to mark the start of a
" block.

" ==============================================================
" Boot

" XXX TMP -- commented out during development
if exists("b:loaded_fsb")
   finish
endif
let b:loaded_fsb = 1

" ==============================================================
" Style

function! FsbToggleTheStyle()

  " Toggle the highlighting style specific to the .fsb format,
  " and set some formatting options.

  let b:fsbStyle=invert(b:fsbStyle)

  if b:fsbStyle


    " `textwidth` is set to one less than the characters per
    " line because some Forth systems compile blocks as a whole,
    " not by lines, and the code at the end of a line could join
    " the code at the start of the following line.
    "
    " XXX TODO Make this configurable with a '#cpl' directive.

    execute 'setlocal textwidth='.b:charsPerLineMinus1

    " Mark the right limit.
    " It's just a visual help for the user -- a check
    " will be done before the conversion.
    execute 'setlocal colorcolumn='.b:charsPerLine

    " Highlight the first line of every block
    hi def link forthBlockTitle Underlined
    execute 'match forthBlockTitle /'.s:blockHeaderExpression.'/'

  else

    setlocal colorcolumn=
    match none

  endif

endfunction

function! FsbToggleTheFormat()

  " Toggle the layout of the blocks between 16x64 (default) and 32x32.

  let b:standardFormat=invert(b:standardFormat)
  call FsbSetTheFormat(b:standardFormat)

endfunction

function! FsbSetTheFormat(standard)

  if a:standard

    let b:standardFormat=s:true
    let b:charsPerLine=64
    let b:linesPerBlock=16
    " For string expressions where calculations don't work:
    let b:charsPerLineMinus1=63
    let b:linesPerBlockMinus1=15

    " echomsg "Current format: 16x64 blocks"

  else

    let b:standardFormat=s:false
    let b:charsPerLine=32
    let b:linesPerBlock=32
    " For string expressions where calculations don't work:
    let b:charsPerLineMinus1=31
    let b:linesPerBlockMinus1=31

    " echomsg "Current format: 32x32 blocks"

  endif

  " XXX TODO Make this configurable with a '#cpl' directive.
  execute 'setlocal textwidth='.b:charsPerLineMinus1

  " Mark the right limit.
  " It's just a visual help for the user -- a check
  " will be done before the conversion.
  execute 'setlocal colorcolumn='.b:charsPerLine

endfunction

" ==============================================================
" Misc

function! FsbTrim(string)

  " Remove the leading and trailing spaces from a string.
  " Reference:
  " http://stackoverflow.com/questions/4478891/is-there-a-vimscript-equivalent-for-rubys-strip-strip-leading-and-trailing-s

  return substitute(a:string, '^\s*\(.\{-}\)\s*$', '\1', '')

endfunction

" ==============================================================
" Movement

" The movement functions are mapped to function keys at the end
" of the file. They help organize the source file in blocks.

function! FsbValidLine()

  " Is the current line valid?

  " Invalid lines are empty lines or metacomments (backslash
  " comments that don't start at the first column).

  " Invalid lines are ignored and will not be converted to the
  " target format.

  let l:line=getline(line('.')) " current line
  return match(l:line,'^\s*$')==-1 && match(l:line,'^\s\+\\\(\s.*\)\?$')==-1

endfunction

function! FsbMaxValidLinesUp()

  " Move the cursor up the maximum number of valid lines,
  " ignoring invalid lines.

  let l:count=b:linesPerBlock
  while l:count
    if FsbValidLine()
      let l:count=l:count-1
    endif
    call cursor(line('.')-1,1)
  endwhile

endfunction

function! FsbAtLastLine()

  " Is the cursor at the last line of the buffer?

  return line('.')==line('$')

endfunction

function! FsbMaxValidLinesDown()

  " Move the cursor down the maximum number of valid lines,
  " ignoring invalid lines.

  let l:count=b:linesPerBlock
  while l:count && !FsbAtLastLine()
    if FsbValidLine()
      let l:count=l:count-1
    endif
    call cursor(line('.')+1,1)
  endwhile

endfunction

function! FsbPreviousBlock()

  " Go to the header line of the previous block.

  silent! call search(s:blockHeaderExpression,'Wb')

endfunction

function! FsbTopOfBlock()

  " Go to the header line of the current block.
  " Update `s:indexLine` and `s:paddedIndexLine`.

  if !search(s:blockHeaderExpression,'Wbc')
    call cursor(1,1)
  endif

  let s:indexLine=getline(line('.'))
  let s:paddedIndexLine=s:indexLine.repeat(" ",b:charsPerLine-strlen(s:indexLine))

endfunction

function! FsbNextBlock()

  " Go to the header line of the next block.

  silent! let l:success=search(s:blockHeaderExpression,'W')
  if !l:success
    " Go to the end of the file
    normal G
  endif

endfunction

function! FsbGoToBlock(block)

  " Go to the header of the given block number, (the first block
  " is 0).

  let l:block=a:block
  call cursor(1,1)
  while l:block
    call FsbNextBlock()
    let l:block=l:block-1
  endwhile

endfunction

function! FsbGoToBlockFromEnd(block)

  " Go to the header of given block number, counting backwards
  " from the end of the file (the last block is 0).

  let l:block=a:block+1
  call cursor(line('$'),1)
  while l:block
    call FsbPreviousBlock()
    let l:block=l:block-1
  endwhile

endfunction

function! FsbBottomOfBlock()

  " Go to the last non-empty line of the current block.

  call FsbNextBlock()

  " If the cursor is at the end of the file, it's not at the
  " header of a block, so the 'c' search flag is used in order
  " to accept a match at the cursor position:

  let l:searchFlags= FsbAtLastLine() ? 'Wbc' : 'Wb'
  call search('^.*\S',l:searchFlags)

  " XXX FIXME -- this fails when the last block is empty.
  " XXX FIXME -- this fails when the last block has any empty line at the end

endfunction

" ==============================================================
" Checks

function! FsbIsHeader(lineNumber)

  " Is the given line a block header?

   return match(getline(a:lineNumber),s:blockHeaderExpression)==0

endfunction

function! FsbLineTooLongError()
  echoerr "line" line('.') "is longer than" b:charsPerLineMinus1 "characters"
endfunction

function! FsbCheckLines(silent)

  " Check the lenght of all lines, regardless of blocks. This is
  " useful when editing sources in FSA format, which has no
  " block headers except the first one.

  let l:errorFlag=0

  let l:currentLine=line('.')
  let l:currentCol=col('.')

  let l:validLines=0 " counter
  call cursor(1,1)

  while !FsbAtLastLine() " not end of file?

    let l:validLine=FsbValidLine()
    if l:validLine
      let l:errorFlag=strchars(getline(line('.')))>b:charsPerLineMinus1
      if l:errorFlag
        call FsbLineTooLongError()
        break
      endif
    endif

    call cursor(line('.')+1,1) " move to next line

  endwhile

  echohl none
  return l:errorFlag

endfunction

function! FsbCheckCurrentBlock(block,silent)

  " Check the lenght of the current block.
  " block = number of the current block, or -1 if unknown

  let l:errorFlag=0

  let l:blockId = a:block==-1 ? "current block" : "block ".printf("%5s","#".a:block)

  let l:currentLine=line('.')
  let l:currentCol=col('.')

  let l:validLines=0 " counter
  call FsbTopOfBlock()

  while !FsbAtLastLine() " not end of file?

    let l:validLine=FsbValidLine()
    if l:validLine
      let l:errorFlag=strchars(getline(line('.')))>b:charsPerLineMinus1
      if l:errorFlag
        call FsbLineTooLongError()
        break
      endif
    endif

    let l:validLines+=l:validLine " update the counter

    call cursor(line('.')+1,1) " move to next line
    if FsbIsHeader(line('.')) " next block?
      break
    endif

  endwhile

  if !l:errorFlag " no line length error?

    " Check the length of the block

    call cursor(l:currentLine,l:currentCol)
    let l:errorFlag=(l:validLines>b:linesPerBlock)
    if l:errorFlag
      echohl Error
      echomsg "Error:" l:blockId s:indexLine "has" l:validLines "lines; the maximum is" b:linesPerBlock
    else
      if !a:silent
        echohl Normal
        echomsg l:blockId s:paddedIndexLine printf("%3d",l:validLines) "lines"
      endif
    endif

  endif

  echohl none
  return l:errorFlag

endfunction

function! FsbCheckBlocks(silent)

  " Check the lenght of all blocks.

  let l:errorFlag=0
  let l:blockNumber=0
  let l:currentLine=line('.')
  let l:currentCol=col('.')
  call cursor(1,1)
  while 1
    let l:titleLine=line('.')
    if FsbCheckCurrentBlock(l:blockNumber,a:silent)
      let l:errorFlag=1
      break
    endif
    call cursor(l:titleLine+1,1)
    if !search(s:blockHeaderExpression,'W') " not another block title?
      break
    endif
    let l:blockNumber=blockNumber+1
  endwhile
  if !l:errorFlag
    call cursor(l:currentLine,l:currentCol)
  endif
  return l:errorFlag

endfunction

function! FsbIndex()

  " Show and index of all blocks.

  let l:blockNumber=0
  let l:currentLine=line('.')
  let l:currentCol=col('.')

  let l:more=&more
  set more

  call cursor(1,1)
  while 1
    if FsbIsHeader(line('.'))
      echo l:blockNumber getline(line('.'))
      let l:blockNumber=blockNumber+1
    endif
    if line('.')==line('$')
      break
    else
      call cursor(line('.')+1,1) " move to next line
    endif
  endwhile

  call cursor(l:currentLine,l:currentCol)
  let &more=l:more
  return

endfunction

function! FsbBlockNumber()

  " Show the number of the current block.

  " A dry-run substitution of block headers does the trick:
  " it shows the number of occurrences in the desired range.

  " XXX FIXME -- This method doesn't work for the first block
  " (it shows 1 instead of 0) and it works only if the first
  " block starts with a block header.

  " XXX FIXME -- The result is one less when the cursor is on a
  " header line.

  "let l:currentLine=line('.')
  "let l:currentCol=col('.')

  execute ":1,?".s:blockHeaderExpression."?-1substitute@".s:blockHeaderExpression."@@ne"

endfunction

" ==============================================================
" Directives

" Directives make it possible to configure the converter and add
" ad hoc conversions to it.

" All directives must be at the start of a line. They consist of
" two or three parts, separated with one or more spaces: First,
" the Forth backslash, as a Forth line comment (but always at
" the start of the line); second, the directive keyword; third,
" an optional parameter.

" Examples:
"
" / Substitute a string in the whole file:
" / #vim %substitute/Hello/Goodbye/g
" / Substitute a string in the definition of the word 'MYWORD':
" / #vim /\<: MYWORD\>/,/\<;\>/%substitute/Hello/Goodbye/g
"
" Examples of directives not implemented yet:
"
" / #cpl 63
" / #tap
" / #abersoft

function! FsbVimDirective(directive)

  " Search for '#vim' or '#previm' directives, depending on the
  " argument, and execute their Vim commands.

  call cursor(1,1) " Go to the top of the file.

  " Empty dictionary to store the Vim commands; their line
  " number, padded with zeroes, will be used as key:
  let l:command={}

  " Search for all directives and store their line numbers and
  " Vim commands

  let l:directiveExpr='^\s\+\\\s\+'.a:directive.'\s\+'
  while search(l:directiveExpr,'Wc')
    let l:key=matchstr('00000000'.string(line('.')),'.\{8}$')
    let l:line=getline(line('.'))
    let l:command[l:key]=strpart(l:line,matchend(l:line,l:directiveExpr))
    call setline('.','') " blank the line
  endwhile

  if len(l:command)

    " Execute all Vim commands

    for l:key in sort(keys(l:command))
      call cursor(str2nr(l:key),1)
      " XXX TODO make 'silent' configurable
      " XXX with 'silent', wrong regexp in substitutions are hard to notice!
      execute 'silent! '.l:command[l:key]
    endfor

    if len(l:command)==1
      echo "One '".a:directive."' directive executed'"
    else
      echo len(l:command)." '".a:directive."' directives executed"
    endif

  endif

endfunction

function! FsbVimDirectives()

  " Search for all '#previm' and '#vim' directives and execute
  " their Vim commands.

  " The '#previm' and '#vim' directives make it possible to
  " execute any ex Vim command in the source.
  "
  " A typical simple usage is to convert UTF-8 characters to the
  " encoding or user defined graphics of an 8-bit platform.
  "
  " This function was adapted from Vimclair BASIC
  " (http://programandala.net/en.program.vimclair_basic.html).

  " Syntax:
  "
  " The directives must be at the start of a line. They consist
  " of three parts: the Forth backslash as an ordinary comment
  " (with optional spaces at the left), the '#previm' or '#vim'
  " directive and any Vim ex command:
  "
  "   \ #vim Any-Vim-Ex-Command

  call FsbVimDirective('#previm')
  call FsbVimDirective('#vim')

endfunction

function! FsbTraceDirective()

  " Search for the '#trace' directive and update the b:trace
  " flag.

  let b:trace=search('^\s\+\\\s\+#trace\s*$','wc')

  if b:trace

    " Directory to save the conversion steps into.
    let s:traceDir=s:sourceFileDir.'/.fsb_trace/'
    if !isdirectory(s:traceDir)
      " XXX TODO if exists("*mkdir")
      " XXX TODO catch possible errors
      call mkdir(s:traceDir,'',0700)
    endif

  endif

endfunction


" ==============================================================
" Converter

function! FsbSaveStep(description)

  " Save the current version of the file being converted, into
  " the s:traceDir directory, for debugging purposes.  The
  " directory must exist.

  if !b:trace
    return
  endif

  let l:number='00'.s:step

  " XXX INFORMER
  " echo 'Step' l:number ':' a:description

  let l:number=strpart(l:number,len(l:number)-2)
  silent execute 'write! ++bin ++bad=keep '.s:traceDir.s:sourceFilename.'.step_'.l:number.'_'.a:description
  let s:step=s:step+1

endfunction

function! Fsb2(filetype)

  " Save a copy of the Forth source code hold in the current
  " buffer to a new file, with the given filetype.

  " a:filetype = format and filename extension of the output
  " file:

  "     fb   = Forth block file
  "     fbs  = Forth block file with end of lines

  " ----------------------------------------------------------
  " Check the lengths of the blocks

  " XXX INFORMER
  " echo "About to check the blocks"
  if FsbCheckBlocks(1)
    return
  endif
  " XXX INFORMER
  " echo "Blocks checked"

  " ----------------------------------------------------------
  " Target file type

  let l:fb  = a:filetype=='fb'
  let l:fbs = a:filetype=='fbs'

  " ----------------------------------------------------------
  " Init the saving of steps

  " Counter for the saved step files
  let s:step=0

  " Filename of the source file, without path
  let s:sourceFilename=fnamemodify(expand('%'),':t')

  " Absolute directory of the source file
  let s:sourceFileDir=fnamemodify(expand('%'),':p:h')

  " ----------------------------------------------------------
  " Create the target file and start editing it

  " Create a copy of the current file with the filename
  " extension changed to .fb and open it for editing.

  " XXX TMP experimental It seems this fixes the problem caused
  " by '#vim' directives that convert UTF-8 or Latin1 chars to
  " characters of the target platform that are bad in the
  " current encoding.
  set encoding=latin1

  " XXX INFORMER
  " echo 'About to create the target file'

  silent! update " Write the current file if needed

  let t:standardFormat=b:standardFormat

  split " Split the window
  let s:outputFile=expand('%:r').'.'.a:filetype
  if bufloaded(s:outputFile)
    silent! execute 'bw! '.s:outputFile
  endif
  silent! execute 'write! '.s:outputFile
  silent! execute 'edit ++bin '.s:outputFile

  call FsbSetTheFormat(t:standardFormat)

  " XXX INFORMER
  " echo 'Editing the target file'

  " Don't add an end of line at the end of the file
  setlocal bin
  setlocal noendofline

  " ----------------------------------------------------------
  " Vim directives

  call FsbVimDirectives()
  call FsbTraceDirective()

  " ----------------------------------------------------------
  " Remove metacomments

  " Metacomments are backslash comments that have any space at
  " the left.
  "
  " This is done at the start in order to prevent line length
  " errors caused by multibyte chars in comments.
  "
  " The lines are not removed, but just emptied, in order to
  " keep the original line numbers in possible error messages
  " caused later by a too long line code.

  silent! %substitute@^\s\+\\\(\s.*\)\?$@@e

  call FsbSaveStep('metacomments_removed')

  " ----------------------------------------------------------
  " Check the length of lines

  " Remove trailing spaces:
  silent! %substitute@\s\+$@@e

  " Is there any line longer that b:charsPerLine-1 characters?
  "if search('^.\{63}.\+','w') " XXX OLD
  if search('^.\{'.b:charsPerLineMinus1.'}.\+','w')
    call FsbLineTooLongError()
    return
  endif

  " ----------------------------------------------------------
  " Remove the empty lines

  silent! %substitute@^\n@@e

  call FsbSaveStep('empty_lines_removed')

  " ----------------------------------------------------------
  " Add missing lines before misplaced block titles

  " Block titles are recognized because the Forth word '(' is
  " at the first column of the line. They are supposed to be
  " the first line of a new block.

  call cursor(1,1)

  while search(s:blockHeaderExpression,'Wc') " block title?

    let l:titleLine=line('.')
    if (l:titleLine-1)%b:linesPerBlock " misplaced block title?
      let l:nextTitleLine=b:linesPerBlock*((l:titleLine-1)/b:linesPerBlock+1)+1
      let s:missingLines=l:nextTitleLine-l:titleLine
      while s:missingLines
        call append(l:titleLine-1,'')
        let s:missingLines=s:missingLines-1
      endwhile
    endif
    if l:titleLine==line('$')
      break
    endif
    call cursor(l:titleLine+1,1)

  endwhile

  " XXX Vim's bug?
  " XXX FIXME this reports 1 more than the lines saved:
  " XXX INFORMER
  " echo "last line before saving the step:" line('$')
  " normal G
  " echo "it's" line('.')

  call FsbSaveStep('missing_lines_added_before_block_headers')

  " ----------------------------------------------------------
  " Add missing lines at the end of the last block

  " XXX Vim's bug?
  " XXX FIXME this reports 1 more than the lines saved:
  " XXX INFORMER
  " echo "last line after saving the step:" line('$')
  " normal G
  " echo "it's" line('.')

  if FsbIsHeader(line('$'))
    let s:missingLines=b:linesPerBlock-1
  else
    " XXX FIXME -- it seems this adds 15 lines at the end of the file
    " when the last block has 16 lines
    " and there's a blank line or metacomment at the end (!?):
    let s:missingLines=b:linesPerBlock-1-(line('$')-1)%b:linesPerBlock
    " XXX INFORMER
    " echo " missing lines:" s:missingLines
    " echo " lines per block:" b:linesPerBlock
    " XXX TMP -- temporary solution:
    let s:missingLines= s:missingLines>=(b:linesPerBlock-1) ? 0 : s:missingLines
  endif
  " XXX INFORMER
  " echo "missing lines:" s:missingLines
  while s:missingLines
    " XXX FIXME -- This seems a bug of Vim:
    " This creates one line less than expected:
    "call append(line('$'),'')
    " This creates the expected number of lines,
    " because one empty line is created first:
    call append(line('$'),' ')
    let s:missingLines=s:missingLines-1
    " XXX INFORMER
    " echo "line added at the end"
  endwhile

  call FsbSaveStep('missing_lines_added_at_the_end')

  " ----------------------------------------------------------
  " Add trailing spaces to all lines

if 1 " XXX original method

  " XXX FIXME This adds a new blank line at the end! Why?
  " But it works fine manually!

  " XXX 2015-03-24: it seems it works fine now (?!)

  silent! %substitute@$@\=repeat(' ',b:charsPerLine)@e

" XXX TMP -- debug tries:
"  silent! %substitute@\n@\=repeat('X',b:charsPerLine)."\r"@e

else " XXX alternative method

  " XXX FIXME -- This alternative method fails as well

  " XXX FIXME
  " The file is fine, but the last line reported is +1!
  " XXX INFORMER
   " echo "The last line is " line('$')
"  write /tmp/kk2.txt

  call cursor(1,1)
  while 1
    let l:line=getline(line('.'))
    call setline('.',l:line.repeat(" ",b:charsPerLine))
    " XXX INFORMER
    " echo "line" line('.') "blanked"

    " XXX FIXME -- The condition above should be:
    "
    "    if line('.')==line('$')
    "
    " But somehow (no clue yet) Vim adds one line to the line
    " count returned by `line('$')`. The test files saved during
    " the process are perfect, but `line('$')` returns the last
    " line number +1!

    " if line('.')==line('$')-1
    " XXX -- 2015-03-23: now it works (?!):
    if line('.')==line('$')
      break
    endif
    call cursor(line('.')+1,1)
  endwhile

endif " XXX TMP

  call FsbSaveStep('trailing_spaces_added')

  " ----------------------------------------------------------
  " Trim the lines to the required length

  if l:fbs
    " .fbs format
    " silent! %substitute@^\(.\{63}\).\+$@\1@e " XXX OLD
    execute 'silent! %substitute@^\(.\{'.b:charsPerLineMinus1.'}\).\+$@\1@e'
  else
    " .fb format
    " silent! %substitute@^\(.\{64}\).\+$@\1@e " XXX OLD
    execute 'silent! %substitute@^\(.\{'.b:charsPerLine.'}\).\+$@\1@e'
  endif

  call FsbSaveStep('lines_trimmed_to_the_final_length')

  if l:fb
    " .fb format
    " Remove all end of lines
    silent! %substitute@\n@@e
    call FsbSaveStep('ends_of_line_removed')
  endif

  " ----------------------------------------------------------
  " Save

  " Write the output file
  silent! write! ++bin ++enc=latin1 ++bad=keep

  " Wipe its buffer
  silent! bw!

  echo '"'.s:outputFile.'" created'


endfunction

function! Fsb2fb()

  " Save a copy of the Forth source code hold in the current
  " buffer to a new file, with the format of Forth blocks.  The
  " output file will have its extension changed to '.fb'.

  call Fsb2('fb')

endfunction

function! Fsb2fbs()

  " Save a copy of the Forth source code hold in the current
  " buffer to a new file, with the format of Forth blocks with
  " end of lines (as used by the lina Forth system).  The output
  " file will have its extension changed to '.fbs'.

  call Fsb2('fbs')

endfunction

" ==============================================================
" Init

let s:true=-1
let s:false=0

" Listings don't pause when the screen is filled:
set nomore

" XXX OLD first version
"let s:blockHeaderExpression='^(\s.\+)\s*$'
" XXX NEW also accepts the word `.(`, and something at the end:
" let s:blockHeaderExpression='^\.\?(\s.\+)\(\s\+.*\)\?$'
" XXX NEW also accepts empty headers:
" let s:blockHeaderExpression='^\.\?(\s.*)\(\s\+.*\)\?$'
" XXX NEW also accepts backslashes instead of parens:
" let s:blockHeaderExpression='^\(\(\.\?(\s\+.*)\)\|\(^\\\s.*\\\)\)\(\s\+.*\)\?$'
" XXX NEW changed '?' to '=', else the pattern can not be used backwards with the '?' command or range.
let s:blockHeaderExpression='^\(\(\.\=(\s\+.*)\)\|\(\\\s.*\\\)\)\(\s\+.*\)\=$'

" Set the standard format (16x64):
call FsbSetTheFormat(s:true)

" Activate the style (must be done *after* setting the format):
let b:fsbStyle = 0
call FsbToggleTheStyle()

" ==============================================================
" Key mappings

" Convert to .fb format
nmap <silent> <buffer> .fb  :call Fsb2fb()<Return>
" Convert to .fbs format
nmap <silent> <buffer> .fbs :call Fsb2fbs()<Return>

" Toggle the highlighting style
nmap <silent> <buffer> ,s :call FsbToggleTheStyle()<Return>
" Toggle the format
nmap <silent> <buffer> ,f :call FsbToggleTheFormat()<Return>

" Movement
nmap <silent> <buffer> ,g :<C-U>call FsbGoToBlock(v:count)<Return>
nmap <silent> <buffer> ,G :<C-U>call FsbGoToBlockFromEnd(v:count)<Return>
nmap <silent> <buffer> ,b :call FsbBottomOfBlock()<Return>
nmap <silent> <buffer> ,t :call FsbTopOfBlock()<Return>
nmap <silent> <buffer> ,p :call FsbPreviousBlock()<Return>
nmap <silent> <buffer> ,n :call FsbNextBlock()<Return>
nmap <silent> <buffer> ,<Up> :call FsbMaxValidLinesUp()<Return>
nmap <silent> <buffer> ,<Down> :call FsbMaxValidLinesDown()<Return>

" Checks
nmap <silent> <buffer> ,c :call FsbCheckCurrentBlock(-1,0)<Return>
nmap <silent> <buffer> ,C :call FsbCheckBlocks(0)<Return>
nmap <silent> <buffer> ,L :call FsbCheckLines(0)<Return>
nmap <silent> <buffer> ,i :call FsbIndex()<Return>

" Number of the current block
nmap <silent> <buffer> ,# :call FsbBlockNumber()<Return>

" ==============================================================
" Change log

" 2015-02-12: Draft of the style commands.
"
" 2015-02-13: First version of the converters.
"
" 2015-02-14: New: Missing lines are at the end of the file and
" before every misplaced block title. Also the 'fbs' format is
" supported (Forth blocks with end of lines). Change: Renamed
" from 'fsb2fb.vim' to 'fsb.vim'. New: mappings.
"
" 2015-03-10: Change: maps.
"
" 2015-03-10: New: 'loaded_fsb' check.
"
" 2015-03-11:
"
" Fix: The program always returned '1' exit code, what made
" 'make' fail when used in a Makefile.  In order to prevent an
" error code to be returned, two fixes are done: 1) The 'e' flag
" is added to every 'substitute'.  2) 'bufloaded()' is used
" instead of a 'try' structure.
"
" Fix: The 'c' flag (accept a match at the current cursor
" position) was needed in the 'search()' function that searches
" for block titles. Otherwise empty blocks were not recognized.
"
" Fix: The 'set binary' was needed in order to make 'set
" noendofline' effective.
"
" 2015-03-14:
"
" New: Metacomments: backslash comment lines that start at the
" start of the line. They will not be included in the target.
" Now the 16-line movement ignores empty lines and metacomments.
"
" New: 'FsbCheckCurrentBlock()' checks the lenght of the current
" block and shows a message. It's mapped to a function key.
"
" New: 'FsbCheckBlocks()' checks the lenght of all blocks and
" It's called before the conversion, and also mapped to a
" function key.
"
" 2015-03-15:
"
" Change: Movement and check mappings are changed to nmemonic
" shortcuts with comma prefix.
"
" New: First support for the '#vim' directive, adapted from
" Vimclair BASIC
" (http://programandala.net/en.program.vimclair_basic.html).
"
" Change: Clearer message in'FsbCheckCurrentBlock()' when the
" lenght is valid.
"
" New: More and improved movement functions and mappings.
"
" 2015-03-15:
"
" Version A-01.
"
" Change: Now line comments at the start of the line are kept,
" while those with spaces before the backslash are considered
" metacomments and removed.  Formerly it was done the opposite
" way, but it seems more intuitive and practical this way.
"
" 2015-03-19:
"
" Fix: The algorythm of 'FsbCheckCurrentBlock()' was wrong: it
" failed at the last block because it did a comparation between
" limit lines, moving 16 lines down twice: ignoring or not the
" invalid lines.  It has been rewritten with a loop and an
" actual count of valid lines, till the next block or the end of
" the file.
"
" Change: One-letter mappings for checking.
"
" Version A-02.
"
" 2015-03-20:
"
" Change: New improved version of 'FsbVimDirectives()',  adapted
" from Vimclair BASIC
" (http://programandala.net/en.program.vimclair_basic.html):
" support for '#previm'; the directives are extracted before
" being executed.
"
" 2015-03-21:
"
" Fix: Now 'FsbTopOfBlock()' goes to the top of the file when no
" header is found. Formerly checking just the first block gave a
" wrong result, depending on the current line.
"
" Fix: The calculation of missing lines at the end of the last
" block was wrong, because the first line of a Vim file is
" number 1, not 0.
"
" Fix: It seems there's a Vim bug: `line('$')` returns +1 than
" expected, while the file (saved during the process, for
" debugging) has the expected lenght.  This added one line at
" the end of the file when the last block is 16 lines long. The
" solution was to substitute the `substitute` command with a
" loop using a modified condition. More details in the code.
"
" Version A-03.
"
" 2015-03-22:
"
" First changes to implement the support for alternative 32x32
" blocks.
"
" 2015-03-23:
"
" Fix: The calculation of missing lines at the end of the file
" failed when there was no block header line, or when it was the
" only line of the file.
"
" Version A-04.
"
" 2015-03-24:
"
" New: The steps of the conversion are saved, for debugging
" purposes.
"
" New: The alternative 32x32 format is finished. A function
" toggles the format.
"
" 2015-03-27:
"
" New: The old functions to move 16 valid lines up or down are
" restored, improved, renamed and associated to new key maps:
" `FsbMaxValidLinesUp()` and `FsbMaxValidLinesDown()`.
"
" 2015-03-30:
"
" New: Also the word `.(` is accepted as block header.
"
" 2015-04-19:
"
" Improved: After checking all blocks, the cursor position is
" restored if there was no error.
"
" 2015-05-13:
"
" Fix: Now block headers are recognized also when they are
" empty.
"
" Version A-05.
"
" 2015-05-30:
"
" Improvement: The new "#trace" directive activates the saving
" of steps. The trace directory is renamed to <.fsb_trace>.
"
" Version A-06.
"
" 2015-09-03:
"
" Added `set nomore`. Improved `s:blockHeaderExpression` to
" support two backslashes (first and last char on the header
" line), in order to make it possible to write words with
" closing parens in the block headers, e.g.  `(emit)`.
"
" Version A-07.
"
" 2015-09-19:
"
" Added `FsbBlockNumber()` to show the number of the current
" block. Added `FsbGoToBlock()` and `FsbGoToBlockFromEnd()` to
" go to a block specified by a prefix count.
"
" Version A-08.
"
" 2015-09-24:
"
" Improved the block check function: Now also the length of
" lines is checked.  Formerly that was done only during the
" conversion to FB or FBS.
"
" Version A-09.
"
" 2015-09-25:
"
" Fixed a recent typo that made `FsbBlockNumber()` fail.
"
" 2015-10-17:
"
" Little simplification of the expression hold by
" `s:blockHeaderExpression`, without practical effect.
"
" 2015-11-25:
"
" Fixed `FsbCheckCurrentBlock()`: now `strchars()` is used
" instead of `strlen()`, else lines with UTF-8 multibyte chars
" (to be translated by the correspondent directives) could cause
" a "line too long" error.
"
" Version A-10.
"
" 2015-11-27:
"
" Modified the directives' syntax: They must be in backslash
" metacomments.  So far they were recognized also in ordinary
" backslash comments, but it was no advantage, only caused
" problems: the directive lines were considered source lines
" when checking the blocks.
"
" Updated and improved the <README.adoc>.
"
" Published on GitHub.
"
" Version A-11.
"
" 2016-03-24:
"
" Fix: `l:errorFlag` was not initialized in
" `FsbCheckCurrentBlock()`, what caused error messages when
" checking an empty fake block 0 (a file header with
" metacomments).
"
" Removed trailing spaces from the source.
"
" Updated the version number after Semantic Versioning
" (http://semver.org):
"
" Version 0.11.1+20160324.
"
" 2017-01-08:
"
" Add function `FsbCheckLines()`.
"
" Version 0.12.0+20170108.
"
" 2017-01-09:
"
" Restore recursion check.
"
" Version 0.12.0+20170109.
"
" 2017-03-01:
"
" Add function `FsbIndex()`.
"
" Version 0.13.0+20170301.
"
" 2018-03-25:
"
" Improve the format of the list of checked blocks: Display the
" index lines and tabularize the list.

" vim: tw=64:ts=2:sts=2:sw=2:et
