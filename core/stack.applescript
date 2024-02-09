(*
	@Project:
		applescript-core

	@Build:
		make build-lib SOURCE=core/stack

	@Last Modified: 2024-02-09 12:19:23
*)
on new()
	set localEmptyStack to {}

	script StackInstance
		property _stack : localEmptyStack

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
