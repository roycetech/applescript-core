(*
	How to determine coordinates:

		Using the default macOS Screen Capture, press command + control + shift + 4.

		1. Verify dimension by trying out the screenshot before integrating with
			your main script.

		Date Format: 0819-0859-

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/screenshot

	@Script Menu
		View Image From Clipboard - to view the clipboard contents during testing.

	@Redesigned: August 25, 2023 7:19 PM
*)

use script "core/Text Utilities"

use scripting additions

use std : script "core/std"
use textUtil : script "core/string"
use Math : script "core/math"
use listUtil : script "core/list"
use loggerFactory : script "core/logger-factory"

use dateTime : script "core/date-time"

use spotScript : script "core/spot-test"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Capture App Window to Clipboard
		Manual: Capture Dimensions to Clipboard
		Manual: Capture Points to Clipboard

		Manual: Capture App Window to File
		Manual: Capture Dimensions to File
		Manual: Capture Points to File
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set generatedFilePath to missing value
	set sut to new()
	if caseIndex is 1 then
		sut's captureFrontAppToClipboard("Script Editor")

	else if caseIndex is 2 then
		sut's captureDimensionsToClipboard(100, 100, 200, 100)

	else if caseIndex is 3 then
		-- sut's capturePointsToClipboard(1000, 900, 1400, 1100)
		sut's capturePointsToClipboard(0, 93, 950, 535, "Spot.png")

	else if caseIndex is 4 then
		sut's captureFrontAppToFile("Script Editor", "Spot.png")

	else if caseIndex is 5 then
		sut's captureDimensionsToFile(100, 100, 200, 100, "Spot.png")

	else if caseIndex is 6 then
		-- sut's capturePointsToFile(1000, 900, 1400, 1100, "Spot.png")

	end if

	try
		set generatedFilePath to result
	end try
	if generatedFilePath is not missing value then
		logger's debugf("generatedFilePath: {}", generatedFilePath)

		(*
			The app script needs to complete before the file is actually revealable in the finder that's why I
			created an optional Delayed AppleScript app for testing only.
		*)
		set optionalAppName to "Delayed Applescript"
		if std's appExists(optionalAppName) then
			tell application optionalAppName
				activate
				set theScript to "tell application \"Finder\" to reveal POSIX file \"" & generatedFilePath & "\""
				logger's debugf("theScript: {}", theScript)
				runScript(theScript, 1)
			end tell
		end if
	end if

	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's inject(me)

	script ScreenshotInstance
		property savePath : "/Users/" & std's getUsername()

		(*
			All handlers lead here.
		*)
		on captureDimensionsToFile(x, y, w, h, baseFilename)
			if baseFilename is missing value then
				set filePathParam to ""
			else
				set filePathParam to format {"{}/{}-{}", {savePath, my _nowForScreenShot(), baseFilename}}
			end if

			set clipboardParam to std's ternary(baseFilename is missing value, " -c", "")
			set command to textUtil's rtrim(format {"screencapture{} -R{},{},{},{} {}", {clipboardParam, x, y, w, h, filePathParam}})
			logger's debugf("command: {}", command)

			do shell script command
			std's ternary(baseFilename is missing value, missing value, filePathParam)
		end captureDimensionsToFile


		on captureFrontAppToFile(appName, baseFilename)
			logger's debugf("appName: {}", appName)
			tell application "System Events" to tell process appName
				set {x, y} to position of front window
				set {w, h} to size of front window
			end tell

			-- logger's debugf("X: {}, Y: {}, W: {}, H: {}", {x, y, w, h})
			captureDimensionsToFile(x, y, w, h, baseFilename)
		end captureFrontAppToFile


		on capturePointsToFile(x1, y1, x2, y2, baseFilename)
			set ax1 to Math's abs(x1)
			set ax2 to Math's abs(x2)
			set w to std's ternary(ax2 > ax1, ax2 - ax1, ax1 - ax2)

			set ay1 to Math's abs(y1)
			set ay2 to Math's abs(y2)
			set h to std's ternary(ay2 > ay1, ay2 - ay1, ay1 - ay2)

			captureDimensionsToFile(x1, y1, w, h, baseFilename)
		end capturePointsToFile


		on captureFrontAppToClipboard(appName)
			captureFrontAppToFile(appName, missing value)
		end captureFrontAppToClipboard


		(*  @filename base filename with .png extension.  e.g. "spot.png". This will be saved to default location with timestamp prefix. *)
		on captureDimensionsToClipboard(x, y, w, h)
			captureDimensionsToFile(x, y, w, h, missing value)
		end captureDimensionsToClipboard


		on capturePointsToClipboard(x1, y1, x2, y2)
			capturePointsToFile(x1, y1, x2, y2, missing value)
		end capturePointsToClipboard


		on _nowForScreenShot()
			do shell script "date '+%m%d-%H%M'"
		end _nowForScreenShot
	end script
end new