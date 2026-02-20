(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/ChatGPT/1.2025.168/chat-gpt

	@Created: Tue, Jul 01, 2025 at 07:20:31 AM
	@Last Modified: 2026-02-10 08:07:28

	@Change Logs:
		Tue, Feb 10, 2026, at 08:07:18 AM - Added handler #closeRightSideBar
*)

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: New Chat
		Manual: Close right side bar
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's newChat()

	else if caseIndex is 3 then
		sut's closeRightSideBar()

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)

	script ChatGptInstance
		on newChat()
			if running of application "ChatGPT" is false then
				activate application "ChatGPT"
			end if

			tell application "System Events" to tell process "ChatGPT"
				-- click (first button of button 2 of toolbar 1 of front window whose help is "New Chat")
				set frontmost to true
				try
					click menu item "New Chat" of menu 1 of menu bar item "File" of menu bar 1
				end try
			end tell
		end newChat

		on closeRightSideBar()
			tell application "System Events" to tell process "ChatGPT"
				set frontmost to true
				try
					click button 2 of last group of splitter group 1 of group 1 of front window
				end try
			end tell
		end closeRightSideBar
	end script
end new
