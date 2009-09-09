" File: objc_cocoa_mappings.vim
" Author: Michael Sanders (msanders42 [at] gmail [dot] com)
" Description: Sets up mappings for cocoa.vim.
" Last Updated: September 08, 2009

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
nn <buffer> <silent> <d-r> :w<bar>cal<SID>BuildAnd('launch')<cr>
nn <buffer> <silent> <d-b> :w<bar>cal<SID>XcodeRun('build')<cr>
nn <buffer> <silent> <d-K> :w<bar>cal<SID>XcodeRun('clean')<cr>
" TODO: Add this
" nn <buffer> <silent> <d-y> :w<bar>cal<SID>BuildAnd('debug')<cr>
nn <buffer> <silent> <d-m-up> :cal<SID>AlternateFile()<cr>
nn <buffer> <silent> <d-0> :call system('open -a Xcode '.b:cocoa_proj)<cr>
nn <buffer> <silent> <d-2> :<c-u>ListMethods<cr>
nm <buffer> <silent> <d-cr> <d-r>
ino <buffer> <silent> <f5> <c-x><c-o>

if exists('*s:AlternateFile') | finish | endif

" Switch from header file to implementation file (and vice versa).
fun s:AlternateFile()
	let path = expand('%:p:r').'.'
	if expand('%:e') == 'h'
		if filereadable(path.'m')
			exe 'e'.fnameescape(path.'m')
			return
		elseif filereadable(path.'c')
			exe 'e'.fnameescape(path.'c')
			return
		endif
	else
		if filereadable(path.'h')
			exe 'e'.fnameescape(path.'h')
			return
		endif
	endif
	echoh ErrorMsg | echo 'Alternate file not readable.' | echoh None
endf

" Opens Xcode and runs Applescript commands, splitting them onto newlines
" if needed.
fun s:XcodeRun(command)
	call system("open -a Xcode ".b:cocoa_proj." && osascript -e 'tell app "
				\ .'"Xcode" to '.a:command."' &")
endf

fun s:BuildAnd(command)
	call system("open -a Xcode ".b:cocoa_proj." && osascript -e 'tell app "
				\ ."\"Xcode\"' -e '"
				\ .'set target_ to project of active project document '
				\ ."' -e '"
				\ .'if (build target_) starts with "Build succeeded" then '
				\ .a:command.' target_'
				\ ."' -e 'end tell'")
endf
