global std

(*
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "idler-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	set cases to listUtil's splitByLine("
		Manual: Idle for seconds
		Manual: Is Idle
		Manual: Idle in seconds
	")
	
	set spotLib to std's import("spot")
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sutThreshold to 2
	set sut to new(sutThreshold)
	if caseIndex is 1 then
		log sut's isIdleFor(1)
		delay 2
		log sut's isIdleFor(1)
		
	else if caseIndex is 2 then
		log sut's isIdle() -- false
		delay 1
		log sut's isIdle() -- still false
		delay 1
		log sut's isIdle() -- true
		
	else if caseIndex is 3 then
		log sut's idleInSeconds()
		delay 1.5
		log sut's idleInSeconds()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new(pAwayThresholdSeconds)
	script IdlerInstance
		property awayThresholdSeconds : pAwayThresholdSeconds
		
		on isIdleFor(threshold)
			idleInSeconds() is greater than threshold
		end isIdleFor
		
		on isIdle()
			isIdleFor(awayThresholdSeconds)
		end isIdle
		
		(* Very lightweight operation, you may invoke as frequently as you like. *)
		on idleInSeconds()
			do shell script "ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print $NF/1000000000; exit}'"
			result as real
		end idleInSeconds
	end script
end new


to init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("idler")
end init
