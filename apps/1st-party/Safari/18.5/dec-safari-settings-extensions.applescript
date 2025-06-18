(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/18.5/dec-safari-settings-extensions

	@Created: Fri, Jun 06, 2025 at 08:39:15 AM
	@Last Modified: 2025-06-14 08:33:47
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
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

	if caseIndex is 1 then

	else if caseIndex is 2 then

	else if caseIndex is 3 then

	else if caseIndex is 5 then
		sut's enableExtension("Unicorn")
		sut's enableExtension("safari-extension-poc")

	else if caseIndex is 6 then
		sut's disableExtension("Unicorn")
		sut's disableExtension("safari-extension-poc")

	else if caseIndex is 7 then
		sut's closeOnExtensionToggle("safari-extension-poc", 0)

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script SafariSettingsExtensionsDecorator
		property parent : mainScript

		(*
			@returns true if extension is toggled.
		*)
		on enableExtension(extensionKeyword)
			set prefsWindow to getPreferencesWindow()
			if prefsWindow is missing value then return false

			if getPreferencesTabName() is not "Extensions" then switchPreferencesTab("Extensions")
			set extRow to getExtensionRow(extensionKeyword)
			if extRow is missing value then return false

			tell application "System Events" to tell process "Safari"
				if value of checkbox 1 of UI element 1 of extRow is 0 then
					click checkbox 1 of UI element 1 of extRow
					return true
				end if
			end tell

			false
		end enableExtension


		(*
			@returns true if extension is toggled.
		*)
		on disableExtension(extensionKeyword)
			set prefsWindow to getPreferencesWindow()
			if prefsWindow is missing value then return false

			if getPreferencesTabName() is not "Extensions" then switchPreferencesTab("Extensions")
			set extRow to getExtensionRow(extensionKeyword)
			if extRow is missing value then return false

			tell application "System Events" to tell process "Safari"
				if value of checkbox 1 of UI element 1 of extRow is 1 then
					click checkbox 1 of UI element 1 of extRow
					return true
				end if
			end tell
			false
		end disableExtension


		on closeOnExtensionToggle(extensionKeyword, targetStatus)
			set retry to retryLib's new()
			set prefsWindow to getPreferencesWindow()
			if prefsWindow is missing value then return false

			if getPreferencesTabName() is not "Extensions" then switchPreferencesTab("Extensions")
			set extRow to getExtensionRow(extensionKeyword)
			if extRow is missing value then return false

			script ToggleWaiter
				tell application "System Events" to tell process "Safari"
					if value of checkbox 1 of UI element 1 of extRow is targetStatus then return true
				end tell
			end script
			exec of retry on result for 10
			if result is not missing value then closePreferences()
		end closeOnExtensionToggle


		on getExtensionRow(extensionKeyword)
			set prefsWindow to getPreferencesWindow()
			if prefsWindow is missing value then return

			if getPreferencesTabName() is not "Extensions" then switchPreferencesTab("Extensions")

			tell application "System Events" to tell process "Safari"
				set myExtRow to missing value
				try
					set myExtRow to first row of table 1 of scroll area 1 of group 1 of group 1 of group 1 of prefsWindow whose value of static text 1 of UI element 1 starts with extensionKeyword
				end try

			end tell
			myExtRow
		end getExtensionRow
			end script
end decorate
