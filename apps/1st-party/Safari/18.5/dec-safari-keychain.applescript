(*
	@Purpose:
		The original safari script is quite big and we want to improve its manageability by breaking it down into smaller pieces.
		This decorator will contain the handlers relating to the keychain.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/18.5/dec-safari-keychain

	@Created: Sunday, March 31, 2024 at 10:20:13 PM
	@Last Modified: 2025-08-08 07:47:18
	@Change Logs:
		Sunday, March 31, 2024 at 10:20:18 PM - Keychain UI layout has changed.
*)
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use timerLib : script "core/timer"

use kbLib : script "core/keyboard"

property logger : missing value
property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		INFO
		Manual: Select Keychain
		Manual: Show other passwords
		Manual: Select other password
		Manual: Get username index

		Manual: Select Keychain with username and url
		Manual: Trigger AutoFill
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	activate application "Safari"
	delay 1

	set sutLib to script "core/safari"
	set sut to sutLib's new()
	set sut to decorate(sut)

	set keyChainVisible to sut's isKeychainFormVisible()
	logger's infof("Keychain form visible: {}", keyChainVisible)
	logger's infof("Is Mfa Keychain: {}", sut's isMfaKeychain())

	if keyChainVisible then
		logger's infof("Keychain items count: {}", sut's getKeyChainItemsCount())
		repeat with nextKeyChainItem in sut's getKeyChainItems()
			logger's infof("Username: {}, Host: {}", {username of nextKeyChainItem, hostname of nextKeyChainItem})
		end repeat
	end if

	if caseIndex is 1 then

	else if caseIndex is 2 then
		logger's infof("Keychain clicked: {}", sut's selectKeychainItem("Unicorn"))

	else if caseIndex is 3 then
		sut's showOtherPasswords()

	else if caseIndex is 4 then
		sut's showOtherPasswords()
		logger's infof("Keychain clicked: {}", sut's selectOtherKeychainItem("ft-admin"))

	else if caseIndex is 5 then
		set sutUsername to "unicorn"
		set sutUsername to "proxmox5"
		logger's debugf("sutUsername: {}", sutUsername)

		logger's infof("Credential index: {}", sut's getUsernameIndex(sutUsername))

	else if caseIndex is 6 then
		set configLib to script "core/config"
		set configBusiness to configLib's new("business")

		set sutUsername to configBusiness's getValue("app-hub: Work Username")
		logger's infof("sutUsername: {}", sutUsername)

		set sutCredentialKey to "Timesheet"
		logger's infof("sutCredentialKey: {}", sutCredentialKey)

		logger's infof("Keychain clicked: {}", sut's selectKeychainItem({sutUsername, sutCredentialKey}))

	else if caseIndex is 7 then

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set kb to kbLib's new()
	set delayAfterKeySeconds of kb to 0.05

	script SafariKeychainDecorator
		property parent : mainScript

		on getUsernameIndex(username)
			set keychainItems to getKeyChainItems()
			set usernameIndex to 0
			repeat with nextKeychain in keychainItems
				set usernameIndex to usernameIndex + 1
				if username of nextKeychain is equal to the username then return usernameIndex

			end repeat

			0
		end getUsernameIndex

		(*
			@returns true if keychain appeared on time.
		*)
		on waitForKeychain(timeoutSeconds, waitTime)
			set timer to timerLib's new()
			timer's start()
			repeat until timer's hasExceededTimeoutSeconds(3)
				if isKeychainFormVisible() then return true
				delay waitTime
			end repeat

			false
		end waitForKeychain


		on showOtherPasswords()
			if running of application "Safari" is false then return

			tell application "System Events" to tell process "Safari"
				set frontmost to true
				delay 0.1
				set optionsCount to the (number of rows of table 1 of scroll area 1) - 1
				logger's debugf("optionsCount: {}", optionsCount)
				repeat optionsCount times
					kb's pressKey("down")
				end repeat
				kb's pressKey("enter")
			end tell
		end showOtherPasswords

		(*
			@returns list of {username:text, hostname:text} record.
		*)
		on getKeyChainItems()
			set returnList to {}
			if not isKeychainFormVisible() then return returnList

			set localIsMfa to isMfaKeychain()
			tell application "System Events" to tell process "Safari"
				set credentialRows to rows of table 1 of scroll area 1
				if not localIsMfa then set credentialRows to items 1 thru -3 of credentialRows

				repeat with nextRow in credentialRows
					if localIsMfa then
						textUtil's stringAfter(value of static text 1 of UI element 1 of nextRow, "verification code for ")
						set end of returnList to {username:value of static text 2 of UI element 1 of nextRow, hostname:result}
					else
						set end of returnList to {username:value of static text 1 of UI element 1 of nextRow, hostname:value of static text 2 of UI element 1 of nextRow}
					end if
				end repeat
			end tell

			returnList
		end getKeyChainItems


		on getKeyChainItemsCount()
			number of items in getKeyChainItems()
		end getKeyChainItemsCount

		(*
			NOTE: Native AppleScript click command does not work. Tested on Ventura.
			@ itemKey - the username or the list containing the username and the credential key (host or title).

			@returns true if successfully clicked.
		*)
		on selectKeychainItem(itemKey)
			if running of application "Safari" is false then return

			set targetCredentialTitle to missing value
			if class of itemKey is text then
				set targetUsername to itemKey
				set targetCredentialKey to missing value
			else
				set {targetUsername, targetCredentialKey} to itemKey
			end if

			set isUsernameOnly to the number of items in itemKey is 1

			tell application "System Events" to tell process "Safari"
				set frontmost to true
				try
					set itemIndex to 0
					repeat with nextRow in rows of table 1 of scroll area 1
						set itemIndex to itemIndex + 1
						-- log value of static text 1 of UI element 1 of nextRow as text
						-- log value of static text 2 of UI element 1 of nextRow as text
						set credentialUsername to value of static text 1 of UI element 1 of nextRow
						set credentialTitle to value of static text 2 of UI element 1 of nextRow

						set isMatched to credentialUsername is equal to targetUsername and (isUsernameOnly or credentialTitle contains the targetCredentialKey)

						-- logger's debugf("isMatched: {}", isMatched)
						if isMatched then
							repeat itemIndex times
								kb's pressKey("down")
							end repeat
							kb's pressKey("enter")
							return true

						end if
					end repeat
				end try
			end tell
			false
		end selectKeychainItem


		(*
			Copied from selectKeychainItem
			@returns true if successfully clicked.
		*)
		on selectOtherKeychainItem(itemName)
			if running of application "Safari" is false then return

			set itemIndex to 0
			tell application "System Events" to tell process "Safari"
				set frontmost to true
				delay 0.1
				try
					repeat with nextRow in rows of table 1 of scroll area 1
						set itemIndex to itemIndex + 1
						set rowIsMatched to value of static text 1 of UI element 1 of nextRow is equal to itemName
						if rowIsMatched then
							-- Selection defaults at the 2nd item.
							if itemIndex is 1 then
								kb's pressKey("up")
							else if itemIndex is 2 then
								-- noop
							else
								repeat itemIndex - 2 times
									kb's pressKey("down")
								end repeat
							end if
							kb's pressKey("enter")
							return true
						end if
					end repeat
				end try
			end tell
			false
		end selectOtherKeychainItem


		on isKeychainFormVisible()
			if running of app "Safari" is false then return false

			tell application "System Events" to tell process "Safari"
				exists (table 1 of scroll area 1)
			end tell
		end isKeychainFormVisible


		(*
			Invoke this to make the keychain form appear when it is absent.
		*)
		on triggerAutoFill()
			if running of app "Safari" is false then return false

			tell application "System Events" to tell process "Safari"
				set frontmost to true
				set autoFillGroup to missing value
				try
					set autoFillGroup to the first group of UI element 1 of scroll area 1 of group 1 of group 2 of tab group 1 of splitter group 1 of front window whose description of button 1 of text field 1 is "password AutoFill"
				end try
				if autoFillGroup is not missing value then
					click the button "password AutoFill" of text field 1 of autoFillGroup
				end if
			end tell
		end triggerAutoFill


		on isMfaKeychain()
			if not isKeychainFormVisible() then return false

			tell application "System Events" to tell process "Safari"
				value of static text 1 of UI element 1 of row 1 of table 1 of scroll area 1 starts with "verification code"
			end tell
		end isMfaKeychain
	end script
end decorate
