(*
	@Testing:
		Have a valid connection created with name: Docker MySQL 5
		A database called "crm" must exist
		A table called customers must exist.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Sequel Ace/4.0.x/sequel-ace'

	@Last Modified: August 18, 2023 9:27 AM
	@Change Logs:
		August 18, 2023 9:28 AM - update switchView to use only menus as the last resort so that app focus is not always required.

*)

use scripting additions

use listUtil : script "core/list"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"
use retryLib : script "core/retry"
use syseveLib : script "core/system-events"
use kbLib : script "core/keyboard"

use decoratorLib : script "core/decorator"

property logger : missing value
property retry : missing value
property syseve : missing value
property kb : missing value

property TEST_CONNECTION_NAME : "Docker MySQL 5"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()
	
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		INFO
		Manual: New Tab
		Manual: Get Front Tab
		Manual: Find Tab - Not Found, Found and Focus
		Manual: Find Table (DB not selected, selected)		
		Manual: Switch to Query
		
		Manual: Is Connected? (Connection Tab/Connected tab)
		Manual: Get Selected Text (Connection Tab, Non-Query Tab, None, Selected)			
		Manual: Get Editor Text (Connection Tab, Non-Query Tab, None, With Text)	
		Manual: Is Table Selected (Connection Tab, DB Not Selected, Table Not Selected, Happy)	
		Manual: Run Query
		
		Manual: Current Info (Connection Tab, DB Not Selected, Table Not Selected, Happy)
		Manual: Apply Filters
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()

		set sutTab to sut's getFrontTab()
		logger's infof("Tab Name: {}", name of appWindow of sutTab as text)
		
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		set sutTab to sut's newTab(TEST_CONNECTION_NAME)
		
	else if caseIndex is 2 then
		
	else if caseIndex is 3 then
		set sut to sut's findTab(TEST_CONNECTION_NAME, "")
		if sut is missing value then
			logger's info("Tab was not found")
		else
			logger's info("Tab was found")
			sut's focus()
		end if
		
	else if caseIndex is 4 then
		logger's debugf("TEST_CONNECTION_NAME: {}", TEST_CONNECTION_NAME)
		set sut to sut's findTab(TEST_CONNECTION_NAME, "crm")
		assertThat of std given condition:sut is not missing value, messageOnFail:"Test Connection was not found"
		assertThat of std given condition:sut's findTable("phones") is false, messageOnFail:"Expected non existing phones table was found instead."
		assertThat of std given condition:sut's findTable("customers") is true, messageOnFail:"Expected existing customers table was not found."
		
	else if caseIndex is 5 then
		set sutTab to sut's getFrontTab()
		sutTab's switchTab("Query")
		sutTab's switchTab("Content")
		
		
	else if caseIndex is 6 then
		set frontTab to sut's getFrontTab()
		logger's infof("Is Connected: {}", frontTab's isConnected())
		
	else if caseIndex is 7 then
		set frontTab to sut's getFrontTab()
		logger's infof("Selected Text: {}", frontTab's getSelectedText())
		
	else if caseIndex is 8 then
		set frontTab to sut's getFrontTab()
		logger's infof("Editor Text: {}", frontTab's getEditorText())
		
	else if caseIndex is 9 then
		set frontTab to sut's getFrontTab()
		logger's infof("Is Table Selected: {}", frontTab's isTableSelected())
		
	else if caseIndex is 10 then
		set frontTab to sut's getFrontTab()
		frontTab's runQuery("SELECT '" & (current date) & "'")
		
	else if caseIndex is 11 then
		set frontTab to sut's getFrontTab()
		logger's infof("Connection Name: {}", frontTab's getConnectionName())
		logger's infof("Database Name: {}", frontTab's getDatabaseName())
		logger's infof("Table Name: {}", frontTab's getTableName())
		
	else if caseIndex is 13 then
		tell application "System Events" to tell process "Sequel Ace"
			-- set frontmost to true
			click button "Apply Filter(s)" of group 1 of splitter group 1 of front window
		end tell
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck

