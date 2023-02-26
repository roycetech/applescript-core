global std, retry, kb, process

(*
	Currently, the app is problematic when launched from a script. App window closes right after performing touch ID. 
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	logger's start()
	
	set sut to new()
	sut's waitToUnlock()
	
	if result is true then
		logger's infof("Password: {}", sut's getPassword("Dodoot."))
	else
		logger's info("Did not unlock")
	end if
	
	logger's finish()
end spotCheck


on new()
	script LastPassInstance
		on getPassword(credKey)
			script GetPasswordScript
				_clearSearch()
				_search(credKey)
				
				set thePassword to _getPassword()
				
				if thePassword is not missing value and thePassword is not "" then return thePassword
			end script
			exec of retry on result for 5
		end getPassword
		
		
		(*  *)
		on waitToUnlock()
			if running of application "LastPass" is true then
				tell application "System Events" to tell process "LastPass"
					if (count of windows) is 0 then
						set lastPassProcess to std's import("process")'s new("LastPass")
						lastPassProcess's terminate()
					end if
				end tell
			end if
			
			script UnlockOrPasswordOrTouch
				if running of application "LastPass" is false then
					activate application "LastPass"
					delay 1
					activate application "LastPass" -- issue where window is 
					-- closed right after touch ID. Still a problem unfortunately.
				end if
				
				
				tell application "System Events" to tell process "LastPass" -- to update
					if exists (button "LastPass Enterprise" of splitter group 1 of window 1) then return "unlocked" -- TODO: Would fail for personal version.
					-- if exists (button "ADD ITEM" of group 1 of splitter group 1 of group 1 of splitter group 1 of window 1) then return "unlocked"
					
					if exists (button "UNLOCK" of window "App Lock Window") then return "locked"
				end tell
				
				tell application "System Events" to tell process "coreautha"
					if exists (button "Use Password..." of window 1) then return "touch"
				end tell
			end script
			
			logger's debug("Waiting for unlock or password for 60s...")
			set unlockState to exec of retry on UnlockOrPasswordOrTouch by 0.5 for 120
			logger's debugf("unlockState: {}", unlockState)
			if unlockState is missing value then return false
			
			script Unlock
				tell application "System Events" to tell process "LastPass"
					if exists (button "ADD ITEM" of group 1 of splitter group 1 of group 1 of splitter group 1 of window 1) then
						do shell script "afplay ~/applescript/sounds/Beer\\ Opening.aiff > /dev/null 2>&1 &"
						return "unlocked"
					end if
				end tell
				
				tell application "System Events" to tell process "coreautha"
					if (count of windows) is not 0 then set frontmost to true
				end tell
			end script
			
			if unlockState is "locked" then
				do shell script "afplay /System/Library/Sounds/Purr.aiff" -- should be after the click but it takes a bit of time.
				logger's debug("Clicking unlock...")
				tell application "System Events" to tell process "LastPass"
					click button "UNLOCK" of window "App Lock Window"
				end tell
				
				set unlockState to exec of retry on Unlock by 0.5 for 120
				return unlockState is "unlocked"
			end if
			
			if unlockState is "unlocked" then return true
			
			tell application "System Events" to tell process "coreautha" to set frontmost to true
			logger's debug("Waiting for unlock...")
			do shell script "afplay /System/Library/Sounds/Purr.aiff"
			
			return (exec of retry on Unlock by 0.5 for 200) is "unlocked"
		end waitToUnlock
		
		
		-- Private Codes below =======================================================
		
		(* Search for a credential. Make sure that your key results in only one match *)
		on _search(distinctiveSearchKey)
			if running of application "LastPass" is false then return
			
			tell application "System Events" to tell process "LastPass"
				if (count of windows) is 0 then return

				set searchField to text area 1 of scroll area 1 of splitter group 1 of group 1 of splitter group 1 of window 1
				set value of searchField to distinctiveSearchKey
				delay 1
				
				select row 2 of outline 1 of scroll area 2 of splitter group 1 of group 1 of splitter group 1 of window 1
				delay 1
			end tell
		end _search
		
		
		(* Optionally clear if there's text present *)
		on _clearSearch()
			if running of application "LastPass" is false then return
			
			tell application "System Events" to tell process "LastPass"
				if (count of windows) is 0 then return

				set searchField to text area 1 of scroll area 1 of splitter group 1 of group 1 of splitter group 1 of window 1
				
				if value of searchField is not "" then set value of searchField to ""
			end tell
		end _clearSearch
		
		
		on _getPassword()
			activate application "LastPass"
			tell application "System Events" to tell process "LastPass"
				set originalClipboard to the clipboard
				set the clipboard to ""
				repeat until (the clipboard) is ""
					delay 0.1
				end repeat
				
				try
					click menu item "Copy Password" of menu 1 of menu bar item "Vault" of menu bar 1
				end try
				
				set thePassword to ""
				repeat until thePassword is not ""
					delay 0.1
					set thePassword to the clipboard
				end repeat
				set the clipboard to originalClipboard
				
				-- Re-focus previous app.
				kb's pressCommandShiftKey(tab)
				kb's pressKey("enter")
				
			end tell
			thePassword
		end _getPassword
	end script
end new

(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("last-pass")
	set retry to std's import("retry")'s new()
	set kb to std's import("keyboard")'s new()
	set process to std's import("process")
end init
