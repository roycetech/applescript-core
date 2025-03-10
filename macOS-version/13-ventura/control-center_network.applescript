(*
	This script provides network-specific functions to the control-center library.

	@Project:
		applescript-core

	@Build:
		make build-control-center

	@Migrated: September 25, 2023 11:18 AM
*)


use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"
use retryLib : script "core/retry"
use ccLib : script "core/control-center"

use spotScript : script "core/spot-test"

property logger : missing value
property kb : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: List of Hotspot (Maybe used to identify your hotpot key, mind the Unicode apostrophe, test no hotspot available)
		Manual: Join Hotspot (Not Joined, Already Joined, Not Found)
		Manual: Join WIFI (Not Joined, Already Joined, Not Found)
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set controlCenterLib to script "core/control-center"
	set controlCenter to controlCenterLib's new()
	set sut to decorate(controlCenter)
	if caseIndex is 1 then
		set hotspots to sut's getListOfAvailableHotspot()
		if the number of items in hotspots is 0 then
			logger's info("No hotspot found")
		else
			repeat with nextHotspot in hotspots
				logger's info(nextHotspot)
			end repeat
		end if

	else if caseIndex is 2 then
		(* Toggle below cases. *)
		sut's joinHotspot("iPhone")
		-- sut's joinHotspot("Galaxy")

	else if caseIndex is 3 then
		(* Toggle below cases. *)
		sut's joinHotspot("Care")
		-- sut's joinHotspot("Careless")
	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set kb to kbLib's new()
	set retry to retryLib's new()


	script ControlCenterNetworkDecorated
		property parent : mainScript

		(*
			@hotspotKey - the hotspot identifier to join, e.g. "Joe's iPhone". (Use the correct Unicode apostrophe)
		*)
		on joinHotspot(hotspotKey)
			joinNetwork(hotspotKey)
		end joinHotspot

		(*
			Joins the first network matching the given key.

			@hotspotKey - the hotspot identifier to join, e.g. "Joe's iPhone". (Use the correct Unicode apostrophe)
		*)
		on joinNetwork(networkKey)
			_activateControlCenter()
			_activateWifiPane()

			set retry to retryLib's new()

			logger's infof("Hotspot: {}", networkKey)
			tell application "System Events" to tell process "ControlCenter"
				script HotspotClicker
					tell application "System Events" to tell process "ControlCenter" to tell window "Control Center"
						set matchedConnections to checkbox 1 of scroll area 1 of group 1 whose value of attribute "AXIdentifier" contains networkKey
						if the number of items in matchedConnections is 0 then return "not found"

						set currentState to value of first item in matchedConnections
						logger's debugf("Current State: {}", currentState)
						if currentState is 1 then
							return "already connected"
						end if

						click (first checkbox of scroll area 1 of group 1 whose value of attribute "AXIdentifier" contains networkKey)
						true
					end tell
				end script
				set clickResult to exec of retry on result for 3 by 1

				if clickResult is "not found" then
					error "The given hotspot key: " & networkKey & " was not found"

				else if clickResult is "already connected" then
					kb's pressKey("esc")
					logger's warn("You are already connected ")

				else if clickResult is missing value then
					kb's pressKey("esc")
					logger's fatal("Could not click your hotspot " & networkKey & ", make sure it is available")

				else
					kb's pressKey("esc")

				end if
			end tell
		end joinNetwork


		(*
			Joins the first hotspot matching the given key.

			@hotspotKey - the hotspot identifier to join, e.g. "Joe's iPhone". (Use the correct Unicode apostrophe)
		*)
		on joinWifi(sidKey)
			joinNetwork(sidKey)
		end joinWifi


		on getListOfAvailableHotspot()
			set retry to retryLib's new()
			set listOfHotspot to {}

			_activateControlCenter()
			_activateWifiPane()

			set startOffset to the (length of "wifi-network-") + 1
			set headingCount to 0

			tell application "System Events" to tell process "ControlCenter"
				repeat with nextUIElement in UI elements of scroll area 1 of group 1 of front window
					if value of attribute "AXRole" of the nextUIElement is "AXHeading" then set headingCount to headingCount + 1
					if headingCount is greater than 1 then exit repeat

					if value of attribute "AXRole" of the nextUIElement is "AXCheckBox" then
						set axIdentifier to value of attribute "AXIdentifier" of the nextUIElement
						set hotspotName to the text startOffset thru -1 in axIdentifier
						set end of listOfHotspot to hotspotName
					end if
				end repeat
			end tell

			kb's pressKey("esc")

			listOfHotspot
		end getListOfAvailableHotspot


		(*
			While the Control Center is already visible, it moves to the Wi-Fi pane by triggering the "Show Details" of the Wi-Fi check box
		*)
		on _activateWifiPane()
			set retry to retryLib's new()
			tell application "System Events" to tell process "ControlCenter"
				perform action 2 of (first checkbox of group 1 of window "Control Center" whose value of attribute "AXIdentifier" is "controlcenter-wifi")
			end tell

			script WiFiAreaWaiter
				tell application "System Events" to tell process "ControlCenter"
					if exists (first static text of group 1 of front window whose name starts with "Wi" and name ends with "Fi") then return true
				end tell
			end script
			set scrollWaitResult to exec of retry on result for 20 by 0.1
			if scrollWaitResult is missing value then
				error "Scroll Area with WIFI list did not appear within the allotted time"
			end if
		end _activateWifiPane
	end script
end decorate
