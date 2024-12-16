(*
	@Testing:
		Have a valid connection created with name: Docker MySQL 5
		A database called "crm" must exist
		A table called customers must exist.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Sequel Ace/4.1.x/sequel-ace'

	@Created: Sun, Oct 27, 2024 at 1:03:15 PM
	@Last Modified: Sun, Oct 27, 2024 at 1:03:12 PM
	@Change Logs:
*)

use scripting additions

use listUtil : script "core/list"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use sequelAceTabLib : script "core/sequel-ace-tab"
use decoratorLib : script "core/decorator"
use retryLib : script "core/retry"

property logger : missing value
property retry : missing value

property TEST_CONNECTION_NAME : "MySQL5 Docker"

(* Used for testing only. *)
property CONFIG_USER : "user"
property CONFIG_KEY_TEST_CONNECTION : "Test MySQL Connection"


if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()
	
	set configLib to script "core/config"
	set configUser to configLib's new(CONFIG_USER)
	
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		INFO
		Manual: New Tab
		Manual: Get Front Tab
		Manual: Find Tab - Not Found, Found and Focus, Connection Tab, No Tabs

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
	logger's infof("Tab count: {}", sut's getTabCount())
	
	set testConnection to configUser's getValue(CONFIG_KEY_TEST_CONNECTION)
	logger's debugf("testConnection: {}", testConnection)
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		set sutConnectionName to "Unicorn"
		set sutConnectionName to testConnection
		logger's debugf("sutConnectionName: {}", sutConnectionName)
		sut's newTab(sutConnectionName)
		
	else if caseIndex is 3 then
		set sutTab to sut's getFrontTab()
		logger's infof("Front tab found: {}", sutTab is not missing value)
		
	else if caseIndex is 4 then
		set sutConnectionName to testConnection
		-- set sutConnectionName to "Unicorn"
		set sutConnectionName to {testConnection, "crm"}
		set sutConnectionName to {testConnection, "Unicorn"}
		set sutConnectionName to {testConnection & "/crm"}
		
		set sut to sut's findTab(sutConnectionName)
		if sut is missing value then
			logger's info("Tab was not found")
		else
			logger's info("Tab was found")
			sut's focus()
		end if
		
		-- FOR REVIEW BELOW TEST CASES.
		
		
	else if caseIndex is 3 then
		logger's debugf("TEST_CONNECTION_NAME: {}", TEST_CONNECTION_NAME)
		
		set sutDbName to "Unicorn"
		set sutDbName to "crm"
		logger's debugf("sutDbName: {}", sutDbName)
		
		set sutParams to {TEST_CONNECTION_NAME}
		-- set sutParams to {TEST_CONNECTION_NAME, sutDbName}
		
		set sequelAceTab to sut's findTab(sutParams)
		
		logger's infof("Tab Found: {}", sequelAceTab is not missing value)
		
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
	
	script SequelAceInstance
		
		on getTabCount()
			if running of application "Sequel Ace" is false then return 0
			
			tell application "System Events" to tell process "Sequel Ace"
				if not (exists (tab group 1) of front window) then return 1
				
				count of radio buttons of tab group 1 of front window
			end tell
		end getTabCount
		
		
		(*  
			@tabPath - a list of connection, database, and table name. May also pass as Connection name/database/table
		*)
		-- on findTab(connectionName, databaseAndOrTable)
		on findTab(tabPath)
			if running of application "Sequel Ace" is false then return missing value
			if tabPath is missing value then return missing value
			if the class of tabPath is text then
				if tabPath contains "/" then
					set tabPath to listUtil's split(tabPath, "/")
				else
					set tabPath to {tabPath}
				end if
			end if
			
			-- if the number of items in tabPath is not 0 then
			set {connectionName, dbName, tableName} to tabPath & {missing value, missing value, missing value}
			
			
			logger's debugf("connectionName: {}", connectionName)
			logger's debugf("dbName: {}", dbName)
			logger's debugf("tableName: {}", tableName)
			
			set nonEmptyPathTokens to {}
			repeat with nextToken in tabPath
				if nextToken is not missing value and nextToken is not equal to "" then
					set end of nonEmptyPathTokens to nextToken
				end if
			end repeat
			
			set titleKey to textUtil's join(nonEmptyPathTokens, "/")
			-- if databaseAndOrTable is not missing value and length of databaseAndOrTable is greater than 0 then set titleKey to titleKey & "/" & databaseAndOrTable
			logger's debugf("titleKey: {}", titleKey)
			
			tell application "System Events" to tell process "Sequel Ace"
				if (count of windows) is 0 then return missing value
				
				set frontWindowTitle to get title of front window
				logger's debugf("frontWindowTitle: {}", frontWindowTitle)
				if frontWindowTitle ends with titleKey then return my getFrontTab()
				
				if not (exists tab group "tab bar" of front window) then return missing value -- What is this state?
				
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
			sequelAceTabLib's new(frontWindow)
		end getFrontTab
		
		
		on newTab(connectionName)
			if running of application "Sequel Ace" is false then activate application "Sequel Ace"
			
			set frontTab to getFrontTab()
			if frontTab's isConnected() then
				set currentTabCount to getTabCount()
				tell application "System Events" to tell process "Sequel Ace"
					try
						click menu item "New Connection Tab" of menu 1 of menu bar item "File" of menu bar 1
					end try
				end tell
				script TabIncreaseWaiter
					if getTabCount() is equal to currentTabCount + 1 then return true
				end script
				exec of retry on result
			end if
			
			logger's debug("Checking each connection...")
			set connectionFound to false
			tell application "System Events" to tell process "Sequel Ace"
				repeat with nextConnection in rows of outline 1 of scroll area 1 of splitter group 1 of front window
					try
						if get value of text field 1 of nextConnection is connectionName then
							set selected of nextConnection to true
							set connectionFound to true
							logger's info("Found matching connection")
							exit repeat
						end if
					end try -- text field don't exist
				end repeat
				if connectionFound then
					click button "Connect" of scroll area 2 of splitter group 1 of front window
					delay 0.1
				else
					logger's info("Connection was not found.")
					return missing value
				end if
			end tell
			
			logger's debug("Checking for dialog")
			tell application "System Events" to tell process "Sequel Ace"
				if exists (first window whose title does not start with "Connecting") then -- Dialog appears during connection regardless if there's error or not.
					set dialogWindow to first window whose title does not start with "Connecting"
					logger's infof("Dialog text: {}", value of static text 1 of dialogWindow)
					try
						click button "OK" of dialogWindow -- Auto-dismiss if error
					end try -- Ignore if not found.
					return missing value
				else
					logger's debug("No dialog window found")
				end if
			end tell
			
			set frontTab to getFrontTab()
			repeat until frontTab's isConnected()
				delay 0.5
			end repeat
			delay 2 -- UI takes some time to refresh
			
			frontTab
		end newTab
	end script
	
	set decoratorOuter to decoratorLib's new(result)
	decoratorOuter's decorate()
end new

