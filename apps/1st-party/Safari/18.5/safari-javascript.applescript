(*
	Usage:
		See spotCheck

	Testing Template:
		use safariLib : script "core/safari"
		property safari : safariLib's new()

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/18.5/safari-javascript

	@Change Logs:
		Fri, Jul 04, 2025 at 09:20:00 AM - Refactored out the javascript codes.
		Thu, Jun 19, 2025 at 12:34:12 PM - Added set selected option by label
 *)

use scripting additions

use std : script "core/std"

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	(* Tests are based on current apple.com website, very likely to change in the future. *)
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Example.com

		Manual: AWS Login, IAM Radio Option
		Manual: Link Text Visible
		Manual: Selector Exists
		Checked By ID
		Retrieve Value
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set safariLib to script "core/safari"
	set safari to safariLib's new()
	-- set safariTab to safari's newTab("https://www.apple.com")
	safari's getFrontTab()
	set safariTab to decorate(result)

	tell safariTab
		set its findRunMax to 3
		set its findRetrySleep to 1
	end tell
	safariTab's focus()
	safariTab's waitForPageLoad()

	if caseIndex is 1 then
		logger's infof("H1 content: {}", safariTab's textContent("h1"))

	else if caseIndex is 2 then
		-- logger's infof("Selector Exists: {}",
		log safariTab's selectorExists("#iam_user_radio_button")
		log safariTab's selectorExists("#account")
		-- )

	else if caseIndex is 3 then
		set jsResult to safariTab's linkTextVisible("Learn more")
		assertThat of std given condition:jsResult is true, messageOnFail:"Failed spot check"
		set jsFalseResult to safariTab's linkTextVisible("Learn nothing")
		assertThat of std given condition:jsFalseResult is false, messageOnFail:"Failed spot check"
		logger's info("Passed")

	else if caseIndex is 4 then
		assertThat of std given condition:safariTab's selectorExists(".alert-danger") is false, messageOnFail:"Failed spot check"

		assertThat of std given condition:safariTab's selectorExists(".unit-wrapper") is true, messageOnFail:"Failed spot check"
		logger's info("Passed.")

	else if caseIndex is 5 then
		log sutTab's getCheckedById("activate_account_choice")

	else if caseIndex is 6 then
		log sutTab's getValue(".version-dd") -- cffiddle.org
	end if

	(*
	powered's waitForSelector("#as-search-input")
	powered's setValueById("as-search-input", "hello")
	*)

	spot's finish()
	logger's finish()
end spotCheck


-- Start of actual handlers ================

on decorate(safariTab)
	loggerFactory's injectBasic(me)

	script SafariJavaScriptDecorator
		property parent : safariTab

		(*
			Created because _runScript is bugged but it is widely used and I
			don't want to break the other uses. TODO: Unit Tests.
		*)
		on runScript(scriptText)
			try
				tell application "Safari"
					do JavaScript ("
						try {
							" & scriptText & "
						} catch(e) {
							e.message;
						}
					") in _tab of safariTab
				end tell
			end try -- Ignore when _tab is de-referenced.
		end runScript

		on runScriptPlain(scriptText)
			if scriptText does not end with ";" then set scriptText to scriptText & ";"
			try
				tell application "Safari" to return do JavaScript ("try {" & scriptText & "} catch(e) { e.message; }") in _tab of safariTab
			end try -- When _tab is de-referenced.
		end runScriptPlain


		on runScriptDirect(scriptText)
			tell application "Safari"
				do JavaScript scriptText in _tab of safariTab
			end tell
		end runScriptDirect
	end script
end decorate
