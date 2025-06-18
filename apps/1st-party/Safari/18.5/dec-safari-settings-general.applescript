(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/18.5/dec-safari-settings-general

	@Created: Sat, Jun 14, 2025 at 08:36:40 AM
	@Last Modified: Sat, Jun 14, 2025 at 08:36:40 AM
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Toggle Open safe files after downloading
		Manual: Set Open safe files after downloading - ON
		Manual: Set Open safe files after downloading - OFF
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
	set sutLib to script "core/safari"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("Is open safe files after downloading: {}", sut's isOpenSafeFilesAfterDownloading())
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's toggleOpenSafeFilesAfterDownloading()
		
	else if caseIndex is 3 then
		sut's setOpenSafeFilesAfterDownloadingOn()
		
	else if caseIndex is 4 then
		sut's setOpenSafeFilesAfterDownloadingOff()
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script SafariSettingsGeneralDecorator
		property parent : mainScript
		
		on isOpenSafeFilesAfterDownloading()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			tell application "System Events" to tell process "Safari"
				-- value of checkbox "Open “safe” files after downloading" of group 1 of group 1 of settingsWindow
				1 is equal to the (value of first checkbox of group 1 of group 1 of settingsWindow whose title ends with "files after downloading")
			end tell
		end isOpenSafeFilesAfterDownloading
		
		on toggleOpenSafeFilesAfterDownloading()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return
			
			tell application "System Events" to tell process "Safari"
				click (first checkbox of group 1 of group 1 of settingsWindow whose title ends with "files after downloading")
			end tell
		end toggleOpenSafeFilesAfterDownloading
		
		on setOpenSafeFilesAfterDownloadingOn()
			if not isOpenSafeFilesAfterDownloading() then toggleOpenSafeFilesAfterDownloading()
		end setOpenSafeFilesAfterDownloadingOn
		
		on setOpenSafeFilesAfterDownloadingOff()
			if isOpenSafeFilesAfterDownloading() then toggleOpenSafeFilesAfterDownloading()
		end setOpenSafeFilesAfterDownloadingOff
	end script
end decorate
