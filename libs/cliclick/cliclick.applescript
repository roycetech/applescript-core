global std, textUtil, sessionPlist
global CLICLICK_CLI

(* 
	Download cli at https://www.bluem.net/en
	For some reason if you are not moving the mouse pointer far enough, the repositioning of the cursor doesn't change or change but off by a small size. 

	TODO: Refactor to use an instance.

	@Usage:
		lclick at "UI element" with reset and smoothing
		
	@Session:
		Pointer Position
		
	@Plists
		config-system
			cliclick CLI

*)

use script "Core Text Utilities"
use scripting additions

property initialized : false
property logger : missing value
property savedPosition : missing value

if name of current application is "Script Editor" then spotCheck()
if name of current application is "osascript" then unitTest()

on spotCheck()
	init()
	logger's start()
	set thisCaseId to "cliclick-spotCheck"
	logger's infof("Current Coord: {}:{}", getCurrentCoord())
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Unit Test
		Manual: Click on Show Accessory View - Default
		Manual: Click on Show Accessory View - Reset
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	if caseIndex is 1 then
		unitTest()
		
	else
		tell application "System Events" to tell process "Script Editor"
			set sutUi to checkbox 1 of group 1 of group 1 of toolbar 1 of front window
		end tell
		if caseIndex is 2 then
			lclick at sutUi
			
		else if caseIndex is 3 then
			lclick at sutUi with reset
			
		end if
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on clickRelative at theWindow given fromLeft:pLeft : missing value, fromBottom:pBottom : missing value, fromTop:pTop : missing value, fromRight:pRight : missing value
	tell application "System Events"
		tell theWindow -- do not merge with above, it will fail.
			set {x, y} to its position
			set {w, h} to its size
		end tell
	end tell
	
	if pLeft is not missing value then set theX to pLeft + x
	if pBottom is not missing value then
		if y is less than 0 then -- 2nd screen
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
	init()
	
	set origPos to do shell script CLICLICK_CLI & " p:."
	set origPos to textUtil's replace(origPos, "-", "=-")
	
	set calcStart to formatCoordinates(first item of startPos, last item of startPos)
	set calcEnd to formatCoordinates(first item of endPos, last item of endPos)
	
	tell application "System Events"
		-- drag down, drag up, and click.  does not work without the additional click.
		set clickCommand to CLICLICK_CLI & " -e 1 dd:" & calcStart & " du:" & calcEnd & " c:" & calcEnd
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
		set clickCommand to CLICLICK_CLI & " -e 1 dd:" & x1 & "," & y1 & " du:" & x2 & "," & y2 & " c:" & x2 & "," & y2
		-- log clickCommand
		do shell script clickCommand
	end tell
end dragFromTo


(*
	-e is for easing, to make it move human-like, sometimes necessary for some
	UIs to detect and respond to.
*)
on movePointer at theUi
	set coord to getCoord at theUi
	set formattedCoord to formatCoordinates(item 1 of coord, item 2 of coord)
	
	set clickCommand to CLICLICK_CLI & " -e 1 m:" & formattedCoord
	do shell script clickCommand
end movePointer


(*
	-e is for easing, to make it move human-like, sometimes necessary for some
	UIs to detect and respond to.
*)
on moveToXy(x, y)
	set formattedCoord to formatCoordinates(x, y)
	
	set clickCommand to CLICLICK_CLI & " -e 1 m:" & formattedCoord
	do shell script clickCommand
end moveToXy


(*
	-e is for easing, to make it move human-like, sometimes necessary for some
	UIs to detect and respond to.
*)
on rclickAtXy(x, y)
	set formattedCoord to formatCoordinates(x, y)
	set clickCommand to CLICLICK_CLI & " -e 1 rc:" & formattedCoord
	do shell script clickCommand
end rclickAtXy


(*
	-e is for easing, to make it move human-like, sometimes necessary for some
	UIs to detect and respond to.
*)
on lclickAtXy(x, y)
	saveCurrentPosition()
	
	set formattedCoord to formatCoordinates(x, y)
	set clickCommand to CLICLICK_CLI & " -e 1 c:" & formattedCoord
	
	try
		do shell script clickCommand
	end try -- swallow if the command is not present.
	
	restorePosition()
end lclickAtXy

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
on lclick at theUi given reset:resetArg : true, smoothing:smoothingArg : true
	
	-- WARNING: if we don't log these parameters, compile error :tableflip:. 
	-- Seems  it's no longer a problem February 19, 2021
	-- log reset
	-- log smoothing
	
	saveCurrentPosition()
	
	set smoothingParam to ""
	if smoothingArg then set smoothingParam to "-e 1 "
	
	tell application "System Events"
		tell theUi
			set {xPosition, yPosition} to position
			set {xSize, ySize} to size
		end tell
		
		set theYPos to yPosition + (ySize div 2)
		if theYPos is less than 0 then
			set theYPos to "=" & theYPos
		end if
		set clickCommand to CLICLICK_CLI & " " & smoothingParam & "c:" & xPosition + (xSize div 2) & "," & theYPos
		-- logger's debug(clickCommand)
		do shell script clickCommand
	end tell
	
	restorePosition()
end lclick


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
	set formattedCoord to formatCoordinates(item 1 of coord, item 2 of coord)
	set clickCommand to CLICLICK_CLI & " " & smoothingParam & "rc:" & formattedCoord
	do shell script clickCommand
end rclick


(* Used to explicitly save and restore mouse pointer. *)
on saveCurrentPosition()
	set origPos to do shell script CLICLICK_CLI & " p:."
	set origPos to textUtil's replace(origPos, "-", "=-")
	set my savedPosition to origPos
	sessionPlist's setValue("Pointer Position", origPos)
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
	set savedPosition to sessionPlist's getValue("Pointer Position")
	logger's debugf("Restoring pointer to: {}", savedPosition)
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

-- Unit Tests here
on unitTest()
	set utLib to std's import("unit-test")
	set ut to utLib's new()
	tell ut
		newMethod("formatCoordinates")
		-- expected, actual, description
		assertEqual("1,1", my formatCoordinates(1, 1), "Both positive")
		assertEqual("1,=-1", my formatCoordinates(1, -1), "Left positive")
		assertEqual("=-1,1", my formatCoordinates(-1, 1), "Right positive")
		assertEqual("=-1,=-1", my formatCoordinates(-1, -1), "Both negative")
		
		done()
	end tell
end unitTest


(* Changes format to the cliclick recognizable format. *)
on formatCoordinates(x, y)
	if x is less than 0 then set x to "=" & x
	if y is less than 0 then set y to "=" & y
	
	format {"{},{}", {x, y}}
end formatCoordinates


(* Constructor. When you need to load another library, do it here. *)
on init()
	try
		set CLICLICK_CLI to do shell script "plutil -extract \"cliclick CLI\" raw ~/applescript-core/config-system.plist"
	on error
		error "cliclick was not found. Download cli then run make install-cliclick"
	end try
	
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("cliclick")
	set textUtil to std's import("string")
	set plutil to std's import("plutil")'s new()
	set sessionPlist to plutil's new("session")
end init
