(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/Level_2/window

	@Created:
		Wed Dec 28 18:24:28 2022

	@Last Modified: 2026-03-24 17:31:31

	@Change Logs:
		Wed, Mar 18, 2026, at 10:43:28 AM - Added window overlap handlers.
*)
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		INFO:
		Manual: Has Window (Check absence, presence, and on another desktop)
		Dummy
		Dummy
		Dummy

		Manual: Window Points
		Manual: Is a coordinate inside a window
		Manual: Is Window Overlapping E2E
		Manual: Compute adjustment point
		Manual: Remove overlap
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
	logger's infof("Has Window: {}", sut's hasWindow("Safari"))

	if caseIndex is greater than 5 then
		set sutAppNameOne to "Script Editor"
		logger's infof("sutAppNameOne: {}", sutAppNameOne)

		set sutAppNameTwo to "iTerm2"
		logger's debugf("sutAppNameTwo: {}", sutAppNameTwo)

		logger's debugf("Left most window process name: {}", sut's detectLeftMostWindowProcess(sutAppNameOne, sutAppNameTwo))
	end if

	if caseIndex is 1 then

	else if caseIndex is 6 then
		set fourPoints to sut's getWindowPoints("Script Editor")
		log fourPoints

	else if caseIndex is 7 then
		set windowPointsOne to sut's getWindowPoints(sutAppNameOne)
		set windowPointsTwo to sut's getWindowPoints(sutAppNameTwo)

		logger's infof("{}'s x1 and y1 is inside the {} window: {}", {sutAppNameTwo, sutAppNameOne, sut's isPointInsideWindow({windowPointsTwo's x1, windowPointsTwo's y1}, windowPointsOne)})

		logger's infof("{}'s x2 and y2 is inside the {} window: {}", {sutAppNameTwo, sutAppNameOne, sut's isPointInsideWindow({windowPointsTwo's x2, windowPointsTwo's y2}, windowPointsOne)})

		logger's infof("{}'s x3 and y3 is inside the {} window: {}", {sutAppNameTwo, sutAppNameOne, sut's isPointInsideWindow({windowPointsTwo's x3, windowPointsTwo's y3}, windowPointsOne)})

		logger's infof("{}'s x4 and y4 is inside the {} window: {}", {sutAppNameTwo, sutAppNameOne, sut's isPointInsideWindow({windowPointsTwo's x4, windowPointsTwo's y4}, windowPointsOne)})

	else if caseIndex is 8 then

		logger's infof("isOverlapping: {}", sut's isOverlapping(sutAppNameOne, sutAppNameTwo))

	else if caseIndex is 9 then
		set overlapRecord to sut's computeOverlap(sutAppNameOne, sutAppNameTwo)
		log overlapRecord
		set adjustDirection to "vertical"
		if overlapRecord's |x-overlap| is not 0 and overlapRecord's |x-overlap| is not 0 and overlapRecord's |x-overlap| is less than overlapRecord's |y-overlap| then
			set adjustDirection to "horizontal"
		end if
		logger's debugf("adjustDirection: {}", adjustDirection)

	else if caseIndex is 10 then
		set overlapRecord to sut's computeOverlap(sutAppNameOne, sutAppNameTwo)
		log overlapRecord
		sut's removeOverlap(sutAppNameOne, sutAppNameTwo)
	end if

	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's inject(me)

	script WindowInstance
		property coordinatesBuffer : 20

		on removeOverlap(processNameOne, processNameTwo)
			set overlapRecord to computeOverlap(processNameOne, processNameTwo)
			set xOverlap to overlapRecord's |x-overlap|
			set yOverlap to overlapRecord's |y-overlap|

			if xOverlap is not 0 and yOverlap is not 0 then
				if xOverlap is less than yOverlap then
					-- logger's debug("Shrinking horizontally")
					set processToShrink to detectLeftMostWindowProcess(processNameOne, processNameTwo)
					tell application "System Events" to tell process processToShrink
						set currentSize to size of front window
						set size of front window to {(item 1 of currentSize) - xOverlap, item 2 of currentSize}
					end tell

				else
					-- logger's debug("Shrinking vertically")
					set processToShrink to detectTopMostWindowProcess(processNameOne, processNameTwo)
					tell application "System Events" to tell process processToShrink
						set currentSize to size of front window
						set size of front window to {item 1 of currentSize, (item 2 of currentSize) - yOverlap}
					end tell
				end if

			else if xOverlap is not 0 then
				-- logger's debug("Shrinking horizontally")
				set processToShrink to detectLeftMostWindowProcess(processNameOne, processNameTwo)
				tell application "System Events" to tell process processToShrink
					set currentSize to size of front window
					set size of front window to {(item 1 of currentSize) - xOverlap, item 2 of currentSize}
				end tell

			else if yOverlap is not 0 then
				-- logger's debug("Shrinking vertically")
				set processToShrink to detectTopMostWindowProcess(processNameOne, processNameTwo)
				tell application "System Events" to tell process processToShrink
					set currentSize to size of front window
					set size of front window to {item 1 of currentSize, (item 2 of currentSize) - yOverlap}
				end tell
			end if
		end removeOverlap


		(*
			@returns process name of the left most window
		*)
		on detectTopMostWindowProcess(processNameOne, processNameTwo)
			set windowPointsOne to getWindowPoints(processNameOne)
			set windowPointsTwo to getWindowPoints(processNameTwo)
			if windowPointsOne's y1 is less than windowPointsTwo's y1 then return processNameOne

			processNameTwo
		end detectTopMostWindowProcess

		(*
			@returns System Event window
		*)
		on detectLeftMostWindowProcess(processNameOne, processNameTwo)
			set windowPointsOne to getWindowPoints(processNameOne)
			set windowPointsTwo to getWindowPoints(processNameTwo)
			if windowPointsOne's x1 is less than windowPointsTwo's x1 then return processNameOne

			processNameTwo
		end detectLeftMostWindowProcess


		(*
			@returns {x-overlap, y-overlap}
				x-overlap is positive number if it overlaps on the horizontal plane, otherwise it is 0.
				y-overlap is positive number if it overlaps on the vertical plane, otherwise it is 0.
		*)
		on computeOverlap(processNameOne, processNameTwo)
			set windowPointsTwo to getWindowPoints(processNameTwo)
			if not isOverlapping(processNameOne, processNameTwo) then return {|x-overlap|:0, |y-overlap|:0}

			set windowPointsOne to getWindowPoints(processNameOne)

			-- compute x-overlap
			-- logger's debugf("windowPointsOne's x1: {}", windowPointsOne's x1)
			-- logger's debugf("windowPointsTwo's x1: {}", windowPointsTwo's x1)

			if windowPointsOne's x1 is equal to windowPointsTwo's x1 or windowPointsOne's x2 is equal to windowPointsTwo's x2 then
				-- logger's debug("window one is aligned horizontally with window two")
				set overlapX to 0

			else if windowPointsOne's x1 < windowPointsTwo's x1 then
				-- logger's debug("window one is to the left of window two")
				set overlapX to ((windowPointsOne's x1) + (windowPointsOne's w)) - (windowPointsTwo's x1)
			else
				-- logger's debug("window one is to the right of window two")
				set overlapX to ((windowPointsTwo's x1) + (windowPointsTwo's w)) - (windowPointsOne's x1)
			end if

			-- compute y-overlap
			-- logger's debugf("windowPointsOne's y1: {}", windowPointsOne's y1)
			-- logger's debugf("windowPointsTwo's y1: {}", windowPointsTwo's y1)

			if windowPointsOne's y1 is equal to windowPointsTwo's y1 or windowPointsOne's y2 is equal to windowPointsTwo's y2 then
				-- logger's debug("window one is aligned vertically with window two")
				set overlapY to 0

			else if windowPointsOne's y1 < windowPointsTwo's y1 then
				-- logger's debug("window one is above window two")
				set overlapY to ((windowPointsOne's y1) + (windowPointsOne's h)) - (windowPointsTwo's y1)
			else
				-- logger's debug("window two is above window one")
				set overlapY to ((windowPointsTwo's y1) + (windowPointsTwo's h)) - (windowPointsOne's y1)

			end if

			{|x-overlap|:overlapX, |y-overlap|:overlapY}
		end computeOverlap


		on isOverlapping(processNameOne, processNameTwo)
			set windowPointsOne to getWindowPoints(processNameOne)
			set windowPointsTwo to getWindowPoints(processNameTwo)

			isPointInsideWindow({windowPointsOne's x1, windowPointsOne's y1}, windowPointsTwo) or isPointInsideWindow({windowPointsOne's x2, windowPointsOne's y2}, windowPointsTwo) or isPointInsideWindow({windowPointsOne's x3, windowPointsOne's y3}, windowPointsTwo) or isPointInsideWindow({windowPointsOne's x4, windowPointsOne's y4}, windowPointsTwo) or isPointInsideWindow({windowPointsTwo's x1, windowPointsTwo's y1}, windowPointsOne) or isPointInsideWindow({windowPointsTwo's x2, windowPointsTwo's y2}, windowPointsOne) or isPointInsideWindow({windowPointsTwo's x3, windowPointsTwo's y3}, windowPointsOne) or isPointInsideWindow({windowPointsTwo's x4, windowPointsTwo's y4}, windowPointsOne)
		end isOverlapping

		(*
			@coordinate - record with x and y property.

			@returns true if points overlap.
		*)
		on isPointInsideWindow(pCoordinate, fourPointRecord)
			set coordinateRecord to {x:item 1 of pCoordinate, y:item 2 of pCoordinate}

			set hOverlap to coordinateRecord's x is greater than or equal to (fourPointRecord's x1) + (my coordinatesBuffer) and coordinateRecord's x is less than or equal to (fourPointRecord's x2) - (my coordinatesBuffer)

			(*
				logger's debugf("coordinateRecord's x: {}", coordinateRecord's x)
				logger's debugf("fourPointRecord's x1: {}", fourPointRecord's x1)
				logger's debugf("fourPointRecord's x2: {}", fourPointRecord's x2)
				*)
			-- logger's debugf("hOverlap: {}", hOverlap)

			set vOverlap to coordinateRecord's y is greater than or equal to (fourPointRecord's y1) + (my coordinatesBuffer) and coordinateRecord's y is less than or equal to (fourPointRecord's y3) - (my coordinatesBuffer)
			(*
				logger's debugf("coordinateRecord's y: {}", coordinateRecord's y)
				logger's debugf("fourPointRecord's y1: {}", fourPointRecord's y1)
				logger's debugf("fourPointRecord's y3: {}", fourPointRecord's y3)
				*)
			-- logger's debugf("vOverlap: {}", vOverlap)
			hOverlap and vOverlap
		end isPointInsideWindow


		(*
			@returns record of points top-left, top-right, bottom-left, and bottom-right()
				{p1(top-left), p2(top-right), p3(bottom-right), p4(bottom-left)}
		*)
		on getWindowPoints(processName)
			tell application "System Events" to tell process processName
				set p to position of front window
				set s to size of front window
			end tell

			{p, {(item 1 of p) + (item 1 of s), item 2 of p}, {(item 1 of p), (item 2 of p) + (item 2 of s)}, {(item 1 of p) + (item 1 of s), (item 2 of p) + (item 2 of s)}}
			{x1:item 1 of p, x2:(item 1 of p) + (item 1 of s), x3:(item 1 of p), x4:(item 1 of p) + (item 1 of s), y1:item 2 of p, y2:item 2 of p, y3:(item 2 of p) + (item 2 of s), y4:(item 2 of p) + (item 2 of s), w:item 1 of s, h:item 2 of s}
		end getWindowPoints


		on hasWindow(appName)
			hasAllWindows({appName})
		end hasWindow

		(*
			Purpose?

			@appNames list of app names
		*)
		on hasAllWindows(appNames)
			set calcAppNames to appNames
			if class of appNames is text then set calcAppNames to {appNames}

			repeat with nextAppName in calcAppNames
				if running of application nextAppName is false then return false

				tell application "System Events" to tell process nextAppName
					if (count of windows) is 0 then return false
				end tell
			end repeat

			true
		end hasAllWindows
	end script
end new
