" File:         objc#man.vim (part of the cocoa.vim plugin)
" Author:       Michael Sanders (msanders42 [at] gmail [dot] com)
" Description:  Allows you to look up Cocoa API docs in Vim.
" Last Updated: June 12, 2009

" Return all matches in for ":CocoaDoc <tab>" sorted by length.
fun objc#man#Completion(ArgLead, CmdLine, CursorPos)
	return system('grep -ho "^'.a:ArgLead.'\w*" ~/.vim/lib/cocoa_indexes/*.txt'.
	            \ "| perl -e 'print sort {length $a <=> length $b} <>'")
endf

let s:docsets =  []
for path in ['/Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset',
           \ '/Developer/Platforms/iPhoneOS.platform/Developer/Documentation/DocSets/com.apple.adc.documentation.AppleiPhone2_0.iPhoneLibrary.docset']
	if isdirectory(path)
		call add(s:docsets, path)
	endif
endfor

let s:docset_cmd = '/Developer/usr/bin/docsetutil search -skip-text -query '

fun s:OpenFile(file)
	if a:file =~ '/usr/.\{-}/man/'
		exe ':!'.substitute(&kp, '^man -s', 'man', '').' '.a:file
	else
		" /usr/bin/open strips the #fragments in file:// URLs, which we need,
		" so I'm using applescript instead.
		call system('osascript -e ''open location "file://'.a:file.'"'' &')
	endif
endf

fun objc#man#ShowDoc(...)
	let word = a:0 ? a:1 : expand('<cword>')
	if word == ''
		if !a:0 " Mimic K if using it as such
			echoh ErrorMsg
			echo 'E349: No identifier under cursor'
			echoh None
		endif
		return
	endif

	let references = {}

	" First check Cocoa docs for word using docsetutil
	for docset in s:docsets
		let response = split(system(s:docset_cmd.word.' '.docset), "\n")
		let docset .= '/Contents/Resources/Documents/' " Actual path of files
		for line in response
			" Format string is: " Language/type/class/word path"
			let path = matchstr(line, '\S*$')
			if path[0] != '/' | let path = docset.path | endif
			if has_key(references, path) | continue | endif " Ignore duplicate entries

			let [lang, type, class] = split(matchstr(line, '^ \zs*\S*'), '/')[:2]
			" If no class if given use type instead
			if class == '-' | let class = type | endif
			let references[path] = {'lang': lang, 'class': class}
		endfor
	endfor

	" Then try man
	let man = system('man -S2:3 -aW '.word)
	if man !~ '^No manual entry'
		for path in split(man, "\n")
			if !has_key(references, path)
				let references[path] = {'lang': 'C', 'class': 'man'}
			endif
		endfor
	endif

	if len(references) == 1
		return s:OpenFile(keys(references)[0])
	elseif !empty(references)
		return s:ChooseFrom(references)
	else
		echoh WarningMsg
		echo "Can't find documentation for ".word
		echoh None
	endif
endf

fun s:ChooseFrom(references)
 	let type_abbr = {'cl' : 'Class', 'intf' : 'Protocol', 'cat' : 'Category',
	               \ 'intfm' : 'Method', 'instm' : 'Method', 'econst' : 'Enum',
	               \ 'tdef' : 'Typedef', 'macro' : 'Macro', 'data' : 'Data',
	               \ 'func' : 'Function'}
	let inputlist = []
	" Don't display "Objective-C" if all items are objc
	let show_lang = !AllKeysEqual(values(a:references), 'lang', 'Objective-C')
	let i = 1
	for ref in values(a:references)
		let class = ref.class
		if has_key(type_abbr, class) | let class = type_abbr[class] | endif
		call add(inputlist, i.'. '.(show_lang ? ref['lang'].' ' : '').class)
		let i += 1
	endfor
	let num = inputlist(inputlist)
	return num ? s:OpenFile(keys(a:references)[num - 1]) : -1
endf

fun AllKeysEqual(list, key, item)
	for item in a:list
		if item[a:key] != a:item
			return 0
		endif
	endfor
	return 1
endf
" vim:noet:sw=4:ts=4:ft=vim
