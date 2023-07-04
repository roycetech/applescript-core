(*
	@Usage:
		use kbLib : script "keyboard"
	Or type (Text Expander): uuse kb
	
	@Build:
		make compile-lib SOURCE=core/keyboard
*)

use script "Core Text Utilities"
use scripting additions

use AppleScript version "2.4"
use framework "Foundation"
use framework "AppKit" -- for NSEvent

-- classes, constants, and enums used
property NSControlKeyMask : a reference to 262144
property NSAlternateKeyMask : a reference to 524288
property NSShiftKeyMask : a reference to 131072
property NSCommandKeyMask : a reference to 1048576
property NSEvent : a reference to current application's NSEvent

use std : script "std"

use loggerFactory : script "logger-factory"
use plutilLib : script "plutil"
use listUtil : script "list"
use emoji : script "emoji"
use spotScript : script "spot-test"
use overriderLib : script "overrider"

property logger : missing value
property session : missing value

property overrider : overriderLib's new()

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me, "keyboard")
	
	set caseId to "keyboard-spotCheck"
	logger's start()
	
	-- All spot check cases are manual.
	set cases to listUtil's splitByLine("
		Manual Checks
		Paste Text with Emoji
		Manual: Modifier Pressed
	")
	
	
	set spotLib to spotScript's new()
	set spot to spotLib's new(caseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	
	set sut to new()
	tell sut
		if caseIndex is 1 then
			pressKey(0)
			pressKey(1)
			pressKey(2)
			pressKey(3)
			pressKey(4)
			pressKey(5)
			pressKey(6)
			pressKey(7)
			pressKey(8)
			pressKey(9)
			(*
		
		pressKey("a")
		pressKey("b")
		pressKey("c")
		pressKey("d")
		pressKey("e")
		pressKey("f")
		pressKey("g")
		pressKey("h")
		pressKey("i")
		pressKey("j")
		pressKey("k")
		pressKey("l")
		pressKey("m")
		pressKey("n")
		pressKey("o")
		pressKey("p")
		pressKey("q")
		pressKey("r")
		pressKey("s")
		pressKey("t")
		pressKey("u")
		pressKey("v")
		pressKey("w")
		pressKey("x")
		pressKey("y")
		pressKey("z")
	*)
			activate application "Terminal"
			delay 0.1
			pressControlKey("c")
			
		else if caseIndex is 2 then
			insertTextByPasting("Hello " & emoji's HORN)
			
		else if caseIndex is 3 then
			delay 1
			logger's infof("Option Pressed: {}", checkModifier("option"))
			logger's infof("Shift Pressed: {}", checkModifier("shift"))
			logger's infof("Command Pressed: {}", checkModifier("command"))
			
		end if
		
	end tell
	
	(* Output will vary depending on current system keyboard layout. *)
	-- Cursor inside bracket: [] -- Manually erase the contents each time
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's inject(me, "keyboard")
	set plutil to plutilLib's new()
	set session to plutil's new("session")
	
	script KeyboardInstance
		on checkModifier(keyName)
			if keyName = "option" then
				set theMask to NSAlternateKeyMask
			else if keyName = "control" then
				set theMask to NSControlKeyMask
			else if keyName = "command" then
				set theMask to NSCommandKeyMask
			else if keyName = "shift" then
				set theMask to NSShiftKeyMask
			else
				return false
			end if
			set theFlag to NSEvent's modifierFlags() as integer
			if ((theFlag div theMask) mod 2) = 0 then
				return false
			else
				return true
			end if
		end checkModifier
		
		on modifiersDown()
			set theKeys to {}
			set theFlag to NSEvent's modifierFlags() as integer
			if ((theFlag div NSAlternateKeyMask) mod 2) is not 0 then
				set end of theKeys to "option"
			end if
			if ((theFlag div NSControlKeyMask) mod 2) is not 0 then
				set end of theKeys to "control"
			end if
			if ((theFlag div NSCommandKeyMask) mod 2) is not 0 then
				set end of theKeys to "command"
			end if
			if ((theFlag div NSShiftKeyMask) mod 2) is not 0 then
				set end of theKeys to "shift"
			end if
			return theKeys
		end modifiersDown
		
		on isDvorak()
			getLayout() contains "DVORAK"
		end isDvorak
		
		on getLayout()
			do shell script "defaults read ~/Library/Preferences/com.apple.HIToolbox.plist \\
 AppleSelectedInputSources | \\
 egrep -w 'KeyboardLayout Name' | sed -E 's/^.+ = \"?([^\"]+)\"?;$/\\1/'"
		end getLayout
		
		
		on pressKey(keyToPress)
			tell application "System Events"
				key code my _charToKeycode(keyToPress)
			end tell
			delay 0.01
		end pressKey
		
		
		on pressCommandKey(keyToPress)
			tell application "System Events"
				key code my _charToKeycode(keyToPress) using {command down}
			end tell
			delay 0.01
		end pressCommandKey
		
		
		on pressCommandControlKey(keyToPress)
			tell application "System Events"
				key code my _charToKeycode(keyToPress) using {command down, control down}
			end tell
			delay 0.01
			
		end pressCommandControlKey
		
		on pressCommandShiftKey(keyToPress)
			tell application "System Events"
				key code my _charToKeycode(keyToPress) using {command down, shift down}
			end tell
			delay 0.01
		end pressCommandShiftKey
		
		on pressCommandOptionKey(keyToPress)
			tell application "System Events"
				key code my _charToKeycode(keyToPress) using {command down, option down}
			end tell
			delay 0.01
		end pressCommandOptionKey
		
		on pressControlKey(keyToPress)
			tell application "System Events"
				key code my _charToKeycode(keyToPress) using {control down}
			end tell
			delay 0.01
		end pressControlKey
		
		on pressControlShiftKey(keyToPress)
			tell application "System Events"
				key code my _charToKeycode(keyToPress) using {control down, shift down}
			end tell
			delay 0.01
		end pressControlShiftKey
		
		on pressOptionKey(keyToPress)
			tell application "System Events"
				key code my _charToKeycode(keyToPress) using {option down}
			end tell
			delay 0.01
		end pressOptionKey
		
		on typeText(theText)
			tell application "System Events" to keystroke theText
			delay 0.01
		end typeText
		
		(* To test. *)
		on insertTextByPasting(theText)
			try
				set origClipboard to the clipboard
			on error
				set origClipboard to ""
			end try
			
			try
				repeat
					set the clipboard to theText
					delay 0.2
					if (the clipboard) is equal to theText then
						logger's debugf("The clipboard now equal to text to paste: {}", the clipboard)
						exit repeat
					end if
				end repeat
				
				pressCommandKey("v") -- There's issue where incorrect value is 
				-- getting pasted. We could be restoring the orig value too soon.
				delay 0.1 -- Increase the value if failure is still encountered.
				set the clipboard to origClipboard
			on error
				set the clipboard to origClipboard
				typeText(theText)
			end try
		end insertTextByPasting
	end script
	overrider's applyMappedOverride(result)
end new



-- Private Codes below =======================================================
on _charToKeycode(key)
	if key is "A" or key is "a" then return 0
	if key is "B" or key is "b" then return 11
	if key is "C" or key is "c" then return 8
	if key is "D" or key is "d" then return 2
	if key is "E" or key is "e" then return 14
	if key is "F" or key is "f" then return 3
	if key is "G" or key is "g" then return 5
	if key is "H" or key is "h" then return 4
	if key is "I" or key is "i" then return 34
	if key is "J" or key is "j" then return 38
	if key is "K" or key is "k" then return 40
	if key is "L" or key is "l" then return 37
	if key is "M" or key is "m" then return 46
	if key is "N" or key is "n" then return 45
	if key is "O" or key is "o" then return 31
	if key is "P" or key is "p" then return 35
	if key is "Q" or key is "q" then return 12
	if key is "R" or key is "r" then return 15
	if key is "S" or key is "s" then return 1
	if key is "T" or key is "t" then return 17
	if key is "U" or key is "u" then return 32
	if key is "V" or key is "v" then return 9
	if key is "W" or key is "w" then return 13
	if key is "X" or key is "x" then return 7
	if key is "Y" or key is "y" then return 16
	if key is "Z" or key is "z" then return 6
	
	if key as text is "0" then return 29
	if key as text is "1" then return 18
	if key as text is "2" then return 19
	if key as text is "3" then return 20
	if key as text is "4" then return 21
	if key as text is "5" then return 23
	if key as text is "6" then return 22
	if key as text is "7" then return 26
	if key as text is "8" then return 28
	if key as text is "9" then return 25
	
	if key is space then return 49
	if key is "[" then return 33
	if key is "]" then return 30
	if key is "/" then return 44
	if key is "\\" then return 42
	if key is "-" then return 27
	if key is "=" then return 24
	if key is "`" then return 50
	if key is "\"" then return 39
	
	if key is tab or key is "tab" then return 48
	if (ASCII number key) is 10 or key is "enter" then return 76
	if (ASCII number key) is 13 or key is "return" then return 36
	
	if key is "esc" then return 53
	if key is "escape" then return 53
	if key is "delete" then return 51
	if key is "del" then return 51
	if key is "space" then return 49
	if key is " " then return 49
	if key is "up" then return 126
	if key is "down" then return 125
	if key is "left" then return 123
	if key is "right" then return 124
	
	if key is "F1" or key is "f1" then return 122
	if key is "F2" or key is "f2" then return 120
	if key is "F3" or key is "f3" then return 99
	if key is "F4" or key is "f4" then return 118
	if key is "F5" or key is "f5" then return 96
	if key is "F6" or key is "f6" then return 97
	if key is "F7" or key is "f7" then return 98
	if key is "F8" or key is "f8" then return 100
	if key is "F9" or key is "f9" then return 101
	if key is "F10" or key is "f10" then return 109
	if key is "F11" or key is "f11" then return 103
	if key is "F12" or key is "f12" then return 111
	
	-1
end _charToKeycode
-- EOS
