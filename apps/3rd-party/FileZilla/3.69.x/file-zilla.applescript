(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/FileZilla/3.69.x/file-zilla

	@Created: Wednesday, January 15, 2025 at 9:46:35 AM
	@Last Modified: 2025-05-17 07:39:10
*)

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Reconnect Latest
		Manual: Set host
		Manual: Set username
		Manual: Set password

		Manual: Connect
		Manual: Disconnect
		Manual: Files pane: Scroll to top
		Manual: Files pane: Scroll to bottom
		Manual: Directories pane: Scroll to top

		Manual: Directories pane: Scroll to bottom
		Manual: triggerQuickConnect
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
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's reconnectlatest()
		
	else if caseIndex is 3 then
		set sutHost to "spot"
		
		sut's setHost(sutHost)
		
	else if caseIndex is 4 then
		set sutUsername to "fruit"
		
		sut's setHost(sutUsername)
		
	else if caseIndex is 5 then
		set sutPassword to "incorrect"
		
		sut's setPassword(sutPassword)
		
	else if caseIndex is 6 then
		
		-- sut's connect("127.0.0.1", missing value, missing value)  -- Commit this empty credentials, NOT THE ACTUAL VALUES!
		
	else if caseIndex is 7 then
		sut's disconnect()
		
	else if caseIndex is 8 then
		sut's scrollFilesPaneToTop()
		
	else if caseIndex is 9 then
		sut's scrollFilesPaneToBottom()
		
	else if caseIndex is 10 then
		sut's scrollDirectoryPaneToTop()
		
	else if caseIndex is 11 then
		sut's scrollDirectoryPaneToBottom()

	else if caseIndex is 12 then
		sut's triggerQuickConnect()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	
	script FileZillaInstance
		on connect(host, username, password)
			if running of application "FileZilla" is false then return
			
			setHost(host)
			if username is not missing value then
				setUsername(username)
			end if
			
			if password is not missing value then
				setPassword(password)
			end if
			
			triggerQuickConnect()
		end connect
		
		
		on scrollDirectoryPaneToTop()
			if running of application "FileZilla" is false then return
			
			tell application "System Events" to tell process "FileZilla"
				try
					set value of value indicator 1 of scroll bar 5 of front window to 0
				end try
			end tell
			
		end scrollDirectoryPaneToTop
		
		
		on scrollDirectoryPaneToBottom()
			if running of application "FileZilla" is false then return
			
			tell application "System Events" to tell process "FileZilla"
				try
					set value of value indicator 1 of scroll bar 5 of front window to 1
				end try
			end tell
		end scrollDirectoryPaneToBottom
		
		
		on scrollFilesPaneToTop()
			if running of application "FileZilla" is false then return
			
			tell application "System Events" to tell process "FileZilla"
				try
					set value of value indicator 1 of scroll bar 6 of front window to 0
				end try
			end tell
		end scrollFilesPaneToTop
		
		
		on scrollFilesPaneToBottom()
			if running of application "FileZilla" is false then return
			
			tell application "System Events" to tell process "FileZilla"
				try
					set value of value indicator 1 of scroll bar 6 of front window to 1
				end try
			end tell
		end scrollFilesPaneToBottom
		
		
		on disconnect()
			if running of application "FileZilla" is false then return
			
			tell application "System Events" to tell process "FileZilla"
				try
					click menu item "Disconnect" of menu 1 of menu bar item "Server" of menu bar 1
				end try
			end tell
		end disconnect
		
		
		on setHost(host)
			if running of application "FileZilla" is false then return
			
			if host does not start with "sftp://" then set host to "sftp://" & host
			tell application "System Events" to tell process "FileZilla"
				set value of text field 1 of my _getMainWindow() to host
			end tell
		end setHost
		
		
		on setUsername(username)
			if running of application "FileZilla" is false then return
			
			tell application "System Events" to tell process "FileZilla"
				set value of text field 2 of my _getMainWindow() to username
			end tell
		end setUsername
		
		
		on setPassword(password)
			if running of application "FileZilla" is false then return
			
			tell application "System Events" to tell process "FileZilla"
				set value of text field 3 of my _getMainWindow() to password
			end tell
		end setPassword
		
		
		on triggerQuickConnect()
			if running of application "FileZilla" is false then return
			
			tell application "System Events" to tell process "FileZilla"
				click button "Quickconnect" of my _getMainWindow()
			end tell
		end triggerQuickConnect
		
		
		on reconnectlatest()
			if running of application "FileZilla" is false then return
			
			tell application "System Events" to tell process "FileZilla"
				set quickConnectDropdown to button 2 of my _getMainWindow()
				click quickConnectDropdown
				delay 0.1
				try
					click menu item 4 of menu 1 of quickConnectDropdown
				end try
			end tell
		end reconnectlatest
		
		
		on _getMainWindow()
			if running of application "FileZilla" is false then return
			
			tell application "System Events" to tell process "FileZilla"
				try
					return first window whose title is not "Settings"
				end try
			end tell
			
			missing value
		end _getMainWindow
	end script
end new
