global std, retryLib

(*
	NOTE: For some reason, the "dock" when used as global variable name, appears 
	to be corrupted. That's why I am using "docke" instead.
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()
on spotCheck()
	init()
	set thisCaseId to "dock-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		(Gone) Assign to Desktop 1
		(Gone) Assign to Desktop 2
		(Gone) Assign to All
		(Gone) Assign to None
		New Safari Window
	")
	
	set spotLib to std's import("spot")
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set lib to new()
	set appName to "Script Editor"
	if running of application appName is false then
		activate application appName
		delay 1
	end if
	
	if caseIndex is 1 then
		set assignResult to lib's assignToDesktop(appName, 1)
		
	else if caseIndex is 2 then
		set assignResult to lib's assignToDesktop(appName, 2)
		
	else if caseIndex is 3 then
		set assignResult to lib's assignToDesktop(appName, "all")
		
	else if caseIndex is 4 then
		set assignResult to lib's assignToDesktop(appName, "none")
		
	else if caseIndex is 5 then
		activate application "Safari"
		log lib's newSafariWindow()
		
	end if
	
	if caseIndex is less than 5 then
	logger's debugf("assignResult: {}", assignResult)
	end if
	
	if caseIndex is less than 5 and running of application appName and assignResult is true then
		delay 1.5
		-- Visually verify
		-- tell application "System Events" to key code 53
		tell application "System Events" to tell process "Dock"
			perform action "AXShowMenu" of UI element appName of list 1
			click menu item "Options" of first menu of UI element appName of list 1
		end tell
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	script DockInstance
		
		on newSafariWindow()
			tell application "System Events" to tell process "Dock"
				if not (exists UI element "Safari" of list 1) then return false
				
				perform action "AXShowMenu" of UI element "Safari" of list 1
			end tell
			
			set retry to retryLib's new()
			script MenuWaiter
				tell application "System Events" to tell process "Dock"
					click menu item "New Window" of first menu of UI element "Safari" of list 1
					true
				end tell
			end script
			exec of retry on result for 3
			
			script BlankDocumentWaiter
				tell application "Safari"
					if (source of front document) is "" then return true
				end tell
			end script
			exec of retry on result for 3
		end newSafariWindow
		
		(* @deprecated. No longer available as of December 10, 2022
		@returns false if app is not found in the dock or the menu item is unavailable due to absence of external monitor. *)
		on assignToDesktop(appName, desktopIndex)
			if class of desktopIndex is integer then
				set subMenuName to "Desktop on Display " & desktopIndex
				
			else if desktopIndex is "all" then
				set subMenuName to "All Desktops"
				
			else if desktopIndex is "none" then
				set subMenuName to "None"
				
			end if
			
			tell application "System Events" to tell process "Dock"
				if not (exists UI element appName of list 1) then return false
				
				perform action "AXShowMenu" of UI element appName of list 1
				delay 0.1 -- Intermittently fails without this.
				click menu item "Options" of first menu of UI element appName of list 1
				delay 0.1
				try
					click menu item subMenuName of menu 1 of menu item "Options" of first menu of UI element appName of list 1
				on error
					key code 53
					return false
				end try
			end tell
			true
		end assignToDesktop
	end script
end newInstance


-- Private Codes below =======================================================

(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("dock")
	set retryLib to std's import("retry")
end init
