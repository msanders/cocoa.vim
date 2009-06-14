classes=`grep -m 1 ^$1 ~/.vim/lib/cocoa_indexes/classes.txt`
if [ -z "$classes" ]; then exit; fi
zgrep "^\($classes\)" ~/.vim/lib/cocoa_indexes/methods.txt.gz | sed 's/^[^ ]* //'
