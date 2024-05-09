(*
	@Purpose:
		Handler to return all the tabs.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/17.4.1/dec-safari-tab-group
		
	@Created: Friday, April 26, 2024 at 11:52:07 AM
	@Last Modified: 2024-04-26 11:56:58
	@Change Logs:
*)
use script "core/Text Utilities"
use scripting additions

use listUtil : script "core/list"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use safariTabLib : script "core/safari-tab"
use spotScript : script "core/spot-test"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: Get Tabs
		Manual: Sort
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	-- activate application ""
	set sutLib to script "core/safari"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	if caseIndex is 1 then
		set tabs to sut's getTabs()
		
	else if caseIndex is 2 then
		set testUrls to listUtil's splitByLine("
			https://go.dev/doc/
			https://www.udemy.com/join/login-popup/?next=/course/typescript-the-complete-developers-guide/learn/lecture/15066520#overview
			https://app.pluralsight.com/ilx/video-courses/10dc83a5-6eb0-498f-bff5-e2f310b2fed9/eddf76a9-495b-465e-8e69-a1ba6e3cb147/b3e79167-c23d-4272-8b3c-7757338988e4
			https://twitter.com/home
			https://www.ign.com/wikis/the-legend-of-zelda-a-link-to-the-past/Heart_Pieces
			https://gemini.google.com/app/0222accee918cdae
			https://dev.to/nickytonline/series/4083
		")
		
		set safariTab to sut's newWindow(item 1 of testUrls)
		repeat with nextUrl in rest of testUrls
			safariTab's newTab(nextUrl)
		end
		
		(*
		repeat with nextURL in sut's sortByURL()
			log nextURL
		end repeat
		*)
		
	else if caseIndex is 3 then
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on newSpotBase()
	script SpotBaseInstance
		property template : missing value
	end script
end newSpotBase


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script SafariTabsDecorator
		property parent : mainScript
		property sortingTabs : missing value
		
		on getTabs()
			set safariTabs to {}
			tell application "Safari"
				repeat with nextTab in tabs of front window
					safariTabLib's new(id of front window, index of nextTab)
					set end of safariTabs to result
				end repeat
				
				
				
			end tell
			safariTabs
		end getTabs
		
		on getTabAtIndex(index)
			tell application "Safari"
				safariTabLib's new(id of front window, index)
			end tell
		end getTabAtIndex
		
		(*
			Uses the selection sorting algorithm.
			
			Set Up:
				Documentation
				Course
				Java
				X
				Heart Pieces
				Gemini
				Stuff in My
		*)
		on sortByURL()
			
			(* Will contain the resulting sorted list *)
			set the sorted_list to {}
			
			(* Like the sorted list but stores the original location of the items. *)
			set the index_list to {}
			
			set my sortingTabs to getTabs()
			set repeatCount to 0
			repeat (the number of items in my sortingTabs) times
				set repeatCount to repeatCount + 1
				set the low_item to ""
				repeat with i from 1 to (number of items in my sortingTabs)
					if i is not in the index_list then
						set nextTab to item i of my sortingTabs
						-- set this_item to textUtil's lcase(nextTab's getTitle())
						set this_item to nextTab's getURL() as text
						if the low_item is "" then
							set the low_item to this_item
							set the low_item_index to i
							
						else if this_item is less than low_item then
							set the low_item to this_item
							set the low_item_index to i
						end if
					end if
				end repeat
				
				set the end of sorted_list to the low_item
				set the end of the index_list to the low_item_index
				
				-- log low_item_index & " : " & low_item & " : " & repeatCount -- & (ASCII character 10)
				
				if low_item_index > repeatCount then
					set tabToMove to getTabAtIndex(low_item_index)
					
					log "--------------------------------"
					log (format {"Moving tab: {} from {} to {}", {low_item, low_item_index, repeatCount}})
					log " 
>>> Before move tab to index"
					_printTabs(my sortingTabs)
					tabToMove's moveTabToIndex(repeatCount)
					tabToMove's focus()
					log "
>>> After move tab to index"
					_printTabs(my sortingTabs)
					
					set my sortingTabs to listUtil's moveElement(my sortingTabs, low_item_index, repeatCount)
					-- log ">>> After move element"
					-- _printTabs(tabs)
					
				end if
				
			end repeat
			
			-- log index_list
			
			-- log ">>> returning the sorted list"
			sorted_list
		end sortByURL
		
		on _printTabs(tabs)
			repeat with nextTab in tabs
				log nextTab's getURL()
			end repeat
		end _printTabs
		
	end script
end decorate
