(*
	Usage:
		See spotCheck

	Testing Template:
		use googlegoogleChromeLib : script "core/google-chrome"
		property googleChrome : googlegoogleChromeLib's new()

	@Plists
		config-system
			app-core Web Max Retry Count
			app-core Web Retry Sleep

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Google Chrome/133.0/google-chrome-javascript'

	@Created:
		Thu, Feb 13, 2025 at 10:18:10 AM

	@Change Logs:
 *)

use scripting additions

use script "core/Text Utilities"
use std : script "core/std"
use listUtil : script "core/list"

use configLib : script "core/config"
use retryLib : script "core/retry"
use googleChromeLib : script "core/google-chrome"

use loggerFactory : script "core/logger-factory"

property logger : missing value

property configSystem : missing value
property retry : missing value

property CONFIG_SYSTEM : "system"
property CONFIG_KEY_RETRY_MAX : "FIND_RETRY_SLEEP"
property CONFIG_KEY_RETRY_SLEEP : "FIND_RETRY_SLEEP"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()
	
	(* Tests are based on current apple.com website, very likely to change in the future. *)
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Manual: AWS Login, IAM Radio Option
		Manual: Link Text Visible
		Manual: Selector Exists
		Checked By ID
		Retrieve Value
		
		Manual: Run JavaScript
		Manual: Debug: Run JavaScript on Window
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set googleChrome to googleChromeLib's new()
	-- set safariTab to safari's newTab("https://www.apple.com")
	
	set googleChromeTab to googleChrome's getFrontTab()
	-- For case 7: 
	(*
	beep 1
	delay 2 -- Manually pick another window.
	beep 1 -- Focused window must not be the initial chat window	
	*)
	set googleChromeTab to decorate(googleChromeTab)
	
	tell googleChromeTab
		set its findRunMax to 3
		set its findRetrySleep to 1
	end tell
	googleChromeTab's focus()
	googleChromeTab's waitForPageLoad()
	
	if caseIndex is 1 then
		-- logger's infof("Selector Exists: {}",
		log googleChromeTab's selectorExists("#iam_user_radio_button")
		log googleChromeTab's selectorExists("#account")
		-- )
		
	else if caseIndex is 2 then
		set jsResult to googleChromeTab's linkTextVisible("Learn more")
		assertThat of std given condition:jsResult is true, messageOnFail:"Failed spot check"
		set jsFalseResult to safariTab's linkTextVisible("Learn nothing")
		assertThat of std given condition:jsFalseResult is false, messageOnFail:"Failed spot check"
		logger's info("Passed")
		
	else if caseIndex is 3 then
		assertThat of std given condition:googleChromeTab's selectorExists(".alert-danger") is false, messageOnFail:"Failed spot check"
		
		assertThat of std given condition:googleChromeTab's selectorExists(".unit-wrapper") is true, messageOnFail:"Failed spot check"
		logger's info("Passed.")
		
	else if caseIndex is 4 then
		log sutTab's getCheckedById("activate_account_choice")
		
	else if caseIndex is 5 then
		log sutTab's getValue(".version-dd") -- cffiddle.org
		
	else if caseIndex is 6 then
		-- googleChromeTab's runScript("alert(1);")
		log googleChromeTab's runScript("document.querySelector(`frame[name='mainFrame']`)?.contentDocument.documentElement.outerHTML")
		
	else if caseIndex is 7 then
		set buttonText to googleChromeTab's textContent("#call_button > span > span.button-vue__text")
		logger's infof("buttonText: {}", buttonText)
		
	end if
	
	(*
	powered's waitForSelector("#as-search-input")
	powered's setValueById("as-search-input", "hello")
	*)
	
	spot's finish()
	logger's finish()
end spotCheck


-- Start of actual handlers ================

