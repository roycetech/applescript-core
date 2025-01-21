(*
	Library wrapper for the System Settings app. This was cloned from the original System Preferences app of macOS Monterey.  
	Some handlers have more additional requirements than others.  See handler's documentation for more 
	info.

	@Version:
		macOS Ventura 13.x and above.

	@Project:
		applescript-core
 
	@Build:
		make build-lib SOURCE="apps/1st-party/System Settings/15.0/system-settings"
		 
	@References:
		https://derflounder.wordpress.com/2022/10/25/opening-macos-venturas-system-settings-to-desired-locations-via-the-command-line/
*)

use scripting additions

use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"
use retryLib : script "core/retry"
use usrLib : script "core/user"

use decoratorLib : script "core/decorator"

property logger : missing value
property retry : missing value
property usr : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Quit App (Running/Not Running)
		Manual: Reveal Security & Privacy > Privacy
		Manual: Unlock Security & Privacy > Privacy (Unlock button must be visible already) 
		Manual: Reveal Voice Control
		Manual: Toggle Voice Control
		
		Manual: Click Commands...
		Manual: Enable 'Turn off Voice Control'
		Manual: Filter Commands and Enable
		Manual: Filter Commands and Disable
		Manual: Click Vocabulary
		
		Manual: revealKeyboardDictation
		Manual: Reveal Passwords (decorator)
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	-- spot's setAutoIncrement(true)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	
	sut's printPaneIds()
	logger's infof("Left pane UI detected? {}", sut's getLeftPaneUI() is not missing value)
	logger's infof("Right pane UI detected? {}", sut's getRightPaneUI() is not missing value)
	
	if caseIndex is 2 then
		sut's quitApp()
		
	else if caseIndex is 2 then
		sut's quitApp()
		sut's revealPrivacyAndSecurity_Accessibility()
		logger's infof("Handler result: {}", result)
		
	else if caseIndex is 3 then
		sut's unlockSecurityAccessibilityPrivacy()
		
	else if caseIndex is 4 then
		sut's quitApp()
		sut's revealAccessibilityVoiceControl()
		
	else if caseIndex is 5 then
		sut's revealAccessibilityVoiceControl()
		logger's infof("Toggle Voice Control: {}", sut's toggleVoiceControl())
		
	else if caseIndex is 6 then
		logger's infof("Click Commands...: {}", sut's clickAccessibilityCommands())
		
	else if caseIndex is 7 then
		-- sut's revealAccessibilityDictation()
		logger's infof("Turn On: 'Turn Off Voice Control': {}", sut's enableTurnOffVoiceControl())
		
	else if caseIndex is 8 then
		sut's quitApp()
		if sut's revealAccessibilityDictation() is false then error "Could not reveal Accessibility Dictation"
		sut's clickAccessibilityCommands()
		logger's infof("Manual: Filter and Enable: '<phrase>': {}", sut's filterCommandsAndEnable("<phrase>", 2))
		
	else if caseIndex is 9 then
		sut's quitApp()
		sut's revealAccessibilityDictation()
		sut's clickAccessibilityCommands()
		logger's infof("Manual: Filter and Disable: '<phrase>': {}", sut's filterCommandsAndDisable("<phrase>", 2))
		
	else if caseIndex is 10 then
		sut's quitApp()
		sut's revealAccessibilityDictation()
		sut's clickVocabulary()
		
	else if caseIndex is 11 then
		
	else if caseIndex is 12 then
		sut's revealKeyboardDictation()
		
	else if caseIndex is 13 then
		sut's revealPasswords()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's inject(me)
	set retry to retryLib's new()
	set usr to usrLib's new()
	
	script SystemSettingsInstance
		(* Strangely, sometimes it only prints the pane of the General pane. *)
		on printPaneIds()
			tell application "System Settings"
				set panesList to id of panes
				repeat with nextId in panesList
					log nextId
				end repeat
			end tell
		end printPaneIds
		
		
		(* To move in its own decorator when more functions are needed. *)
		on revealKeyboard()
			tell application "System Settings"
				set current pane to pane id "com.apple.Keyboard-Settings.extension"
			end tell
		end revealKeyboard
		
		
		on revealPrivacyAndSecurity_Accessibility()
			tell application "System Settings"
				activate
				delay 0.2 -- Fails without this delay.
				set current pane to pane id "com.apple.settings.PrivacySecurity.extension"
			end tell
			
			script PanelWaiter
				tell application "System Events" to tell process "System Settings"
					if (value of radio button "Privacy" of tab group 1 of window "Security & Privacy") is 0 then return missing value
					
				end tell
				true
			end script
			exec of retry on result for 50 by 0.1
		end revealPrivacyAndSecurity_Accessibility
		
		(* 
			Invoke this script before doing anything with System Preferences so that you 
			have a clean slate as you start. 
		*)
		on quitApp()
			if running of application "System Settings" is false then return
			
			try
				tell application "System Settings" to quit
			on error
				do shell script "killall 'System Settings'"
			end try
			
			repeat while running of application "System Settings" is true
				delay 0.1
			end repeat
		end quitApp
		
		
		(* UI Structure changes from list to group for unknown reasons. We want to anticipate that so that we only have to make changes to fewer places.*)
		on getLeftPaneUI()
			if running of application "System Settings" is false then return missing value
			
			tell application "System Events" to tell process "System Settings"
				try
					return group 1 of splitter group 1 of group 1 of front window
				on error
					try
						return list 1 of splitter group 1 of list 1 of front window
					on error the errorMessage number the errorNumber
						logger's warn(errorMessage)
					end try
				end try
			end tell
			
			missing value
		end getLeftPaneUI
		
		
		on getRightPaneUI()
			if running of application "System Settings" is false then return missing value
			
			tell application "System Events" to tell process "System Settings"
				try
					return group 2 of splitter group 1 of group 1 of front window
				on error
					try
						return list 2 of splitter group 1 of list 1 of front window
					on error the errorMessage number the errorNumber
						logger's warn(errorMessage)
					end try
				end try
			end tell
			
			missing value
		end getRightPaneUI
	end script
	
	set decPasswords to script "core/dec-system-settings_passwords"
	set decVoiceControl to script "core/dec-system-settings_accessibility_voice-control"
	set decVoiceCommand to script "core/dec-system-settings_accessibility_voice-control_voice-commands"
	set decDisplays to script "core/dec-system-settings_displays"
	set decSound to script "core/dec-system-settings_sound"
	set decDesktopAndDock to script "core/dec-system-settings_desktop-and-dock"
	set decLockScreen to script "core/dec-system-settings_lock-screen"
	set decKeyboard to script "core/dec-system-settings_keyboard"
	
	decPasswords's decorate(SystemSettingsInstance)
	decVoiceControl's decorate(result)
	decVoiceCommand's decorate(result)
	decDisplays's decorate(result)
	decSound's decorate(result)
	decDesktopAndDock's decorate(result)
	decLockScreen's decorate(result)
	decKeyboard's decorate(result)
	
	set decorator to decoratorLib's new(result)
	decorator's decorateByName("SystemSettingsInstance")
