(*
	Download cli at https://www.bluem.net/en
	For some reason if you are not moving the mouse pointer far enough, the repositioning of the cursor doesn't change or change but off by a small size.

	@Usage:
		lclick at "UI element" with reset and smoothing

	@Session:
		Pointer Position

	@Plists
		config-system
			cliclick CLI

	@Client Codes:
		System Settings
		Zoom
		1Password 6
		Clean Shot X
		Eclipse

	@Change Log:
		September 20, 2023 11:46 AM - Removed smoothing for movePointer because having it, the pointer doesn't move to the given coordinates.
		Last tested on macOS Monterey, fixed the movePointer now working.

	@Project:
		applescript-core

	@Build:
		make build-cliclick

*)

use script "core/Text Utilities"
use scripting additions

use std : script "core/std"

use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use plutilLib : script "core/plutil"

property logger : missing value
property session : missing value

property CLICLICK_CLI : missing value
property savedPosition : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)

	logger's start()

	set spotScript to script "core/spot-test"
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP:
		Manual: Click on Show Accessory View - Default
		Manual: Click on Show Accessory View - Reset
		Manual: Move To XY
		Manual: DoubleClick Relative

		Manual: Double Click
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	logger's infof("Current Coord: {}:{}", sut's getCurrentCoord())

	if caseIndex is 1 then

	else
		tell application "System Events" to tell process "Script Editor"
			set sutUi to checkbox 1 of group 1 of group 1 of toolbar 1 of front window
		end tell

		if caseIndex is 2 then
			lclick of sut at sutUi

		else if caseIndex is 3 then
			lclick of sut at sutUi with reset

		else if caseIndex is 4 then
			sut's moveToXy(0, 0)

		else if caseIndex is 5 then
			tell application "System Events" to tell process "Ryujinx"
				set frontmost to true
				doubleClickRelative of sut at front window given fromLeft:100, fromTop:200
			end tell

		else if caseIndex is 6 then
			tell application "System Events" to tell process "Windows App"
				set frontmost to true
				delay 0.1

				first group of list 1 of list 1 of scroll area 1 of group 1 of splitter group 1 of front window whose description of group 1 is "Rose Server Main"
			end tell

			doubleLeftClick of sut at result
		end if
	end if

	spot's finish()
	logger's finish()
end spotCheck

