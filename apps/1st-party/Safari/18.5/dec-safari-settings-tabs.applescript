(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/18.5/dec-safari-settings-tabs

	@Created: Sat, Jun 14, 2025 at 01:33:53 PM
	@Last Modified: 2025-06-14 19:05:10
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		Main
		Manual: Set Tab Layout
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

	logger's infof("Tab layout: {}", sut's getTabLayout())
	if caseIndex is 1 then

	else if caseIndex is 2 then
		set sutTabLayout to "Unicorn"
		set sutTabLayout to "Compact"

		logger's debugf("sutTabLayout: {}", sutTabLayout)

		sut's setTabLayout(sutTabLayout)

	else if caseIndex is 3 then

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script SafariSettingsTabsDecorator
		property parent : mainScript

		on getTabLayout()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value

			tell application "System Events" to tell process "Safari"
				if the value of checkbox 1 of group 1 of group 1 of settingsWindow is 1 then return "Separate"
			end tell

			"Compact"
		end getTabLayout


		(*
			@tabLayout - Separate or Compact
		*)
		on setTabLayout(tabLayout)
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value

			if tabLayout is equal to "Separate" then
				tell application "System Events" to tell process "Safari"
					click checkbox 1 of group 1 of group 1 of settingsWindow
				end tell

			else if tabLayout is equal to "Compact" then
				tell application "System Events" to tell process "Safari"
					click checkbox 2 of group 1 of group 1 of settingsWindow
				end tell

			end if

		end setTabLayout

	end script
end decorate
