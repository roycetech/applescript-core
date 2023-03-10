global std

use script "Core Text Utilities"
use scripting additions

property initialized : false

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
  init()
  set thisCaseId to "chrome-spotCheck"

  -- If you haven't got these imports already.
	set listUtil to std's import("list")

  set cases to listUtil's splitByLine("
    Manual: New Window
  ")

  set spotLib to std's import("spot-test")'s new()
  set spot to spotLib's new(thisCaseId, cases)

  set {caseIndex, caseDesc} to spot's start()

  if caseIndex is 0 then
    return
  end if

  set sut to new()

  if caseIndex is 1 then
    sut's newWindow("https://www.example.com")
  end if
  
end spotCheck

on new()
  script ChromeInstance
    on newWindow(targetUrl)
      tell application "Google Chrome"
        activate
        set newWindow to make new window
        set URL of active tab of newWindow to "https://www.example.com/"
      end tell
    end newWindow
  end script
end new

(* Constructor. When you need to load another library, do it here. *)
on init()
  if initialized of me then return
	set initialized of me to true

  set std to script "std"
end init
