(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/1st-party/Image Capture/26.3/image-capture'

	@Created: Thu, Feb 26, 2026 at 08:21:38 PM
	@Last Modified: July 24, 2023 10:56 AM
*)

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Trigger Overview
		Manual: Trigger Scan
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's triggerOverview()
		
	else if caseIndex is 3 then
		sut's triggerScan()
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	
	script ImageCaptureInstance
		on triggerScan()
			if running of application "Image Capture" is false then return
			
			tell application "System Events" to tell process "Image Capture"
				try
					click button "Scan" of group 2 of splitter group 1 of front window
				end try
			end tell
		end triggerScan
		
		on triggerOverview()
			if running of application "Image Capture" is false then return
			
			tell application "System Events" to tell process "Image Capture"
				try
					click button "Overview" of group 2 of splitter group 1 of front window
				end try
			end tell
			
		end triggerOverview
	end script
end new
