(*
	Handlers related to inspector.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Google Chrome/136.0/dec-google-chrome-inspector'

	@Migrated: Saturday, October 26, 2024 at 8:59:40 PM
	@Last Modified: Saturday, October 26, 2024 at 8:59:40 PM
	@Change Logs:
*)

use loggerFactory : script "core/logger-factory"

use uiutilLib : script "core/ui-util"
use kbLib : script "core/keyboard"
use processLib : script "core/process"
use retryLib : script "core/retry"

property logger : missing value
property uiUtil : missing value
property kb : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		Main
		Manual: Activate DevTools
		Manual: Deactivate DevTools
		Manual: Trigger DevTools Customize
		Manual: Trigger DevTools Menu Item
		
		Manual: Move DevTools Panel
		Manual: Activate Device Toolbar (responsive testing)
		Manual: Deactivate Device Toolbar (responsive testing)
		Manual: Toggle Device Toolbar (responsive testing)
		Manual: Focus Inspector Prompt
		
		Manual: Switch Inspector Tab
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
	set sutLib to script "core/google-chrome"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("DevTools active: {}", sut's isDevToolsActive())
	logger's infof("DevTools HTML found: {}", sut's getDevToolsUiHtml() is not missing value)
	logger's infof("DevTools is floating: {}", sut's isDevToolsFloating())
	logger's infof("DevTools menu is visible (triggered): {}", sut's isDevToolsMenuVisible())
	logger's infof("Device Toolbar active?: {}", sut's isDeviceToolbarActive())
	logger's infof("Inspector Tab Name: {}", sut's getInspectorTabName())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's activateDevTools()
		
	else if caseIndex is 3 then
		sut's deactivateDevTools()
		
	else if caseIndex is 4 then
		sut's triggerDevToolsCustomize()
		
	else if caseIndex is 5 then
		-- sut's triggerDevToolMenuItem("Unicorn")
		-- sut's triggerDevToolMenuItem("Search")
		sut's triggerDevToolMenuItem("More tools")
		
	else if caseIndex is 6 then
		set sutLocation to "left"
		-- set sutLocation to "right"
		-- set sutLocation to "bottom"
		-- set sutLocation to "separate window"
		
		logger's debugf("sutLocation: {}", sutLocation)
		sut's moveDevToolsPanel(sutLocation)
		
	else if caseIndex is 7 then
		sut's activateDeviceToolbar()
		
	else if caseIndex is 8 then
		sut's deactivateDeviceToolbar()
		
	else if caseIndex is 9 then
		sut's toggleDeviceToolbar()
		
	else if caseIndex is 10 then
		sut's focusInspectorPrompt()
		
	else if caseIndex is 11 then
		set sutInspectorTabName to "Unicorn"
		set sutInspectorTabName to "Performance"
		logger's infof("sutInspectorTabName: {}", sutInspectorTabName)
		
		sut's switchInspectorTab(sutInspectorTabName)
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	set uiUtil to uiutilLib's new()
	set kb to kbLib's new()
	set retry to retryLib's new()
	
	script GoogleChromeInspectorDecorator
		property parent : mainScript
		property waitSecondsAfterRunViaJavaScriptViaInspector : 0.1
		
		on isDevToolsActive()
			getDevToolsUiHtml() is not missing value
		end isDevToolsActive
		
		
		on activateDevTools()
			if running of application "Google Chrome" is false then return
			if isDevToolsActive() then return
			
			tell application "System Events" to tell process "Google Chrome"
				set frontmost to true
				try
					click menu item "Developer Tools" of menu 1 of menu item "Developer" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
			delay 0.1
			script ActiveWaiter
				if isDevToolsActive() then return true
			end script
			exec of retry on result for 3
		end activateDevTools
		
		
		(*
			-- {"Elements", "Console", "Sources", "Network", "Performance", "Memory", "Application"}
		*)
		on switchInspectorTab(tabName)
			if running of application "Google Chrome" is false then return
			set devToolsHtmlUi to getDevToolsUiHtml()
			if devToolsHtmlUi is missing value then return
			
			tell application "System Events" to tell process "Google Chrome"
				try
					click (first radio button of tab group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 2 of group 1 of group 1 of group 1 of group 1 of devToolsHtmlUi whose description is tabName)
				end try
			end tell
		end switchInspectorTab
		
		on activateJavaScriptConsole()
			if not isDevToolsActive() then
				tell application "System Events" to tell process "Google Chrome"
					set frontmost to true
					try
						click menu item "JavaScript Console" of menu 1 of menu item "Developer" of menu 1 of menu bar item "View" of menu bar 1
					end try
				end tell
				return
				
			else
				
			end if
		end activateJavaScriptConsole
		
		
		(*
			This is hard to implement using UI Elements because Google Chrome updates too fast.
		*)
		on deactivateDevTools()
			if running of application "Google Chrome" is false then return
			if isDevToolsActive() is false then return
			
			
			(*
			set htmlElement to my getDevToolsUiHtml()
			if htmlElement is missing value then
				logger's debug("HTML Element was not found")
				return
			end if
			
			tell application "System Events" to tell process "Google Chrome"
				set frontmost to true
				delay 0.2
				-- Broke on the same minor version number.
				-- click button 1 of last group of last group of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of htmlElement
				-- click button 1 of last group of last group 
				-- click 
				
				-- perform action "AXPress" of 
				-- click 
				button 1 of last group of toolbar 2 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 2 of group 1 of group 1 of group 1 of group 1 of htmlElement -- Fails to work.
				
				set cliclick to cliclickLib's new()
				lclick of cliclick at result with smoothing
			end tell
*)
			
			set googleChromeProcess to processLib's new("Google Chrome")
			googleChromeProcess's focusWindow()
			kb's pressKey("F12")
			
			script DeactivateWaiter
				delay 0.1
				if not isDevToolsActive() then return true
			end script
			exec of retry on result for 3
		end deactivateDevTools
		
		
		on toggleDevTools()
			if running of application "Google Chrome" is false then return
			
			if isDevToolsActive() then
				deactivateDevTools()
				return
			end if
			
			activateDevTools()
		end toggleDevTools
		
		
		on isDevToolsFloating()
			if running of application "Google Chrome" is false then return missing value
			
			tell application "System Events" to tell process "Google Chrome"
				exists (first window whose title starts with "DevTools - chrome://settings/help")
			end tell
		end isDevToolsFloating
		
		
		on getDevToolsUiHtml()
			if running of application "Google Chrome" is false then return missing value
			
			tell application "System Events" to tell process "Google Chrome"
				try
					return UI element "DevTools" of group 1 of group 1 of group 1 of group 1 of front window
				end try
			end tell
			missing value
		end getDevToolsUiHtml
		
		
		on isDevToolsMenuVisible()
			if running of application "Google Chrome" is false then return fase
			
			set htmlElement to my getDevToolsUiHtml()
			if htmlElement is missing value then return false
			
			tell application "System Events" to tell process "Google Chrome"
				exists (first menu item of menu 1 of group 1 of last group of group 1 of htmlElement)
			end tell
		end isDevToolsMenuVisible
		
		on triggerDevToolsCustomize()
			if running of application "Google Chrome" is false then return
			
			set htmlElement to my getDevToolsUiHtml()
			if htmlElement is missing value then return
			
			tell application "System Events" to tell process "Google Chrome"
				if my isDevToolsFloating() then
					click button 1 of pop up button 1 of last group of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of htmlElement
					return
				end if
				
				-- set sideBarVboxUi to uiUtil's findUiWithAttribute(groups of group 1 of group 1 of group 1 of group 1 of htmlElement, "AXDOMClassList", "shadow-split-widget-contentsshadow-split-widget-sidebarvbox")
				set sideBarVboxUi to uiUtil's findUiWithAttributeContaining(groups of group 1 of group 1 of group 1 of group 1 of htmlElement, "AXDOMClassList", "shadow-split-widget-sidebar")
				click of buttons of pop up button 1 of last group of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of sideBarVboxUi
				delay 0.1
				
			end tell
		end triggerDevToolsCustomize
		
		
		(* Must have already triggered the DevTools Customize and control *)
		on triggerDevToolMenuItem(keyword)
			if running of application "Google Chrome" is false then return missing value
			
			if not isDevToolsMenuVisible() then triggerDevToolsCustomize()
			
			set htmlElement to my getDevToolsUiHtml()
			tell application "System Events" to tell process "Google Chrome"
				try
					click (first menu item of menu 1 of group 1 of last group of group 1 of htmlElement whose description contains keyword or title contains keyword)
					delay 0.1
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
				end try -- keyword did not match any menu item							
			end tell
		end triggerDevToolMenuItem
		
		
		(*
			@locationKey - right, left, bottom, or separate window
		*)
		on moveDevToolsPanel(locationKey)
			if running of application "Google Chrome" is false then return missing value
			
			if not isDevToolsMenuVisible() then triggerDevToolsCustomize()
			
			set htmlElement to my getDevToolsUiHtml()
			if htmlElement is missing value then return
			
			tell application "System Events" to tell process "Google Chrome"
				try
					click (first group of last group of group 1 of menu item 1 of menu 1 of group 1 of last group of group 1 of htmlElement whose description contains locationKey)
				end try
			end tell
		end moveDevToolsPanel
		
		
		(* For testing responsiveness. *)
		on isDeviceToolbarActive()
			if running of application "Google Chrome" is false then return false
			if isDevToolsActive() is false then return false
			
			set htmlElement to my getDevToolsUiHtml()
			if htmlElement is missing value then return false
			
			tell application "System Events" to tell process "Google Chrome"
				set sideBarVboxUi to uiUtil's findUiWithAttributeContaining(groups of group 1 of group 1 of group 1 of group 1 of htmlElement, "AXDOMClassList", "shadow-split-widget-sidebar")
				if sideBarVboxUi is missing value then return false
				
				try
					first group of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of sideBarVboxUi whose description is "Toggle device toolbar"
					
					set classList to value of attribute "AXDOMClassList" of checkbox 1 of result
					return last item of classList as text is "toggled"
				end try
			end tell
			
			false
		end isDeviceToolbarActive
		
		
		on activateDeviceToolbar()
			if isDeviceToolbarActive() then return
			
			triggerDeviceToolbarItem()
		end activateDeviceToolbar
		
		
		on deactivateDeviceToolbar()
			if isDeviceToolbarActive() is false then return
			
			triggerDeviceToolbarItem()
		end deactivateDeviceToolbar
		
		
		on triggerDeviceToolbarItem()
			set htmlElement to my getDevToolsUiHtml()
			if htmlElement is missing value then return
			
			tell application "System Events" to tell process "Google Chrome"
				set sideBarVboxUi to uiUtil's findUiWithAttributeContaining(groups of group 1 of group 1 of group 1 of group 1 of htmlElement, "AXDOMClassList", "shadow-split-widget-sidebar")
				if sideBarVboxUi is missing value then return false
				
				try
					first group of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of sideBarVboxUi whose description is "Toggle device toolbar"
					
					click checkbox 1 of result
				end try
			end tell
			
		end triggerDeviceToolbarItem
		
		
		on toggleDeviceToolbar()
			triggerDeviceToolbarItem()
		end toggleDeviceToolbar
		
		
		on getInspectorTabName()
			if running of application "Google Chrome" is false then return missing value
			set devToolsUiHtml to getDevToolsUiHtml()
			if devToolsUiHtml is missing value then return missing value
			
			tell application "System Events" to tell process "Google Chrome"
				try
					return description of first radio button of tab group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 2 of group 1 of group 1 of group 1 of group 1 of devToolsUiHtml whose value is true
					
				end try
			end tell
			missing value
		end getInspectorTabName
		
		
		on focusInspectorPrompt()
			if running of application "Google Chrome" is false then return
			if not isDevToolsActive() then return
			
(*
			if getInspectorTabName() is not "Console" then
				switchInspectorTab("Console")
			end if
*)
			
			tell application "System Events" to tell process "Google Chrome"
				set frontmost to true
			end tell
			
			kb's pressControlKey("`")
		end focusInspectorPrompt
		
		
		on isInspectorPromptActive()
			if running of application "Google Chrome" is false then return false
			if not isDevToolsActive() then return false
			
			"WIP"
		end isInspectorPromptActive
		
		
		on runJavaScriptViaInspector(javaScriptCode)
			if running of application "Google Chrome" is false then return
			
			if not isDevToolsActive() then
				activateDevTools()
			end if
			
			if getInspectorTabName() is not "Console" then
				
			end if
			
			focusInspectorPrompt()
			
			-- 			kb's typeText(javaScriptCode)
			kb's insertTextByPasting(javaScriptCode)
			kb's pressKey(return)
			delay waitSecondsAfterRunViaJavaScriptViaInspector
		end runJavaScriptViaInspector
		
	end script
end decorate




