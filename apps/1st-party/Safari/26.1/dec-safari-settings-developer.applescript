(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/26.1/dec-safari-settings-developer

	@Created: Sat, Jun 14, 2025 at 01:31:12 PM
	@Last Modified: 2025-12-13 10:29:26
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

property logger : missing value

property CHECKBOX_ALLOW_JAVASCRIPT_FROM_APPLE_EVENTS : "Allow JavaScript from Apple Events"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Toggle Show features for web developers
		Manual: Set Show features for web developers - ON
		Manual: Set Show features for web developers - OFF
		Manual: Respond Allow
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	-- activate application ""
	set sutLib to script "core/safari"
	set sut to sutLib's new()
	set sut to decorate(sut)

	logger's infof("{}: {}", {CHECKBOX_ALLOW_JAVASCRIPT_FROM_APPLE_EVENTS, sut's isAllowJavaScriptFromAppleEvents()})
	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's toggleAllowJavascriptFromAppleEvents()

	else if caseIndex is 3 then
		sut's setAllowJavascriptFromAppleEventsOn()

	else if caseIndex is 4 then
		sut's setAllowJavascriptFromAppleEventsOff()

	else if caseIndex is 5 then
		sut's respondAllow()

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script SafariSettingsAdvancedDecorator
		property parent : mainScript

		on respondAllow()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return

			tell application "System Events" to tell process "Safari"
				click button "Allow" of sheet 1 of window "Developer"
			end tell
		end respondAllow

		on isAllowJavaScriptFromAppleEvents()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value

			tell application "System Events" to tell process "Safari"
				try
					return value of checkbox CHECKBOX_ALLOW_JAVASCRIPT_FROM_APPLE_EVENTS of group 1 of group 1 of settingsWindow is 1

				end try
			end tell
			false
		end isAllowJavaScriptFromAppleEvents


		on toggleAllowJavascriptFromAppleEvents()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value

			tell application "System Events" to tell process "Safari"
				try
					click checkbox CHECKBOX_ALLOW_JAVASCRIPT_FROM_APPLE_EVENTS of group 1 of group 1 of settingsWindow
				end try
			end tell
		end toggleAllowJavascriptFromAppleEvents


		on setAllowJavascriptFromAppleEventsOn()
			if not isAllowJavaScriptFromAppleEvents() then toggleAllowJavascriptFromAppleEvents()
		end setAllowJavascriptFromAppleEventsOn


		on setAllowJavascriptFromAppleEventsOff()
			if isAllowJavaScriptFromAppleEvents() then toggleAllowJavascriptFromAppleEvents()
		end setAllowJavascriptFromAppleEventsOff


	end script
end decorate
