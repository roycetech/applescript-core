global std

use script "Core Text Utilities"
use scripting additions

(*
	Compile:
		make install-dvorak
	
	Usage:
		set kb to std's import("keyboard")'s new()
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set caseId to "dec-keyboard-dvorak-cmd-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	-- All spot check cases are manual.
	set cases to listUtil's splitByLine("
		Manual: pressKey (dvorak/us input);
		Manual: pressControlKey (dvorak/us input);
		Manual: pressCommandKey (dvorak/us input);
		Manual: Type Text (dvorak/us input);
	")
	
	set spotLib to std's import("spot")'s new()
	set spot to spotLib's new(caseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	
	set sut to std's import("keyboard")'s new()
	if name of sut is not "KeyboardDvorakCmd" then set sut to decorate(sut)
	
	if caseIndex is 1 then
		tell sut
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
			-- Put cursor inside bracket: []
		end tell
		
	else if caseIndex is 2 then
		activate application "Terminal"
		delay 0.1
		tell sut to pressControlKey("c")
		
	else if caseIndex is 3 then
		tell sut to pressCommandKey("s")
		
	else if caseIndex is 4 then
		tell sut to typeText("hello")
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on decorate(baseScript)
	script KeyboardDvorakCmdInstance
		property parent : baseScript
		
		on pressKey(keyToPress)
			if not isDvorak() then
				continue pressKey(keyToPress)
				return
			end if
			
			set dvorakKey to _toDvorak(keyToPress)
			continue pressKey(dvorakKey)
		end pressKey
		
		on pressControlKey(keyToPress)
			if not isDvorak() then
				continue pressControlKey(keyToPress)
				return
			end if
			
			set dvorakKey to _toDvorak(keyToPress)
			continue pressControlKey(dvorakKey)
		end pressControlKey
		
		
		on typeText(theText)
			tell application "System Events" to keystroke theText
			delay 0.01
		end typeText
		
		
		on _toDvorak(char)
			if char is "b" then return "n"
			if char is "c" then return "i"
			if char is "d" then return "h"
			if char is "e" then return "d"
			if char is "f" then return "y"
			if char is "g" then return "u"
			if char is "h" then return "j"
			if char is "i" then return "g"
			if char is "j" then return "c"
			if char is "k" then return "v"
			if char is "l" then return "p"
			if char is "n" then return "l"
			if char is "o" then return "s"
			if char is "p" then return "r"
			if char is "q" then return "'x"
			if char is "r" then return "o"
			if char is "s" then return ";"
			if char is "t" then return "k"
			if char is "u" then return "f"
			if char is "v" then return "."
			if char is "w" then return ","
			if char is "x" then return "b"
			if char is "y" then return "t"
			if char is "z" then return "/"
			if char is "-" then return "'"
			if char is "=" then return "]"
			if char is "[" then return "-"
			if char is "]" then return "="
			if char is ";" then return "z"
			if char is "'" then return "q"
			if char is "," then return "w"
			if char is "." then return "e"
			if char is "/" then return "["
			
			char
		end _toDvorak
	end script
end decorate


on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("dec-keyboard-dvorak-cmd")
end init

-- EOS