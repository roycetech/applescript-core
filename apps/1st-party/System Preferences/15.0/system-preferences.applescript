global std, retry, usr

(*
	@Deployment:
		make compile-lib SOURCE="apps/1st-party/System Preferences/15.0/system-preferences"
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "scripteditor-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Manual: Quit App (Running/Not Running)
		Manual: Reveal Security & Privacy > Privacy		
		Manual: Unlock Security & Privacy > Privacy (Unlock button must be visible already) 
	")
	
	set spotLib to std's import("spot")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	-- spot's setAutoIncrement(true)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	if caseIndex is 1 then
		sut's quitApp()
		
	else if caseIndex is 2 then
		sut's quitApp()
		sut's revealSecurityAccessibilityPrivacy()
		
	else if caseIndex is 3 then
		sut's unlockSecurityAccessibilityPrivacy()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck

on new()
	script SystemPreferences
		(* 
			Invoke this script before doing anything with System Preferences so that you 
			have a clean slate as you start. 
		*)
		
		on revealSecurityAccessibilityPrivacy()
			tell application "System Preferences"
				activate
				reveal anchor "Privacy_Accessibility" of pane id "com.apple.preference.security"
			end tell
			
			script PanelWaiter
				tell application "System Events" to tell process "System Preferences"
					if (value of radio button "Privacy" of tab group 1 of window "Security & Privacy") is 0 then return missing value
				end tell
				true
			end script
			exec of retry on result for 50 by 0.1
		end revealSecurityAccessibilityPrivacy
		
		on unlockSecurityAccessibilityPrivacy()
			usr's cueForTouchId()
			script WindowWaiter
				tell application "System Events" to tell process "System Preferences"
					click button "Click the lock to make changes." of window "Security & Privacy"
				end tell
				true
			end script
			exec of retry on result for 10 by 0.5
			
			script UnlockWaiter
				tell application "System Events" to tell application process "System Preferences"
					try
						button "Click the lock to prevent further changes." of window "Security & Privacy" exists
					end try
				end tell
				true
			end script
			exec of retry on result for 10
		end unlockSecurityAccessibilityPrivacy
		
		
		on quitApp()
			if running of application "System Preferences" is false then return
			
			try
				tell application "System Preferences" to quit
			on error
				do shell script "killall 'System Preferences'"
			end try
			
			repeat while running of application "System Preferences" is true
				delay 0.1
			end repeat
		end quitApp
	end script
	std's applyMappedOverride(result)
end new




-- Private Codes below =======================================================
(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("system-preferences")
	set retry to std's import("retry")'s new()
	set usr to std's import("user")'s new()
end init

