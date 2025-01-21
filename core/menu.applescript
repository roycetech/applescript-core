(*
	Purpose:
		Make it simpler to create a menu using Foundation on the main script.

	@Project:
		applescript-core

	@Build:
		make build-lib SOURCE=core/menu

	@Testing:
		Test with Menu Pinned.  Cannot test the UI functionality because menu apps need to be deployed.

	@Created: Saturday, September 30, 2023 at 5:50:31 PM
	@Last Modified: 2025-01-20 08:53:52
*)
use scripting additions
use framework "Foundation"
use framework "AppKit"

use loggerFactory : script "core/logger-factory"

property logger : missing value
property isSpot : false

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	logger's finish()
end spotCheck


(*  *)
on new(pSourceApp, menuBarTitle)
	loggerFactory's inject(me)

	if isSpot is false then
		set bar to current application's NSStatusBar's systemStatusBar
		set localStatusItem to bar's statusItemWithLength:-1.0

		localStatusItem's setTitle:menuBarTitle

		set newMenu to current application's NSMenu's alloc()'s initWithTitle:menuBarTitle
		newMenu's setDelegate:pSourceApp
		localStatusItem's setMenu:newMenu
	else
		set newMenu to missing value
	end if

	script MenuUtilInstance
		property sourceApp : pSourceApp
		property menuElement : newMenu
		property statusItem : localStatusItem

		on addSeparator()
			if isSpot then return missing value

			set sepMenuItem to (current application's NSMenuItem's separatorItem())
			(menuElement's addItem:sepMenuItem)
		end addSeparator


		on clearMenuItems()
			clear()
		end clearMenuItems


		on clear()
			if isSpot then return

			-- menuElement's removeAllItems()

			repeat while (menuElement's numberOfItems() > 0)
				menuElement's removeItemAtIndex:0
			end repeat
		end clear


		(*  tea-such
			@action - e.g. "menuAction:"
			@useCommand - Use the "Command key" for the shortcut key.
		*)
		on createRootMenuItem(title, action, enabledState, shortcutKey, useCommand, checkedState)
			if isSpot then return missing value

			-- Auto-correction.
			if action is not missing value and action does not end with ":" then set action to action & ":"

			set newMenuItem to (current application's NSMenuItem's alloc()'s initWithTitle:title action:action keyEquivalent:shortcutKey)
			if useCommand then newMenuItem's setKeyEquivalentModifierMask:(current application's NSEventModifierFlagCommand)
			(menuElement's addItem:newMenuItem)
			(newMenuItem's setEnabled:enabledState)
			(newMenuItem's setState:checkedState)
			if enabledState then (newMenuItem's setTarget:sourceApp)

			newMenuItem
		end createRootMenuItem


		(*
			@action - e.g. "menuAltAction:"
		*)
		on createOptionalRootMenuItem(title, action, checkedState)
			if isSpot then return missing value

			-- Auto-correction.
			if action is not missing value and action does not end with ":" then set action to action & ":"

			set altMenuItem to (current application's NSMenuItem's alloc()'s initWithTitle:title action:action keyEquivalent:"")
			set altMenuItem's alternate to true
			(altMenuItem's setKeyEquivalentModifierMask:(current application's NSEventModifierFlagOption))
			(menuElement's addItem:altMenuItem)
			(altMenuItem's setState:checkedState)
			(altMenuItem's setTarget:sourceApp)

			altMenuItem
		end createOptionalRootMenuItem


		on createSubMenu(title, sourceMenuItems, action, selectedItem, submenuItemHandler)
			if isSpot then return

			set newSubMenu to (current application's NSMenu's alloc()'s initWithTitle:("title-unused"))
			repeat with nextSourceMenuItem in sourceMenuItems
				-- logger's debugf("nextSourceMenuItem: {}", nextSourceMenuItem)
				set nextProcessedMenuItemTitle to nextSourceMenuItem
				try
					if submenuItemHandler is not missing value then
						set nextProcessedMenuItemTitle to submenuItemHandler's handleNextElement(nextSourceMenuItem)
					end if
				end try

				set nextSubMenuItem to (current application's NSMenuItem's alloc()'s initWithTitle:nextProcessedMenuItemTitle action:action keyEquivalent:"")
				(newSubMenu's addItem:nextSubMenuItem)
				set nextItemChecked to selectedItem is equal to nextSourceMenuItem as text
				(nextSubMenuItem's setState:(nextItemChecked))
				(nextSubMenuItem's setTarget:sourceApp)
			end repeat

			-- Add the sub-menu to the main menu
			set subMenuTitle to (current application's NSString's stringWithString:title)
			set subMenuItem to (current application's NSMenuItem's alloc()'s initWithTitle:subMenuTitle action:action keyEquivalent:"")
			(subMenuItem's setSubmenu:newSubMenu)
			(menuElement's addItem:subMenuItem)
			(subMenuItem's setEnabled:true)
			(subMenuItem's setTarget:sourceApp) -- required for enabling the menu item
		end createSubMenu


		on setTitle(newTitle)
			statusItem's setTitle:(newTitle)
		end setTitle
	end script
end new

