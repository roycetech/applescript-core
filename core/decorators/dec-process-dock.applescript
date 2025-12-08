(*
	WIP:
		Working for bottom dock only. To do the sides as needed.

	@Purpose:
		Provide handlers that will detect window overlap to the dock

	@Suggestion for window positioning configuration:
		1. Save window position with the dock hidden.
		2. When the dock is not hidden and overlap is detected, reduce the height of the offending window.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/decorators/dec-process-dock-aware

	@Created: Thu, Feb 27, 2025 at 08:05:29 AM
	@Last Modified: 2025-12-08 16:42:41
	@Change Logs:
*)
use scripting additions

use loggerFactory : script "core/logger-factory"

use dockLib : script "core/dock"

property logger : missing value

property dock : missing value
property VERTICAL_CORRECTION : 4

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Reduce window size
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
	set sutLib to script "core/process"
	set sut to sutLib's new("Script Editor")
	set sut to decorate(sut)

	logger's infof("Is dock overlapping window: {}", sut's isDockOverlappingWindow())
	set isOverlapping to sut's isDockOverlappingWindow()

	set overlappingAmount to 0
	if isOverlapping then
		set overlappingAmount to sut's computeOverlapSize()
		logger's infof("Overlapping amount: {}", overlappingAmount)
	end if

	-- logger's debugf("Dock height: {}", dock's getHeight())
	-- logger's debugf("Dock width: {}", dock's getWidth())
	-- logger's debugf("Dock x: {}", dock's getHorizontalPosition())
	-- logger's debugf("Dock y: {}", dock's getVerticalPosition())

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's reduceWindowHeight(overlappingAmount)

	else if caseIndex is 3 then

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set dock to dockLib's new()

	script ProcessDockAwareDecorator
		property parent : mainScript

		on waitActivate()
			set parentResult to continue waitActivate()
			if parentResult then return true

			dock's clickApp(processName)
			repeat 6 times
				tell application "System Events" to tell process parent's processName
					if exists (window 1) then return true
				end tell
				delay 0.5
			end repeat

			false
		end waitActivate


		on reduceWindowHeight(heightAdjustAmount)
			set systemEventsWindow to getFirstSystemEventsWindow()
			if systemEventsWindow is missing value then return
			if heightAdjustAmount is less than or equal to 0 then return

			tell application "System Events"
				set {currentWidth, currentHeight} to size of systemEventsWindow
				set size of systemEventsWindow to {currentWidth - 100, currentHeight - 100} -- Tried plus to avoid hitting the minimum limit but it just failed to resize as expected.
				delay 0.2 -- Too small resize fails to work so resize to a bigger size first
				set size of systemEventsWindow to {currentWidth + 100, currentHeight - heightAdjustAmount + 100}
			end tell
		end reduceWindowHeight


		(*
			@returns the amount of overlap length. 0 for no overlap.
		*)
		on computeOverlapSize()
			set winObj to getFirstSystemEventsWindow()
			if winObj is missing value then return 0
			if dock's isAutoHide() then return 0

			tell application "System Events"
				set winPos to position of winObj
				set winSize to size of winObj
			end tell

			set dockPosition to dock's getPosition()
			-- logger's debugf("dockPosition: {}", dockPosition)

			-- Extract values
			set dockWidth to dock's getWidth()
			set dockHeight to dock's getHeight()

			set {winX, winY} to winPos
			set {winWidth, winHeight} to winSize

			set winX2 to winX + winWidth
			set winY2 to winY + winHeight

			-- Get screen dimensions
			set screenBounds to (do shell script "system_profiler SPDisplaysDataType | awk '/Resolution/ {print $2, $4}'")
			set {screenWidth, screenHeight} to words of screenBounds

			if dockPosition as text is equal to "bottom" then
				set dockTopY to (dock's getVerticalPosition()) + VERTICAL_CORRECTION
				-- logger's debugf("dockTopY: {}", dockTopY)
				if (winY2 > dockTopY) then return winY2 - dockTopY

				-- Dock on left
			else if dockPosition is "left" then
				return (winX1 < dockWidth)

				-- Dock on right
			else if dockPosition is "right" then
				set dockLeftX to (screenWidth - dockWidth)
				return (winX2 > dockLeftX)
			end if

			return 0
		end computeOverlapSize


		on isDockOverlappingWindow()
			set winObj to getFirstSystemEventsWindow()
			if winObj is missing value then return false
			if dock's isAutoHide() then return false

			tell application "System Events"
				set winPos to position of winObj
				set winSize to size of winObj
			end tell

			set dockPosition to dock's getPosition()
			-- logger's debugf("dockPosition: {}", dockPosition)

			-- Extract values
			set dockWidth to dock's getWidth()
			set dockHeight to dock's getHeight()

			set {winX, winY} to winPos
			set {winWidth, winHeight} to winSize

			-- Compute window edges
			set winX2 to winX + winWidth
			set winY2 to winY + winHeight
			-- logger's debugf("winY: {}", winY)
			-- logger's debugf("winY2: {}", winY2)
			-- logger's debugf("winHeight: {}", winHeight)

			-- Get screen dimensions
			set screenBounds to (do shell script "system_profiler SPDisplaysDataType | awk '/Resolution/ {print $2, $4}'")
			set {screenWidth, screenHeight} to words of screenBounds

			-- logger's debugf("dockPosition: {}", dockPosition)
			-- Dock at bottom
			if dockPosition as text is equal to "bottom" then
				set dockTopY to (dock's getVerticalPosition()) + VERTICAL_CORRECTION
				-- logger's debugf("dockTopY: {}", dockTopY)
				return (winY2 > dockTopY)

				-- Dock on left
			else if dockPosition is "left" then
				return (winX1 < dockWidth)

				-- Dock on right
			else if dockPosition is "right" then
				set dockLeftX to (screenWidth - dockWidth)
				return (winX2 > dockLeftX)
			end if

			return false
		end isDockOverlappingWindow
	end script
end decorate
