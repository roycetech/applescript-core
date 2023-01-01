global std

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "stack-spotCheck"
	logger's start()
	
	unitTest()
	
	logger's finish()
end spotCheck


on new()
	script StackInstance
		property _stack : {}
		
		on clear()
			set my _stack to {}
		end clear
		
		on getSize()
			number of items of _stack
		end getSize
		
		on push(element)
			set end of _stack to element
		end push
		
		on peek()
			if _stack is {} then return missing value
			
			last item of _stack
		end peek
		
		on pop()
			if _stack is {} then return missing value
			
			set lastItem to last item of _stack
			if number of _stack is less than 2 then
				set _stack to {}
			else
				set _stack to items 1 thru -2 of _stack
			end if
			lastItem
		end pop
	end script
end new


-- Private Codes below =======================================================

(*
	Handler grouped by hundredths.
	Put the case you are debugging at the top, and move to correct place once verified.
*)
on unitTest()
	set utLib to std's import("unit-test")
	set ut to utLib's new()
	
	set stack to new()
	
	tell ut
		newMethod("getSize")
		assertEqual(0, stack's getSize(), "Initial")
		stack's push("test 1")
		assertEqual(1, stack's getSize(), "After adding an element")
		stack's pop()
		assertEqual(0, stack's getSize(), "After removing the single element")
		
		newMethod("peek")
		set sutPeek to new()
		assertEqual(missing value, stack's peek(), "Initial")
		stack's push("test 2")
		assertEqual("test 2", stack's peek(), "After pushing a value")
		stack's pop()
		assertEqual(missing value, stack's peek(), "After popping the only value")
		
		ut's done()
	end tell
end unitTest


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("stack")
end init