on new()
	loggerFactory's injectBasic(me)
	
	set retry to retryLib's new()
	set syseve to syseveLib's new()
	set kb to kbLib's new()
	
	script SequelAceInstance
		(*  *)
		on findTab(connectionName, databaseAndOrTable)
			if running of application "Sequel Ace" is false then return missing value
			
			set titleKey to connectionName
			if databaseAndOrTable is not missing value and length of databaseAndOrTable is greater than 0 then set titleKey to titleKey & "/" & databaseAndOrTable
			logger's debugf("titleKey: {}", titleKey)
			
			tell application "System Events" to tell process "Sequel Ace"
				if (count of windows) is 0 then return missing value
				
				set frontWindowTitle to get title of front window
				logger's debugf("frontWindowTitle: {}", frontWindowTitle)
				if frontWindowTitle ends with titleKey then return my getFrontTab()
				
				if not (exists tab group "tab bar" of front window) then return missing value
				
				repeat with nextTab in radio buttons of tab group "tab bar" of front window
					set nextTabTitle to get title of nextTab
					logger's debugf("nextTabTitle: {}", nextTabTitle)
					if nextTabTitle ends with titleKey then
						click nextTab
						return my getFrontTab()
					end if
				end repeat
			end tell
			missing value
		end findTab
		
		
		on getFrontTab()
			if running of application "Sequel Ace" is false then return missing value
			
			tell application "Sequel Ace" to set frontWindow to front window
			new(frontWindow)
		end getFrontTab
		
		
		on newTab(connectionName)
			if running of application "Sequel Ace" is false then activate application "Sequel Ace"
			
			set frontTab to getFrontTab()
			if frontTab's isConnected() then
				tell application "System Events" to tell process "Sequel Ace"
					try
						click menu item "New Connection Tab" of menu 1 of menu bar item "File" of menu bar 1
					end try
					delay 1
				end tell
			end if
			
			tell application "System Events" to tell process "Sequel Ace"
				repeat with nextConnection in rows of outline 1 of scroll area 1 of splitter group 1 of front window
					try
						if get value of text field 1 of nextConnection is connectionName then
							set selected of nextConnection to true
							exit repeat
						end if
					end try -- text field don't exist
				end repeat
				click button "Connect" of scroll area 2 of splitter group 1 of front window
				delay 0.1
			end tell
			
			set frontTab to getFrontTab()
			repeat until frontTab's isConnected()
				delay 0.5
			end repeat
			delay 2 -- UI takes some time to refresh
			
			frontTab
		end newTab
		
		on new(pAppWindow)
			script SequelAceTabInstance
				property appWindow : pAppWindow -- non-sysEveWindow
				
				
				on setDatabase(databaseName)
					-- TODO
				end setDatabase
				
				(*
					@returns the list consisting of connection, database, and table names. Database and table name may not be available at a given time.  Missing value if both database and table names could not be derived from the window name.
				*)
				on _getIdentifierTokens()
					set windowName to the name of appWindow
					-- logger's debugf("windowName: {}", windowName)
					if windowName is equal to "Sequel Ace" then return missing value
					
					tell application "System Events" to tell process "Sequel Ace"
						try
							if (value of pop up button 1 of group 1 of toolbar 1 of my getSysEveWindow() as text) starts with "Choose database" then
								return missing value
							end if
						end try
					end tell
					
					set nameSpacedTokens to textUtil's split(windowName, " ")
					if the (count of items in nameSpacedTokens) is less than 2 then return missing value
					
					textUtil's split(last item of nameSpacedTokens, "/")
				end _getIdentifierTokens
				
				on getConnectionName()
					set tokens to _getIdentifierTokens()
					if tokens is missing value then return missing value
					
					first item of tokens
				end getConnectionName
				
				on getDatabaseName()
					set tokens to _getIdentifierTokens()
					if tokens is missing value then return missing value
					
					return 2nd item of tokens
				end getDatabaseName
				
				on getTableName()
					set tokens to _getIdentifierTokens()
					if tokens is missing value then return missing value
					if the (count of items in tokens) is less than 3 then return missing value
					
					last item of tokens
				end getTableName
				
				on isTableSelected()
					set windowName to name of appWindow
					set nameTokens to listUtil's split(windowName, "/")
					(the number of nameTokens) is greater than 2
				end isTableSelected
				
				on getEditorText()
					if running of application "Sequel Ace" is false then return missing value
					
					tell application "System Events" to tell process "Sequel Ace"
						try
							set editorText to value of text area 1 of scroll area 1 of splitter group 1 of splitter group 1 of group 1 of splitter group 1 of window (name of my appWindow)
							if editorText is "" then return missing value
							return editorText
						end try -- Wrong tab
					end tell
					
					missing value
				end getEditorText
				
				
				on getSelectedText()
					if running of application "Sequel Ace" is false then return
					switchTab("Query")
					
					tell application "System Events" to tell process "Sequel Ace"
						try
							set selectedStatement to value of attribute "AXSelectedText" of text area 1 of scroll area 1 of splitter group 1 of splitter group 1 of group 1 of splitter group 1 of front window
							if selectedStatement is "" then return missing value
						on error -- when connection tab is focused
							return missing value
						end try
						
						return selectedStatement
					end tell
				end getSelectedText
				
				
				(* Warning: Uses key press to run the query, so maintain focus as needed. *)
				on runQuery(sqlStatement)
					if running of application "Sequel Ace" is false then return
					if isConnected() is false then return
					
					tell application "System Events" to tell process "Sequel Ace"
						set value of text area 1 of scroll area 1 of splitter group 1 of splitter group 1 of group 1 of splitter group 1 of window (name of my appWindow) to sqlStatement
						delay 0.1
						perform action "AXShowMenu" of (first menu button of splitter group 1 of splitter group 1 of group 1 of splitter group 1 of window (name of my appWindow) whose title starts with "Run")
					end tell
					
					kb's pressKey("down")
					kb's pressKey("down") -- Run All Queries
					kb's pressKey("enter")
				end runQuery
				
				
				on connectByName(targetConnectionName)
					if running of application "Sequel Ace" is false then return
					
					tell application "System Events" to tell process "Sequel Ace"
						set desiredConnection to missing value
						repeat with nextRow in rows of outline 1 of scroll area 1 of splitter group 1 of window "Sequel Ace"
							try
								set nextConnectionName to value of text field 1 of nextRow
								if nextConnectionName contains targetConnectionName then
									set desiredConnection to nextRow
									exit repeat
								end if
							end try -- Fail on folder row
						end repeat
						if nextRow is not missing value then
							set selected of nextRow to true
							click button "Connect" of scroll area 2 of splitter group 1 of window "Sequel Ace"
							delay 1
						end if
					end tell
				end connectByName
				
				
				on focus()
					if running of application "Sequel Ace" is false then return
					
					tell application "System Events" to tell process "Sequel Ace"
						try
							click (first menu item of first menu of menu bar item "Window" of first menu bar whose title is equal to name of my appWindow)
						on error
							return false
						end try
					end tell
				end focus
				
				
				on isConnected()
					if running of application "Sequel Ace" is false then return false
					
					focus()
					
					tell application "System Events" to tell process "Sequel Ace"
						if (count of windows) is 0 then return false
						
						not (exists button "Connect" of scroll area 2 of splitter group 1 of window "Sequel Ace") and name of front window does not start with "Connecting"
					end tell
				end isConnected
				
				
				(* @returns true if the table is found. *)
				on findTable(targetTableName)
					script WaitTableSearch
						tell application "System Events" to tell process "Sequel Ace"
							if exists text field 1 of splitter group 1 of splitter group 1 of front window then return true
						end tell
					end script
					exec of retry on result for 5 by 1
					
					tell application "System Events" to tell process "Sequel Ace"
						-- Filter by Table Name. Broken because UI was updated, and the update was automatic!
						-- click button 2 of text field 1 of splitter group 1 of splitter group 1 of front window
						set value of text field 1 of splitter group 1 of splitter group 1 of front window to targetTableName
						-- click button 1 of text field 1 of splitter group 1 of splitter group 1 of front window
						
						-- Select the Table based on name
						repeat with nextTable in rows of table 1 of scroll area 1 of splitter group 1 of splitter group 1 of front window
							if get value of text field 1 of nextTable is equal to targetTableName then
								set selected of nextTable to true
								return true
								exit repeat
							end if
						end repeat
					end tell
					false
				end findTable
				
				
				(*
					@Deprecated - use switch view instead.
					@tabName - Structure, Content, Query, etc.
				*)
				on switchTab(tabName)
					if tabName is not equal to "Query" and isTableSelected() is false then
						logger's warn("Table must be selected")
						beep 1
						return
					end if
					
					tell application "System Events" to tell process "Sequel Ace"
						try
							click button tabName of toolbar 1 of front window
						end try -- when button is not visible on small windows, for example the query.
					end tell
				end switchTab
				
				(*
					Switches the current view between Query, Contents, Structure etc. Use the menu
					item name for better reliability because some UI elements are hidden when the
					window is shrunk.
				*)
				on switchView(viewName)
					if running of application "Sequel Ace" is false then return false
					
					tell application "System Events" to tell process "Sequel Ace"
						try
							click button viewName of toolbar 1 of front window
						on error
							if viewName is "Query" then set viewName to "Custom Query"
							try
								tell application "Sequel Ace" to activate
								click menu item viewName of menu 1 of menu bar item "View" of menu bar 1
							end try
						end try
					end tell
				end switchView
				
				on getSysEveWindow()
					tell application "System Events" to tell process "Sequel Ace"
						window (name of my appWindow)
					end tell
				end getSysEveWindow
			end script
			set decoratorInner to decoratorLib's new(result)
			decoratorInner's decorate()
		end new
	end script
	
	set decoratorOuter to decoratorLib's new(result)
	decoratorOuter's decorate()
end new