on new()
	loggerFactory's injectBasic(me)
	set plutil to plutilLib's new()
	set session to plutil's new("session")

	try
		set CLICLICK_CLI to do shell script "plutil -extract \"cliclick CLI\" raw ~/applescript-core/config-system.plist"
	on error
		error "cliclick was not found. Download cli then run make install-cliclick"
	end try

	script CliClickInstance
		property smoothingSeconds : 1

		on doubleClickRelative at theWindow given fromLeft:pLeft : missing value, fromBottom:pBottom : missing value, fromTop:pTop : missing value, fromRight:pRight : missing value
			tell application "System Events"
				tell theWindow -- do not merge with above, it will fail.
					set {x, y} to its position
					set {w, h} to its size
				end tell
			end tell

			if pLeft is not missing value then set theX to pLeft + x
			if pBottom is not missing value then
				if y is less than 0 then -- 2nd screen at the top
					set theY to y + h - pBottom
				else
					set theY to y + h - pBottom
				end if
			end if

			if pTop is not missing value then
				if y is less than 0 then -- 2nd screen at the top
					set theY to y - pTop
				else
					set theY to y + pTop
				end if
			end if

			doubleClickAtXy(theX, theY)
		end doubleClickRelative


		on lclickRelative at theWindow given fromLeft:pLeft : missing value, fromBottom:pBottom : missing value, fromTop:pTop : missing value, fromRight:pRight : missing value
			tell application "System Events"
				tell theWindow -- do not merge with above, it will fail.
					set {x, y} to its position
					set {w, h} to its size
				end tell
			end tell

			if pLeft is not missing value then set theX to pLeft + x
			if pTop is not missing value then set theY to pTop + y

			if pBottom is not missing value then
				if y is less than 0 then -- 2nd screen at the top
					set theY to y + h - pBottom
				else
					set theY to y + h - pBottom
				end if
			end if

			lclickAtXy(theX, theY)
		end clickRelative

		(*
			Usage: drag from {350, -1250} onto {1020, -1355}
		*)
		on drag from startPos onto endPos

			set origPos to do shell script CLICLICK_CLI & " p:."
			set origPos to textUtil's replace(origPos, "-", "=-")

			set calcStart to _formatCoordinates(first item of startPos, last item of startPos)
			set calcEnd to _formatCoordinates(first item of endPos, last item of endPos)

			tell application "System Events"
				-- drag down, drag up, and click.  does not work without the additional click.
				set clickCommand to CLICLICK_CLI & " -e " & my smoothingSeconds & " dd:" & calcStart & " du:" & calcEnd & " c:" & calcEnd
				do shell script clickCommand
				delay 0.1
				do shell script CLICLICK_CLI & " m:" & origPos
			end tell
		end drag


		on dragFromTo(x1, y1, x2, y2)
			if y1 is less than 0 then
				set y1 to "=" & y1
			end if

			if y2 is less than 0 then
				set y2 to "=" & y2
			end if

			tell application "System Events"
				-- drag down, drag up, and click.  does not work without the additional click.
				set clickCommand to CLICLICK_CLI & " -e " & my smoothingSeconds & " dd:" & x1 & "," & y1 & " du:" & x2 & "," & y2 -- & " c:" & x2 & "," & y2
				-- log clickCommand
				do shell script clickCommand
			end tell
		end dragFromTo


		(*
			-e is for easing, to make it move human-like, sometimes necessary for some
				UIs to detect and respond to.
			September 20, 2023 11:46 AM - Removed smoothing because it does not work.  It does not move the pointer at all.
		*)
		on movePointer at theUi given smoothing:smoothingArg : true
			set coord to getCoord at theUi
			set formattedCoord to _formatCoordinates(item 1 of coord, item 2 of coord)

			set smoothingParam to ""
			if smoothingArg then set smoothingParam to " -e " & smoothingSeconds

			set clickCommand to CLICLICK_CLI & smoothingParam & " m:0,0 m:" & formattedCoord
			do shell script clickCommand
		end movePointer


		(*
			-e is for easing, to make it move human-like, sometimes necessary for some
			UIs to detect and respond to.

			@Known Issues:
				June 16, 2023 - Does not work when smoothing parameter is used.
		*)
		on moveToXy(x, y)
			set formattedCoord to _formatCoordinates(x, y)

			-- set clickCommand to CLICLICK_CLI & " -e 1 m:" & formattedCoord
			set clickCommand to CLICLICK_CLI & " m:" & formattedCoord
			do shell script clickCommand
		end moveToXy


		(*
			-e is for easing, to make it move human-like, sometimes necessary for some
				UIs to detect and respond to.
		*)
		on rclickAtXy(x, y)
			set formattedCoord to _formatCoordinates(x, y)
			set clickCommand to CLICLICK_CLI & " -e 1 rc:" & formattedCoord
			do shell script clickCommand
		end rclickAtXy


		(*
			-e is for easing, to make it move human-like, sometimes necessary for some
				UIs to detect and respond to.
		*)
		on lclickAtXy(x, y)
			saveCurrentPosition()

			set formattedCoord to _formatCoordinates(x, y)
			set clickCommand to CLICLICK_CLI & " -e 1 c:" & formattedCoord

			try
				do shell script clickCommand
			end try -- swallow if the command is not present.

			restorePosition()
		end lclickAtXy


		(*
			-e is for easing, to make it move human-like, sometimes necessary for some
				UIs to detect and respond to.
		*)
		on doubleLeftClickAtXy(x, y)
			saveCurrentPosition()

			set formattedCoord to _formatCoordinates(x, y)
			set clickCommand to CLICLICK_CLI & " -e 1 dc:" & formattedCoord

			try
				do shell script clickCommand
			end try -- swallow if the command is not present.

			restorePosition()
		end doubleLeftClickAtXy


		(*
			Retrofitted from #lclickAtXy.
		*)
		on doubleClickAtXy(x, y)
			saveCurrentPosition()

			set formattedCoord to _formatCoordinates(x, y)
			set clickCommand to CLICLICK_CLI & " -e 1 dc:" & formattedCoord

			try
				do shell script clickCommand
			end try -- swallow if the command is not present.

			restorePosition()
		end doubleClickAtXy

		(*
			Adapter, it conflicts with the click when invoked inside System Events.
		*)
		-- to lclick at theUi with reset and smoothing
		-- 	click at theUi with reset and smoothing
		-- end lclick

		(*
			lclick at "UI element" with reset

			@reset true if you want the pointer to go back to the original position.

			TODO: @reset needs extensive testing. 2. refactor.
		*)
		-- on lclick at theUi with reset and smoothing
		-- on lclick at theUi with reset:false and smoothing:true
		on lclick at theUi given reset:resetArg : true, smoothing:smoothingArg : true, relativex:relativexArg : 0, relativey:relativeyArg : 0

			-- WARNING: if we don't log these parameters, compile error :tableflip:.
			-- Seems  it's no longer a problem February 19, 2021
			-- log reset
			-- log smoothing
			if theUi is missing value then return

			saveCurrentPosition()

			set smoothingParam to ""
			if smoothingArg then set smoothingParam to "-e 1 "

			tell application "System Events"
				tell theUi
					set {xPosition, yPosition} to position
					set {xSize, ySize} to size
				end tell

				set theYPos to yPosition + relativeyArg + (ySize div 2)
				if theYPos is less than 0 then
					set theYPos to "=" & theYPos
				end if
				set negativeX to relativexArg is less than 0
				set cliParamX to std's ternary(negativeX, xPosition + xSize + relativexArg, xPosition + relativexArg + (xSize div 2))
				-- logger's debugf("xPosition: {}", xPosition)
				-- logger's debugf("xSize: {}", xSize)
				-- logger's debugf("cliParamX: {}", cliParamX)
				set clickCommand to CLICLICK_CLI & " " & smoothingParam & "c:" & cliParamX & "," & theYPos
				-- logger's debug(clickCommand)
				do shell script clickCommand
			end tell

			restorePosition()
		end lclick


		(*
			Copied from lclick at.
		*)
		on doubleLeftClick at theUi given reset:resetArg : true, smoothing:smoothingArg : true, relativex:relativexArg : 0, relativey:relativeyArg : 0
			if theUi is missing value then return

			saveCurrentPosition()

			set smoothingParam to ""
			if smoothingArg then set smoothingParam to "-e 1 "

			tell application "System Events"
				tell theUi
					set {xPosition, yPosition} to position
					set {xSize, ySize} to size
				end tell

				set theYPos to yPosition + relativeyArg + (ySize div 2)
				if theYPos is less than 0 then
					set theYPos to "=" & theYPos
				end if
				set negativeX to relativexArg is less than 0
				set cliParamX to std's ternary(negativeX, xPosition + xSize + relativexArg, xPosition + relativexArg + (xSize div 2))
				set clickCommand to CLICLICK_CLI & " " & smoothingParam & "dc:" & cliParamX & "," & theYPos
				do shell script clickCommand
			end tell

			restorePosition()
		end doubleLeftClick


		(*
			click at "UI element" with reset

			@reset true if you want the pointer to go back to the original position.

			TODO: @reset needs extensive testing.
		*)
		on rclick at theUi with reset and smoothing
			-- WARNING: if we don't log these parameters, compile error :tableflip:
			-- log reset
			-- log smoothing

			set smoothingParam to ""
			if smoothing then set smoothingParam to "-e 1 "

			set coord to getCoord at theUi
			set formattedCoord to _formatCoordinates(item 1 of coord, item 2 of coord)
			set clickCommand to CLICLICK_CLI & " " & smoothingParam & "rc:" & formattedCoord
			do shell script clickCommand
		end rclick


		(* Used to explicitly save and restore mouse pointer. *)
		on saveCurrentPosition()
			set origPos to do shell script CLICLICK_CLI & " p:."
			set origPos to textUtil's replace(origPos, "-", "=-")
			set my savedPosition to origPos
			session's setValue("Pointer Position", origPos)
		end saveCurrentPosition


		on getCurrentPosition()
			set currentPos to do shell script CLICLICK_CLI & " p:."
			return textUtil's replace(currentPos, "-", "=-")
		end getCurrentPosition


		on getCurrentCoord()
			set currentCoord to textUtil's replace(getCurrentPosition(), "=-", "-")
			set xyList to textUtil's split(currentCoord, ",")
			return {first item of xyList, last item of xyList}
		end getCurrentCoord


		on restorePosition()
			set savedPosition to session's getValue("Pointer Position")
			-- logger's debugf("Restoring pointer to: {}", savedPosition)
			do shell script CLICLICK_CLI & " m:" & savedPosition
		end restorePosition


		(* @returns 2-element array containing x and y coordinates. *)
		on getCoord at theUi
			tell application "System Events" to tell theUi
				set {xPosition, yPosition} to position
				set {xSize, ySize} to size
			end tell

			set theXPos to xPosition + (xSize div 2)
			set theYPos to yPosition + (ySize div 2)

			return {theXPos, theYPos}
		end getCoord


		-- Private Codes below =======================================================


		(* Changes format to the cliclick recognizable format. *)
		on _formatCoordinates(x, y)
			if x is less than 0 then set x to "=" & x
			if y is less than 0 then set y to "=" & y

			format {"{},{}", {x, y}}
		end _formatCoordinates
	end script
end new
