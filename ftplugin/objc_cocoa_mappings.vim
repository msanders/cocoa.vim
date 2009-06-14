" File: objc_cocoa_mappings.vim
" Author: Michael Sanders (msanders42 [at] gmail [dot] com)
" Description: Sets up mappings for cocoa.vim.
" Last Updated: June 11, 2009

if exists('b:cocoa_proj') || &cp || version < 700
	finish
endif
let b:cocoa_proj = fnameescape(globpath(expand('<afile>:p:h'), '*.xcodeproj'))

com! -buffer ListMethods call objc#method_list#Activate(1)
com! -buffer -nargs=? -complete=customlist,objc#method_builder#Completion BuildMethods call objc#method_builder#Build('<args>')
com! -buffer -nargs=? -complete=custom,objc#man#Completion CocoaDoc call objc#man#ShowDoc('<args>')
com! -buffer -nargs=? Alternate call <SID>AlternateFile()

let objc_man_key = exists('objc_man_key') ? objc_man_key : 'K'
exe 'nn <buffer> <silent> '.objc_man_key.' :<c-u>call objc#man#ShowDoc()<cr>'

nn <buffer> <silent> <leader>A :cal<SID>AlternateFile()<cr>

" Mimic some of Xcode's mappings.
nn <buffer> <silent> <d-r> :cal<SID>XcodeRun('build', 'launch')<cr>
nn <buffer> <silent> <d-b> :cal<SID>XcodeRun('build')<cr>
nn <buffer> <silent> <d-K> :cal<SID>XcodeRun('clean')<cr>
nn <buffer> <silent> <d-y> :cal<SID>XcodeRun('build', 'debug')<cr>
nn <buffer> <silent> <d-m-up> :cal<SID>AlternateFile()<cr>
nn <buffer> <silent> <d-0> :call system('open -a Xcode '.b:cocoa_proj)<cr>
nn <buffer> <silent> <d-2> :<c-u>ListMethods<cr>
nm <buffer> <silent> <d-cr> <d-r>
ino <buffer> <silent> <f5> <c-x><c-o>

if exists('*s:AlternateFile') | finish | endif

" Switch from header file to implementation file (and vice versa).
fun s:AlternateFile()
	let path = expand('%:p:r').'.'.(expand('%:e') == 'm' ? 'h' : 'm')
	if filereadable(path)
		exe 'e'.fnameescape(path)
	else
		echoh ErrorMsg | echo 'Alternate file not readable.' | echoh None
	endif
endf

" Opens Xcode and runs Applescript commands, splitting them onto newlines
" if needed.
fun s:XcodeRun(com, ...)
	let com = !a:0 ? ' to '.a:com :
	               \ "' -e '".join([a:com] + a:000, "' -e '")."' -e 'end tell"
	call system("open -a Xcode ".b:cocoa_proj." && osascript -e 'tell app \"Xcode\"".com."' &")
endf
