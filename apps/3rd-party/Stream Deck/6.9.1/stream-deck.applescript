(* 
	This script wraps some of the Elgato Stream Deck app functionality.
	This script is slow when changing profile via menu so we just ignored the 
	application response to prevent this script from blocking.
	
	WARNING: This app is likely not a native macOS app so UI interactions via script is unreliable. We'll use cliclick to workaround this.
		
	@Usage:
		use streamDeckLib : script "core/stream-deck"
		set streamDeck to streamDeckLib's new()

	@Requires:
		Elgato Stream Deck App
		lsusb installed via brew to check if stream deck via USB is plugged in.
		Stream Deck icon visible in the top right corner.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Stream Deck/6.9.1/stream-deck'
		
	@Change Logs:
		Thu, Oct 02, 2025, at 06:55:08 AM - Removed dependency to homebrew.	
		
	@Created: Wed, Feb 5, 2025 at 7:19:21 AM
	@Last Modified: Mon, Feb 3, 2025 at 8:42:56 AM
*)

use scripting additions

use std : script "core/std"
use textUtil : script "core/string"
use unic : script "core/unicodes"

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"
use decoratorLib : script "core/decorator"
use decStreamDeckSettings : script "core/dec-stream-deck-settings"
use decStreamDeckButton : script "core/dec-stream-deck-button"

property logger : missing value

property retry : missing value
property isSpot : false
property kb : missing value

property DEVICE_XL : "Stream Deck XL"
property ATTR_ID_TEXT_EDIT : "ESDStreamDeckApplication.MainWindow.centralWidget.leftFrame.mainStack.CanvasView.ESDCanvasSplitter.ESDPropertyInspector.PropertyInspectorBase.textEditButton"

if {"Script Editor", "Script Debugger"} contains the name of current application then
	set isSpot to true
	spotCheck()
end if

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()
	
	set spotScript to script "core/spot-test"
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP: Info
		Manual: Focus Process
		Manual: Switch Profile
		Manual: Editor window - show
		Manual: Editor window - hide
		
		Dummy
		Dummy
		Dummy
		Dummy
		Dummy
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	logger's infof("USB Connected: {}", sut's isUsbConnected())
	logger's infof("Current Profile: {}", sut's getCurrentProfile(DEVICE_XL))
	logger's infof("Editor window present: {}", sut's isEditorWindowPresent())
	logger's infof("Integration: Settings window present: {}", sut's isSettingsWindowPresent())
	logger's infof("Integration: Is button selected: {}", sut's isButtonSelected())
	
	(*
	if caseDesc starts with "Manual: Switch Profile:" then
		set caseProfile to textUtil's stringAfter(caseDesc, "Switch Profile: ")
		logger's debugf("caseProfile: {}", caseProfile)
		sut's switchProfile("Stream Deck XL", caseProfile)
		
	end if
	*)
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's focusProcess()
		
	else if caseIndex is 3 then
		set sutProfileTitle to "Unicorn"
		set sutProfileTitle to "Work - Default"
		set sutProfileTitle to "Safari"
		-- set sutProfileTitle to "Percipio"
		logger's debugf("sutProfileTitle: {}", sutProfileTitle)
		
		set sutDevice to "Unicorn Device"
		set sutXlDevice to "Stream Deck XL"
		
		logger's infof("Switch Profile: Found: {}", sut's switchProfile(sutXlDevice, sutProfileTitle))
		
	else if caseIndex is 4 then
		sut's showEditorWindow()
		
	else if caseIndex is 5 then
		sut's hideEditorWindow()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	if std's appExists("Elgato Stream Deck") is false then error "Elgato Stream Deck app needs to be installed"
	-- loggerFactory's injectBasic(me)
	loggerFactory's inject(me)
	set retry to retryLib's new()
	
	script StreamDeckInstance
		
		
		on showEditorWindow()
			if running of application "Elgato Stream Deck" is false then return
			if isEditorWindowPresent() then return
			
			tell application "System Events" to tell process "Stream Deck"
				try
					-- click (first menu item of menu 1 of menu bar 2 whose title starts with "Preferences")
					click (menu item "Configure Stream Deck" of menu 1 of menu bar 2)
				end try
			end tell
			
			script EditorWindowWaiter
				if isEditorWindowPresent() then return true
			end script
			exec of retry on result for 15 by 0.2
		end showEditorWindow
		
		
		on hideEditorWindow()
			if running of application "Elgato Stream Deck" is false then return
			
			set editorWindow to getEditorWindow()
			tell application "System Events" to tell process "Stream Deck"
				try
					click (first button of editorWindow whose description is "close button")
				end try
			end tell
		end hideEditorWindow
		
		
		(*
			What is this for?
		*)
		on focusProcess()
			if running of application "Elgato Stream Deck" is false then return
			
			tell application "System Events" to tell process "Stream Deck"
				set frontmost to true
			end tell
		end focusProcess
		
		
		on isEditorWindowPresent()
			getEditorWindow() is not missing value
		end isEditorWindowPresent
		
		
		on getEditorWindow()
			if running of application "Elgato Stream Deck" is false then return missing value
			
			tell application "System Events" to tell process "Stream Deck"
				try
					return window "Stream Deck"
				end try
			end tell
			
			missing value
		end getEditorWindow
		
		
		on isUsbConnected()
			try
				-- return (do shell script "/opt/homebrew/bin/lsusb | grep 'Stream Deck'") is not ""
				return (do shell script "ioreg -p IOUSB -l | grep -i 'Stream Deck'") is not ""
			end try
			
			false
		end isUsbConnected
		
		(* 
			@returns true if the profile was found.
		*)
		on switchProfile(deviceName, profileName)
			tell application "System Events" to tell process "Stream Deck"
				try
					click menu item profileName of menu 1 of menu item deviceName of menu 1 of menu bar 2
					return true
				end try
			end tell
			
			false
		end switchProfile
		
		
		on getCurrentProfile(deviceName)
			if running of application "Elgato Stream Deck" is false then return missing value
			
			set uiutilLib to script "core/ui-util"
			set uiutil to uiutilLib's new()
			
			tell application "System Events" to tell process "Stream Deck"
				try
					-- NOTE: attribute AXMenuItemMarkChar comparison against non-missing value didn't work. That's why we used unic's MENU_CHECK
					return title of first menu item of menu 1 of menu item deviceName of menu 1 of menu bar 2 whose value of attribute "AXMenuItemMarkChar" is equal to unic's MENU_CHECK
				end try
			end tell
			
			missing value
		end getCurrentProfile
	end script
	
	decStreamDeckSettings's decorate(result)
	decStreamDeckButton's decorate(result)
	
	(*
	if not isSpot then
		set decorator to decoratorLib's new(result)
		return decorator's decorateByName("StreamDeckInstance")
	end if
	
	StreamDeckInstance
	*)
	
	set decorator to decoratorLib's new(result)
	decorator's decorateByName("StreamDeckInstance")
end new
