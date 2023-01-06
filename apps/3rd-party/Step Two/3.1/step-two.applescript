global std, textUtil
global APP_NAME

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "step-two-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Manual: Filter(Found, Empty)
		Manual: Get OTP (Empty, Non-Empty)
	")
	
	set spotLib to std's import("spot")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	if caseIndex is 1 then
		-- sut's filter("xxx")
		sut's filter("VPN")
		
	else if caseIndex is 2 then
		logger's debugf("OTP: {}", sut's getFirstOTP())
		
	end if
	
	spot's finish()
	
	logger's finish()
end spotCheck


(*  *)
on new()
	if std's appExists("Step Two") is false then error "Step Two app was not found"
	
	
	script LibraryInstance
		on filter(filterKey)
			if running of application APP_NAME is false then return
			
			tell application "System Events" to tell process "Step Two"
				set value of text field 1 of window "Step Two" to filterKey
			end tell
		end filter
		
		on getFirstOTP()
			if running of application APP_NAME is false then return missing value
			
			tell application "System Events" to tell process "Step Two"
				try
					first UI element of group 1 of list 1 of list 1 of scroll area 1 of window "Step Two" whose description starts with "AmaysimVPN"
					set tokens to textUtil's split(description of result as text, ",")
				on error
					return missing value
				end try
			end tell
			
			textUtil's replace(last item of tokens, " ", "")
		end getFirstOTP
	end script
end new


-- Private Codes below =======================================================

(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("step-two")
	set textUtil to std's import("string")
	
	set APP_NAME to "Step Two"
end init
