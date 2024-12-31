(*

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/1st-party/System Settings/15.0/dec-system-settings_sound'
		
	NOT WORKING. Can reveal pane but can't access the different accounts via Scripting.

	@Created:  Wed, Dec 25, 2024 at 7:11:24 PM
	@Last Modified: 
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"
use retryLib : script "core/retry"
use processLib : script "core/process"

property logger : missing value
property PANE_ID_INTERNET_ACCOUNTS : "com.apple.Internet-Accounts-Settings.extension"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Main
		Manual: Reveal Internet Accounts
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	-- activate application ""
	set sutLib to script "core/system-settings"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	-- logger's infof("isPlayFeedbackWhenSoundIsChanged: {}", sut's isPlayFeedbackWhenSoundIsChanged())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's revealInternetAccounts()
		
	else if caseIndex is 3 then
		sut's togglePlayFeedbackWhenSoundIsChanged()
		
	else if caseIndex is 4 then
		sut's setPlayFeedbackWhenSoundIsChangedOn()
		
	else if caseIndex is 5 then
		sut's setPlayFeedbackWhenSoundIsChangedOff()
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script SystemSettingsSoundsDecorator
		property parent : mainScript
		
		on revealInternetAccounts()
			if running of application "System Settings" is false then
				set systemSettingsProcess to processLib's new("System Settings")
				systemSettingsProcess's waitActivate()
			end if
			
			tell application "System Settings"
				reveal pane id PANE_ID_INTERNET_ACCOUNTS
			end tell
			
			set retry to retryLib's new()
			script InternetAccountsPaneWaiter
				tell application "System Events" to tell process "System Settings"
					if exists (window "Internet Accounts") then return true
				end tell
			end script
			exec of retry on result for 3
		end revealInternetAccounts
	end script
end decorate
