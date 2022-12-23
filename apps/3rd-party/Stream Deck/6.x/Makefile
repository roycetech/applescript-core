# Note: Do not use the scripts from the <project>/scripts/ sub directory because
# it doesn't work. Just use the osacompile directly.

install:
	../setup-sublime-cli.applescript
	osacompile -o ~/Library/Script\ Libraries/sublime-text.scpt sublime-text.applescript
	osacompile -o ~/Library/Script\ Libraries/dec-syseve-with-sublimetext.scpt dec-syseve-with-sublimetext.applescript
	plutil \
		-replace 'SysEveInstance' \
		-string 'dec-syseve-with-sublimetext' \
		~/applescript-core/config-lib-factory.plist

# To Test
uninstall:
	plutil -remove 'SysEveInstance' ~/applescript-core/config-lib-factory.plist
	rm ~/Library/Script\ Libraries/sublime-text.scpt
	rm ~/Library/Script\ Libraries/dec-syseve-with-sublimetext.scpt
