(*
	Refactored out of sequel-ace.applescript

	@Testing:
		Have a valid connection created with name: Docker MySQL 5
		A database called "crm" must exist
		A table called customers must exist.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Sequel Ace/4.1.x/sequel-ace-tab'

	@Created: Sun, Oct 27, 2024 at 1:03:15 PM
	@Last Modified: Sun, Oct 27, 2024 at 1:03:12 PM
	@Change Logs:
		
	WIP
*)

use scripting additions

use listUtil : script "core/list"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"
use syseveLib : script "core/system-events"
use kbLib : script "core/keyboard"
use processLib : script "core/process"

use decoratorLib : script "core/decorator"

property logger : missing value
property retry : missing value
property syseve : missing value
property kb : missing value

property TEST_CONNECTION_NAME : "MySQL5 Docker"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()
	
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		INFO
		Manual: Switch to Query
		Manual: Run Query
		
		Manual: Current Info (Connection Tab, DB Not Selected, Table Not Selected, Happy)
		Manual: Apply Filters
	")
	
	set sequelAceLib to script "core/sequel-ace"
	set sequelAce to sequelAceLib's new()
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	
	tell application "Sequel Ace"
		set sut to my new(front window)
	end tell
	
	(* 
		Check cases:
			Connection Tab
			DB Not Selected
			Table Not Selected
			Happy
	*)
	logger's infof("Is connected: {}", sut's isConnected())
	logger's infof("Tab Name: {}", name of appWindow of sut as text)
	logger's debugf("Identifier tokens: {}", sut's _getIdentifierTokens())
	logger's infof("Connection Name: {}", sut's getConnectionName())
	logger's infof("Database Name: {}", sut's getDatabaseName())
	logger's infof("Table Name: {}", sut's getTableName())
	logger's infof("Is table selected: {}", sut's isTableSelected())
	logger's infof("Editor text: {}", sut's getEditorText())
	logger's infof("Selected text: {}", sut's getSelectedText())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		set sutView to "Query"
		set sutView to "Content"
		set sutView to "Structure"
		set sutView to "Unicorn"
		
		sut's switchView(sutView)
		
	else if caseIndex is 2 then
		
	else if caseIndex is 3 then
		
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
		
		
	else if caseIndex is 10 then
		set frontTab to sut's getFrontTab()
		frontTab's runQuery("SELECT '" & (current date) & "'")
		
		
	else if caseIndex is 13 then
		tell application "System Events" to tell process "Sequel Ace"
			-- set frontmost to true
			click button "Apply Filter(s)" of group 1 of splitter group 1 of front window
		end tell
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck

on new(pAppWindow)
	loggerFactory's injectBasic(me)
	
	set retry to retryLib's new()
	set syseve to syseveLib's new()
	set kb to kbLib's new()
	
	script SequelAceTabInstance
		property appWindow : pAppWindow -- non-sysEveWindow
		
		on setDatabase(databaseName)
			-- TODO 
		end setDatabase
		
		(*
			A database must already be selected to return non-missing value.
		
			@returns the list consisting of connection, database, and table names. Database and table name may not be available at a given time.  Missing value if both database and table names could not be derived from the window name.
		*)
		on _getIdentifierTokens()
			set windowName to the name of appWindow
			-- logger's debugf("windowName: {}", windowName)
			if windowName is equal to "Sequel Ace" then return missing value
			
			tell application "System Events" to tell process "Sequel Ace"
				try
					if (value of pop up button 1 of toolbar 1 of my getSysEveWindow() as text) starts with "Choose database" then
						return missing value
					end if
				on error the errorMessage number the errorNumber
					log errorMessage
				end try
			end tell
			
			(*
			set nameSpacedTokens to textUtil's split(windowName, " ")
			logger's debugf("nameSpacedTokens: {}", nameSpacedTokens)
			if the (count of items in nameSpacedTokens) is less than 2 then return missing value
			
			textUtil's split(last item of nameSpacedTokens, "/")
			*)
			textUtil's split(windowName, "/")
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
			
			switchView("Query")
			
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
		
		
		(**)
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
			Switches the current view between Query, Contents, Structure etc. Use the menu
				item name for better reliability because some UI elements are hidden when the
				window is shrunk.
		*)
		on switchView(viewName)
			logger's debugf("viewName: {}", viewName)
			if running of application "Sequel Ace" is false then return
			if not isConnected() then
				logger's warn("switchView: The target tab is not currently connected.")
				return
			end if
			
			tell application "System Events" to tell process "Sequel Ace"
				try
					click button viewName of toolbar 1 of front window
				on error
					if viewName is "Query" then set viewName to "Custom Query"
					try
						-- 						tell application "Sequel Ace" to activate
						set frontmost to true
						click menu item viewName of menu 1 of menu bar item "View" of menu bar 1
					on error the errorMessage number the errorNumber
						logger's warn(errorMessage)
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