on decorate(googleChromeTab)
	loggerFactory's injectBasic(me)
	set chrome to googleChromeLib's new()
	set configSystem to configLib's new(CONFIG_SYSTEM)
	set retry to retryLib's new()
	
	script ChromeJavaScriptDecorator
		property parent : googleChromeTab
		property findRunMax : 0
		property findRetrySleep : 0
		
		on getValue(selector)
			set scriptText to format {"document.querySelector('{}').value", {selector}}
			runScript(scriptText)
		end getValue
		
		on getFirstValue(selector)
			set scriptText to format {"document.querySelectorAll('{}')[0].value", {selector}}
			runScript(scriptText)
		end getFirstValue
		
		on getLastValue(selector)
			set scriptText to format {"var result = document.querySelectorAll('{}');result[result.length-1].value", {selector}}
			runScript(scriptText)
		end getLastValue
		
		on getValueByName(elementName)
			set scriptText to format {"document.getElementsByName('{}')[0].value", {elementName}}
			_runScript(scriptText)
		end getValueByName
		
		on getCheckedById(elementId)
			set scriptText to format {"document.getElementById('{}').checked", elementId}
			_runScript(scriptText)
		end getCheckedById
		
		on getCheckedByName(elementName)
			set scriptText to format {"document.getElementsByName('{}')[0].checked", elementName}
			_runScript(scriptText)
		end getCheckedByName
		
		on hasValue(selector)
			set scriptText to format {"document.querySelector('{}').value != ''", {selector}}
			_runScript(scriptText)
		end hasValue
		
		on setValueByName(elementName, theValue)
			set scriptText to format {"document.getElementsByName('{}')[0].value = '{}';", {elementName, theValue}}
			runScriptPlain(scriptText)
		end setValueByName
		
		on setValueBySelector(selector, theValue)
			set scriptText to format {"document.querySelector('{}').value = '{}'", {selector, theValue}}
			runScriptPlain(scriptText)
		end setValueBySelector
		
		on selectRadioByName(elementName, radioValue)
			set scriptText to format {"document.getElementsByName('{}')
				.forEach(function(element) {
					if (element.value == '{}') {element.checked=true;}
				})", {elementName, radioValue}}
			runScriptPlain(scriptText)
		end selectRadioByName
		
		on setSelectedIndexByName(elementName, idx)
			runScriptPlain(format {"document.getElementsByName('{}')[0].selectedIndex = {};", {elementName, idx}})
		end setSelectedIndexByName
		
		on setValueById(elementId, theValue)
			set scriptText to format {"document.getElementById('{}').value = `{}`;", {elementId, theValue}}
			runScriptPlain(scriptText)
		end setValueById
		
		on setCheckedById(elementId, theValue as boolean)
			set checkedScript to format {"document.getElementById('{}').checked", elementId}
			set scriptText to format {"{} = {}", {checkedScript, theValue}}
			script EnsureCheck
				runScriptPlain(scriptText)
				if _runScript(checkedScript) as boolean is equal to theValue then return true
			end script
			exec of retry on result for 3
		end setCheckedById
		
		on setCheckedByName(elementName, theValue as boolean)
			set checkedScript to format {"document.getElementsByName('{}')[0].checked", elementName}
			set scriptText to format {"{} = {}", {checkedScript, theValue}}
			script EnsureCheck
				-- runScriptPlain(scriptText)
				runScript(scriptText)
				if _runScript(checkedScript) as boolean is equal to theValue then return true
			end script
			exec of retry on result for 3
		end setCheckedByName
		
		on click(selector)
			runScriptPlain(format {"document.querySelector('{}').click();", selector})
		end click
		
		on clickByIndex(selector, idx)
			runScriptPlain(format {"document.querySelectorAll('{}')[{}].click();", {selector, idx}})
		end clickByIndex
		
		on clickById(elementId)
			runScriptPlain(format {"document.getElementById('{}').click();", elementId})
		end clickById
		
		on clickByName(elementName)
			runScriptPlain(format {"document.getElementsByName('{}')[0].click();", elementName})
		end clickByName
		
		on clickByNameAndIndex(elementName, idx)
			runScriptPlain(format {"document.getElementsByName('{}')[{}].click();", {elementName, idx}})
		end clickByNameAndIndex
		
		on clickLinkByText(linkText)
			set scriptText to format {"Array.prototype.filter.call(
				document.querySelectorAll('a'),
				function(element) {
					return element.textContent.trim() === '{}';
				})[0].click()", linkText}
			runScriptPlain(scriptText)
			delay 0.1
		end clickLinkByText
		
		(* @idx starts with 0 *)
		on clickLinkByTextAndIndex(linkText, idx)
			set scriptText to format {"Array.prototype.filter.call(
				document.querySelectorAll('a'),
				function(element) {
					return element.textContent.trim() === '{}';
				})[{}].click()", {linkText, idx}}
			runScriptPlain(scriptText)
		end clickLinkByTextAndIndex
		
		on clickHrefMatching(hrefPart)
			set scriptText to format {"document.querySelector(\"a[href*='{}']\").click()", hrefPart}
			runScriptPlain(scriptText)
			delay 0.1
		end clickHrefMatching
		
		on hrefPartExists(hrefPart)
			set scriptText to format {"document.querySelector(\"a[href*='{}']\") !== null", hrefPart}
			_runScript(scriptText)
		end hrefPartExists
		
		on linkTextExists(linkText)
			set scriptText to format {"Array.prototype.filter.call(
				document.querySelectorAll('a'),
				function(element) {
					return element.textContent.trim() === '{}';
				}).length > 0", linkText}
			_runScript(scriptText)
		end linkTextExists
		
		on waitForLinkText(linkText)
			script LinkWaiter
				if linkTextExists(linkText) then return true
			end script
			exec of retry on result for findRunMax by findRetrySleep
		end waitForLinkText
		
		on waitForHrefPart(hrefPart)
			script HrefWaiter
				if hrefPartExists(hrefPart) then return true
			end script
			
			exec of retry on HrefWaiter for 1 * minutes by 1
		end waitForHrefPart
		
		on focusOnId(elementId)
			runScriptPlain(format {"document.getElementById('{}').focus();", elementId})
		end focusOnId
		
		on focusSelector(selector)
			runScriptPlain(format {"document.querySelector('{}').focus();", selector})
		end focusSelector
		
		(*
			@selectors selector or list of selectors

			@return the first selector found to exist.  missing value if it times out.
		*)
		on waitForSelector(selectors)
			if class of selectors is list then
				-- logger's debug("Received list: " & selectors)
				set selectorList to selectors
			else
				-- logger's debug("Received text: " & selectors)
				set selectorList to {selectors}
			end if
			
			script SelectorWaiter
				repeat with nextSelector in selectorList
					set scriptText to format {"document.querySelector('{}') !== null", nextSelector}
					if _runScript(scriptText) is true then return nextSelector
				end repeat
			end script
			exec of retry on SelectorWaiter for findRunMax by findRetrySleep
		end waitForSelector
		
		on waitForNoSelector(selector)
			script SelectorWaiter
				set scriptText to format {"document.querySelector('{}') === null", selector}
				if _runScript(scriptText) is true then return selector
			end script
			exec of retry on SelectorWaiter for findRunMax by findRetrySleep
		end waitForNoSelector
		
		(* *)
		on selectorExists(selector)
			set scriptText to format {"document.querySelector('{}') !== null", selector}
			try
				return _runScript(scriptText)
			end try
			false
		end selectorExists
		
		(* *)
		on namedElementExists(elementName)
			set scriptText to format {"document.getElementsByName('{}').length > 0", elementName}
			runScript(scriptText)
		end namedElementExists
		
		on textContent(selector)
			set scriptText to format {"document.querySelector('{}').textContent.trim()", selector}
			runScriptPlain(scriptText)
		end textContent
		
		on attribute(selector, attributeName)
			set scriptText to format {"document.querySelector('{}')['{}']", {selector, attributeName}}
			runScriptPlain(scriptText)
		end attribute
		
		on waitForTrueExpression(expression)
			set scriptText to expression
			script TruthWaiter
				if _runScript(scriptText) then return true
			end script
			
			set waitResult to exec of retry on TruthWaiter for findRunMax by findRetrySleep
			if waitResult is missing value then return false
			
			return waitResult
		end waitForTrueExpression
		
		on selectorVisible(selectors)
			if class of selectors is list then
				set selectorList to selectors
			else
				set selectorList to {selectors}
			end if
			
			repeat with nextSelector in selectorList
				if isSelectorVisible(nextSelector) then return nextSelector
			end repeat
			false
		end selectorVisible
		
		on isSelectorVisible(selector)
			set scriptText to format {"document.querySelector('{}') !== null &&
				document.querySelector('{}')
				.offsetParent !== null", {selector, selector}}
			_runScript(scriptText)
		end isSelectorVisible
		
		(*
			Checks if a link text (text inside the anchor tags <a></a>) is visible by checking its offsetParent. Leading and trailing spaces are ignored.)

			NOTE: Make sure that the page is completely loaded before you invoke this handler.
		*)
		on linkTextVisible(linkText)
			set scriptText to format {"
				var temp = Array.prototype.filter.call(
					document.querySelectorAll('a'),
					function(element) { return element.textContent.trim() === '{}'; }
				);
				var jsResult = temp.length > 0 && temp[0].offsetParent !== null;
				jsResult ? 'true' : 'false';
			", linkText}
			
			set runScriptResult to runScriptPlain(scriptText)
			if runScriptResult is equal to "true" then return true
			if runScriptResult is equal to "false" then return false
			
			missing value
		end linkTextVisible
		
		(*
			@return the first selector that is determined to be visible.
		*)
		on waitToBeVisible(selectors)
			if class of selectors is list then
				set selectorList to selectors
			else
				set selectorList to {selectors}
			end if
			
			script VisibilityWaiter
				repeat with nextSelector in selectorList
					set scriptText to format {"document.querySelector('{}') !== null &&
						document.querySelector('{}')
						.offsetParent !== null", {nextSelector, nextSelector}}
					if _runScript(scriptText) is true then return nextSelector
				end repeat
			end script
			exec of retry on VisibilityWaiter for findRunMax by findRetrySleep
		end waitToBeVisible
		
		(*
			@return true if selector is invisible.
		*)
		on waitToBeInvisible(selector as text)
			script VisibilityWaiter
				set scriptText to format {"document.querySelector('{}') == null ||
					document.querySelector('{}')
					.offsetParent == null", {selector, selector}}
				if _runScript(scriptText) is true then return true
			end script
			(exec of retry on VisibilityWaiter for findRunMax by findRetrySleep) is equal to true
		end waitToBeInvisible
		
		(*
			Created because _runScript is bugged but it is widely used and I
			don't want to break the other uses. TODO: Unit Tests.
		*)
		on runScript(scriptText)
			tell application "Google Chrome" to tell (my appWindow)
				tell active tab
					execute javascript scriptText
				end tell
			end tell
		end runScript
		
		(*
			@returns result of the javascript.
		*)
		on _runScript(scriptText)
			set montereyFix to "var jsresult = (" & scriptText & ");if (typeof(jsresult) === 'boolean') { jsresult ? 'true' : 'false'} else jsresult;"
			set runScriptResult to runScriptPlain(montereyFix)
			if runScriptResult is equal to "true" then return true
			if runScriptResult is equal to "false" then return false
			
			runScriptResult
		end _runScript
		
		on runScriptPlain(scriptText)
			if scriptText does not end with ";" then set scriptText to scriptText & ";"
			tell application "Google Chrome" to tell (my appWindow)
				tell active tab
					return execute javascript ("try {" & scriptText & "} catch(e) { e.message; }")
				end tell
			end tell
		end runScriptPlain
		
		on submitFirstForm()
			runScriptPlain("document.querySelector('form').submit()")
		end submitFirstForm
	end script
	
	set findRunMax of ChromeJavaScriptDecorator to configSystem's getValue(CONFIG_KEY_RETRY_MAX)
	set findRetrySleep of ChromeJavaScriptDecorator to configSystem's getValue(CONFIG_KEY_RETRY_SLEEP)
	ChromeJavaScriptDecorator
end decorate
