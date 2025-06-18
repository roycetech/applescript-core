(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/18.5/dec-safari-settings-advanced

	@Created: Sat, Jun 14, 2025 at 01:31:12 PM
	@Last Modified: 2025-06-14 19:20:12
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
		Manual: Toggle Show features for web developers
		Manual: Set Show features for web developers - ON
		Manual: Set Show features for web developers - OFF
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

	logger's infof("Show features for web developers: {}", sut's isShowFeaturesForWebDevelopers())
	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's toggleShowFeaturesForWebDevelopers()

	else if caseIndex is 3 then
		sut's setShowFeaturesForWebDevelopersOn()

	else if caseIndex is 4 then
		sut's setShowFeaturesForWebDevelopersOff()

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

		on isShowFeaturesForWebDevelopers()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value

			tell application "System Events" to tell process "Safari"
				try
					return value of checkbox "Show features for web developers" of group 1 of group 1 of settingsWindow is 1

				end try
			end tell
			false
		end isShowFeaturesForWebDevelopers


		on toggleShowFeaturesForWebDevelopers()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value

			tell application "System Events" to tell process "Safari"
				try
					click checkbox "Show features for web developers" of group 1 of group 1 of settingsWindow
				end try
			end tell
		end toggleShowFeaturesForWebDevelopers


		on setShowFeaturesForWebDevelopersOn()
			if not isShowFeaturesForWebDevelopers() then toggleShowFeaturesForWebDevelopers()
		end setShowFeaturesForWebDevelopersOn


		on setShowFeaturesForWebDevelopersOff()
			if isShowFeaturesForWebDevelopers() then toggleShowFeaturesForWebDevelopers()
		end setShowFeaturesForWebDevelopersOff


	end script
end decorate
