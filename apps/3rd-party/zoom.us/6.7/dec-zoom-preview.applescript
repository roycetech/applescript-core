(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/zoom.us/6.7/dec-zoom-preview

	@Created: Mon, Mar 02, 2026 at 04:54:43 PM
	@Last Modified: 2026-03-24 17:31:36
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"

property logger : missing value

property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		Main
		Manual: Toggle Preview Mute
		Manual: Mute Preview
		Manual: Unmute Preview
		Manual: Popup camera

		Manual: Pick Popup camera
		Manual: Start meeting from Preview
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
	set sutLib to script "core/zoom"
	set sut to sutLib's new()
	set sut to decorate(sut)

	logger's infof("Audio: {}", sut's isPreviewAudioOn())
	logger's infof("Preview window present: {}", sut's isPreviewWindowPresent())

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's togglePreviewAudio()

	else if caseIndex is 3 then
		sut's mutePreview()

	else if caseIndex is 4 then
		sut's unmutePreview()

	else if caseIndex is 5 then
		sut's popupPreviewCamera()

	else if caseIndex is 6 then
		sut's popupPreviewCamera()
		-- sut's pickPreviewPopupCamera("iPhone")
		sut's pickPreviewPopupCameraByIndex(2)

	else if caseIndex is 7 then
		sut's startMeetingFromPreview()

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set kb to kbLib's new()

	script ZoomPreviewDecorator
		property parent : mainScript

		on getPreviewWindow()
			if running of application "zoom.us" is false then return missing value

			tell application "System Events" to tell process "zoom.us"
				try
				return first window whose title ends with " Zoom Meeting"
				end try
			end tell

			missing value
		end getPreviewWindow


		on isPreviewWindowPresent()
			getPreviewWindow() is not missing value
		end isPreviewWindowPresent


		on isPreviewAudioOn()
			set previewWindow to getPreviewWindow()
			if previewWindow is missing value then return false

			tell application "System Events" to tell process "zoom.us"
				try
					first button of tab group 1 of previewWindow whose description starts with "Audio"
					return description of result contains "turn off"
				end try
			end tell

			false
		end isPreviewAudioOn


		on togglePreviewAudio()
			set previewWindow to getPreviewWindow()
			if previewWindow is missing value then return false

			tell application "System Events" to tell process "zoom.us"
				try
					click (first button of tab group 1 of previewWindow whose description starts with "Audio")
				on error the errorMessage number the errorNumber
					log errorMessage
				end try
			end tell
		end togglePreviewAudio


		on mutePreview()
			if not isPreviewAudioOn() then return

			togglePreviewAudio()
		end mutePreview

		on unmutePreview()
			if isPreviewAudioOn() then return

			togglePreviewAudio()
		end unmutePreview


		on popupPreviewCamera()
			set previewWindow to getPreviewWindow()
			if previewWindow is missing value then return false

			tell application "System Events" to tell process "zoom.us"
				try
					set cameraPopup to second UI element of previewWindow whose role is "pop up button"
					click cameraPopup
					delay 0.5
					properties of row 2 of table 1 of scroll area 1 of window 1
				end try
			end tell
		end popupPreviewCamera


		-- on pickPreviewPopupCamera(cameraKey)  -- UI Element is not identifiable by name.
		on pickPreviewPopupCameraByIndex(cameraIndex)
			set calculatedIndex to cameraIndex + 1
			-- set uiutilLib to script "core/ui-util"
			-- set uiutil to uiutilLib's new()
			tell application "System Events" to tell process "zoom.us"
				try
					set selected of row calculatedIndex of table 1 of scroll area 1 of window 1 to true
					click UI element 1 of row calculatedIndex of table 1 of scroll area 1 of window 1
					-- uiutil's printAttributeValues(result)
				end try
			end tell
			kb's pressKey(return)
		end pickPreviewPopupCameraByIndex


		on startMeetingFromPreview()
			set previewWindow to getPreviewWindow()
			if previewWindow is missing value then return

			tell application "System Events" to tell process "zoom.us"
				click (first button of previewWindow whose description is "Start")
			end tell
		end startMeetingFromPreview
	end script
end decorate
