# Note: Do not use the scripts from the <project>/scripts/ sub directory because
# it doesn't work. Just use the osacompile directly.

install:
	osacompile -o ~/Library/Script\ Libraries/stream-deck.scpt stream-deck.applescript
	osacompile -o ~/Library/Script\ Libraries/dec-spot-stream-deck.scpt dec-spot-stream-deck.applescript
	plutil \
		-replace 'SpotTestInstance' \
		-string 'dec-spot-stream-deck' \
		~/applescript-core/config-lib-factory.plist

# To Test
uninstall:
	plutil -remove 'SpotTestInstance' ~/applescript-core/config-lib-factory.plist
	rm ~/Library/Script\ Libraries/stream-deck.scpt
	rm ~/Library/Script\ Libraries/dec-spot-stream-deck.scpt
