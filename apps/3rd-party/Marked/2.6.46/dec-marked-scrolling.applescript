(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Marked/2.6.46/dec-marked-scrolling

	@Created: Tue, May 27, 2025 at 03:23:37 PM
	@Last Modified: 2025-10-13 07:12:41
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
		Manual: Scroll to Bottom
		Manual: Scroll to Top
		Manual: Scroll Down a Step
		Manual: Scroll Up a Step

		Manual: Scroll Page Down
		Manual: Scroll Page Up
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
	set sutLib to script "core/marked"
	set sut to sutLib's new()
	set sut to decorate(sut)

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's scrollToBottom()

	else if caseIndex is 3 then
		sut's scrollToTop()

	else if caseIndex is 4 then
		set markdownTab to sut's getFrontTab()
		sut's scrollStepDown()

	else if caseIndex is 5 then
		set markdownTab to sut's getFrontTab()
		sut's scrollStepUp()

	else if caseIndex is 6 then
		set markdownTab to sut's getFrontTab()
		sut's scrollPageDown()

	else if caseIndex is 7 then
		set markdownTab to sut's getFrontTab()
		sut's scrollPageUp()

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script MarkedScrollingDecorator
		property parent : mainScript


		on scrollToBottom()
			if running of application "Marked 2" is false then return

			tell application "System Events" to tell process "Marked 2"
				set value of scroll bar 1 of scroll area 1 of group 1 of front window to 1
			end tell
		end scrollToBottom


		on scrollToTop()
			if running of application "Marked 2" is false then return

			tell application "System Events" to tell process "Marked 2"
				set value of scroll bar 1 of scroll area 1 of group 1 of front window to 0
			end tell
		end scrollToTop


		on scrollStepDown()
			tell application "System Events" to tell process "Marked 2"
				repeat 2 times
					click (first button of scroll bar 1 of scroll area 1 of group 1 of front window whose description is "increment arrow button")
				end repeat
			end tell
		end scrollStepDown


		on scrollStepUp()

			tell application "System Events" to tell process "Marked 2"
				repeat 2 times
					click (first button of scroll bar 1 of scroll area 1 of group 1 of front window whose description is "decrement arrow button")
				end repeat
			end tell
		end scrollStepUp


		on scrollPageDown()
			tell application "System Events" to tell process "Marked 2"
				click (first button of scroll bar 1 of scroll area 1 of group 1 of front window whose description is "decrement page button")
			end tell
		end scrollPageDown


		on scrollPageUp()
			tell application "System Events" to tell process "Marked 2"
				click (first button of scroll bar 1 of scroll area 1 of group 1 of front window whose description is "increment page button")
			end tell
		end scrollPageUp
	end script
end decorate