end new


(*com.apple.systempreferences.GeneralSettings*)
(*com.apple.SystemProfiler.AboutExtension*)
(*com.apple.Software-Update-Settings.extension*)
(*com.apple.settings.Storage*)
(*com.apple.AirDrop-Handoff-Settings.extension*)
(*com.apple.LoginItems-Settings.extension*)
(*com.apple.Coverage-Settings.extension*)
(*com.apple.Localization-Settings.extension*)
(*com.apple.Date-Time-Settings.extension*)
(*com.apple.Sharing-Settings.extension*)
(*com.apple.Time-Machine-Settings.extension*)
(*com.apple.Transfer-Reset-Settings.extension*)
(*com.apple.Startup-Disk-Settings.extension*)
(*com.apple.Profiles-Settings.extension*)
(*com.apple.Touch-ID-Settings.extension*TouchIDPasswordPrefs*)
(*com.apple.Siri-Settings.extension*siri-sae*)
(*com.apple.Battery-Settings.extension*BatteryPreferences*)
(*com.apple.Spotlight-Settings.extension*)
(*com.apple.Game-Center-Settings.extension*)
(*com.apple.Game-Controller-Settings.extension*)
(*com.apple.ControlCenter-Settings.extension*)
(*com.apple.Lock-Screen-Settings.extension*)
(*com.apple.Screen-Time-Settings.extension*)
(*com.apple.ScreenSaver-Settings.extension*)
(*com.apple.Trackpad-Settings.extension*)
(*com.apple.WalletSettingsExtension*)
(*com.apple.Print-Scan-Settings.extension*)
(*com.apple.Keyboard-Settings.extension*)
(*com.apple.systempreferences.AppleIDSettings:icloud*)
(*com.apple.Displays-Settings.extension*)
(*com.apple.settings.PrivacySecurity.extension*)
(*com.apple.Users-Groups-Settings.extension*)
(*com.apple.Internet-Accounts-Settings.extension*)
(*com.apple.Desktop-Settings.extension*)
(*com.apple.Network-Settings.extension*)
(*com.apple.Accessibility-Settings.extension*)
(*com.apple.Notifications-Settings.extension*)
(*com.apple.wifi-settings-extension*)
(*com.apple.Appearance-Settings.extension*)
(*com.apple.Focus-Settings.extension*)
(*com.apple.Wallpaper-Settings.extension*)
(*com.apple.Sound-Settings.extension*)
(*com.apple.BluetoothSettings*)
(*com.apple.systempreferences.AppleIDSettings*AppleIDSettings*)
(*org.gpgtools.gpgpreferences*)
(*com.oracle.oss.mysql.prefPane*)
(*com.apple.Family-Settings.extension*Family*)