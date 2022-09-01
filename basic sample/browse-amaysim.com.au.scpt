# this is a comment

tell application "Google Chrome" to activate # open Google Chrome

tell application "System Events"
	# pressing keys -> keycode can be found at https://eastmanreference.com/complete-list-of-applescript-key-codes
	key code 17 using command down # press cmd + T (New Tab)
	delay 0.5 # wait half a second
	key code 37 using command down # press cmd + L (Open Location)
	delay 1 # wait 1 second
	
	keystroke "amaysim.com.au" # input site
	delay 1
	key code 36 # press enter
end tell