# Note: Do not use the scripts from the <project>/scripts/ sub directory because
# it doesn't work. Just use the osacompile directly.

install:
	../setup-sublime-cli.applescript
	osacompile -o ~/Library/Script\ Libraries/sublime-text.scpt sublime-text.applescript
	osacompile -o ~/Library/Script\ Libraries/dec-system-events-with-sublime-text.scpt dec-system-events-with-sublime-text.applescript
	plutil \
		-replace 'SystemEventsInstance' \
		-string 'dec-system-events-with-sublime-text' \
		~/applescript-core/config-lib-factory.plist

# To Test
uninstall:
	plutil -remove 'SystemEventsInstance' ~/applescript-core/config-lib-factory.plist
	rm ~/Library/Script\ Libraries/sublime-text.scpt
	rm ~/Library/Script\ Libraries/dec-system-events-with-sublime-text.scpt
