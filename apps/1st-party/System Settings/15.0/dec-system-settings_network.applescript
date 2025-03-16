(*
	This decorator contains handlers network settings
	
	WIP!

	@Project:
		applescript-core
		
	@Build:
		./scripts/build-lib.sh 'apps/1st-party/System Settings/15.0/dec-system-settings_network'

	@Created: Mon, Mar 03, 2025 at 06:48:14 AM
	@Last Modified: Mon, Mar 03, 2025 at 06:48:18 AM
	@Change Logs:
		
*)
use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"

property logger : missing value
property retry : missing value
property TopLevel : me
property PANE_ID_NETWORK : "com.apple.Network-Settings.extension"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		INFO
		Manual: Trigger WiFi
		Manual: Compound: Trigger WiFi Details
		Manual: Compound: Switch Network Tab
		Manual: Set DNS
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	-- activate application ""
	set sutLib to script "core/system-settings"
	set sut to sutLib's new()
	set sut to decorate(sut)
	sut's quitApp()
	sut's revealNetwork()
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's triggerWifi()
		
	else if caseIndex is 3 then
		sut's triggerWifi()
		sut's triggerWifiDetails()
		
	else if caseIndex is 4 then
		set sutTab to "Unicorn"
		set sutTab to "DNS"
		logger's debugf("sutTab: {}", sutTab)
		
		sut's triggerWifi()
		sut's triggerWifiDetails()
		sut's switchNetworkTab(sutTab)
		
	else if caseIndex is 5 then
		
	else
		
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set retry to retryLib's new()
	
	script SystemSettingsNetworkDecorator
		property parent : mainScript
		
		on revealNetwork()
			tell application "System Settings" to activate
			
			script PanelWaiter
				tell application "System Settings"
					set current pane to pane id (TopLevel's PANE_ID_NETWORK)
					window "Network" exists
				end tell
			end script
			exec of retry on result for 20 by 0.5
		end revealNetwork
		
		
		on triggerWifi()
			if running of application "System Settings" is false then return
			
			script WifiWaiter
				tell application "System Events" to tell process "System Settings"
					if exists window "Wi-Fi" then return true
					
					click (first button of group 1 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of front window whose value of attribute "AXIdentifier" contains "wifi")
				end tell
			end script
			exec of retry on result for 3
		end triggerWifi
		
		
		on triggerWifiDetails()
			if running of application "System Settings" is false then return
			
			tell application "System Events" to tell process "System Settings"
				click button 1 of group 1 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of front window -- NO ID! 				
				delay 0.2
			end tell
			script SheetWaiter
				tell application "System Events" to tell process "System Settings"
					if exists sheet 1 of window "Wi-Fi" then return true
					click button 1 of group 1 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of front window -- NO ID! 				
				end tell
			end script
			exec of retry on result for 3
		end triggerWifiDetails
		
		
		on switchNetworkTab(targetTab)
			if running of application "System Settings" is false then return
			
			tell application "System Events" to tell process "System Settings"
				try
					set selected of first row of outline 1 of scroll area 1 of group 1 of splitter group 1 of group 1 of sheet 1 of front window whose value of static text 1 of UI element 1 is targetTab to true
					delay 0.2
				end try
			end tell
		end switchNetworkTab
		
		
		(* Must be called while DNS Servers sheet is already shown. *)
		on clearDnsSer()
			if running of application "System Settings" is false then return
			
		end clearDnsSer
		
		
		(*
			@returns true of Voice control is active.
		*)
		on clearDnsEntries()
			tell application "System Events" to tell process "System Settings"
				-- ptext field 1 of UI element 1 of
				set selected of row 1 of outline 1 of scroll area 1 of group 1 of scroll area 1 of group 2 of splitter group 1 of group 1 of sheet 1 of front window to true
				
				
				-- properties of 
				click (second button of group 1 of scroll area 1 of group 2 of splitter group 1 of group 1 of sheet 1 of front window whose value of attribute "AXIdentifier" is "DNSServersList")
				-- uiutil's printAttributeValues(result)
			end tell
		end clearDnsEntries
		
		
		on isWiFiWindowPresent()
			
		end isWiFiWindowPresent
		
		
	end script
end decorate

