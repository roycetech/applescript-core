(*
	@Purpose:
		Handlers for Downloads-related functions.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/26.2/dec-safari-downloads

	@Created: Mon, Feb 09, 2026 at 10:45:42 AM
	@Last Modified: 2026-02-09 10:47:47
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
		Manual: Integration: Reveal latest downloaded file
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
		logger's infof("Result: {}", sut's revealLatestDownloadedFile())

	else if caseIndex is 3 then

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*
	@mainScript - SafariInstance
*)
on decorate(mainScript)
	loggerFactory's inject(me)

	script SafariDownloadsDecorator
		property parent : mainScript

		(*
			@Purpose:
				Quickly reveal the latest downloaded file in Finder.

			@Created: Mon, Feb 09, 2026, at 10:34:33 AM
			@Returns boolean
		*)
		on revealLatestDownloadedFile()
			set mainWindow to getFirstZoomableWindow()
			if mainWindow is missing value then return

			openDownloadsPopup()
			try
				tell application "System Events" to tell process "Safari"
					set downloadsButton to the first button of toolbar 1 of mainWindow whose description is "Downloads"
					click button 1 of group 1 of UI element 1 of row 1 of table "Downloads" of scroll area 1 of pop over 1 of downloadsButton
				end tell
				delay 0.5
				closeDownloadsPopup()
				return true
			end try
			false
		end revealLatestDownloadedFile


		on isDownloadsPopupPresent()
			set mainWindow to getFirstZoomableWindow()
			if mainWindow is missing value then return false

			tell application "System Events" to tell process "Safari"
				try
					set downloadsButton to the first button of toolbar 1 of mainWindow whose description is "Downloads"
					return exists (button 1 of group 1 of UI element 1 of row 1 of table "Downloads" of scroll area 1 of pop over 1 of downloadsButton)
				end try
			end tell

			false
		end isDownloadsPopupPresent


		on closeDownloadsPopup()
			if not isDownloadsPopupPresent() then return

			toggleDownloadsPopup()
		end closeDownloadsPopup


		on openDownloadsPopup()
			if isDownloadsPopupPresent() then return

			toggleDownloadsPopup()
		end openDownloadsPopup


		on toggleDownloadsPopup()
			set mainWindow to getFirstZoomableWindow()
			if mainWindow is missing value then return

			tell application "System Events" to tell process "Safari"
				try
					set downloadsButton to the first button of toolbar 1 of mainWindow whose description is "Downloads"
					click the downloadsButton
					delay 0.5
				end try
			end tell
		end toggleDownloadsPopup
	end script
end decorate
