(*

*)
use loggerFactory : script "logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set sut to new()
	logger's infof("A media is focused: {}", sut's hasFocused())

	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	script PhotosInstance
		on hasFocused()
			if running of application "Photos" is false then return false

			tell application "System Events" to tell process "Photos"
				try
					return exists (button "Edit" of group 1 of group 1 of toolbar 1 of window 1)
				end try
			end tell
			false
		end hasFocused
	end script
end new
