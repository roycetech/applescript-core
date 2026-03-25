(*
	@Purpose:
		Serves as base class for all application wrapper scripts.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/base-app

	@Created: Sat, Feb 28, 2026 at 07:17:25 PM
	@Last Modified: 2026-03-24 17:31:28
*)
if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

property logger : missing value

on spotCheck()
	set loggerFactory to script "core/logger-factory"
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		NOOP
		Manual: Calendar
		Manual: Safari
		Dummy
		Dummy
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	if caseIndex is 1 then

	else if caseIndex is 2 then
		set calendarLib to script "core/calendar"
		set calendar to calendarLib's new()
		logger's infof("Has file access: {}", calendar's hasFileAccess())

	else if caseIndex is 3 then
		set safariLib to script "core/safari"
		set safari to safariLib's new()

		set hasFileAccessResult to safari's hasFileAccess()
		logger's infof("Has file access: {}", hasFileAccessResult)
		if hasFileAccessResult then
		logger's infof("Has dialog window: {}", safari's hasFileDialogWindow())
		end if
	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	script BaseAppInstance
		on hasFileAccess()
			false
		end hasFileAccess
	end script
end new
