(*
	@Purpose:
		Read secrets from a .env file.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/Level_4/dotenv

	@Created: Sat, Mar 14, 2026 at 02:11:57 PM
	@Last Modified: Tue, Nov 17, 2026

	@Change Logs:
		Tue, Nov 17, 2026 - Keep the full value after the first equals so URLs with query parameters stay intact.
*)
use scripting additions

use fileUtil : script "core/file"
use listUtil : script "core/list"
use mapLib : script "core/map"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"



property logger : missing value

if {"Script Editor", "Script Debugger", "osascript"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		NOOP
		Manual: Read Key
		Value after first equals
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

	set sut to new("~/.env.personal")
	if caseIndex is 1 then

	else if caseIndex is 2 then
		set sutKeyName to "Unicorn"
		set sutKeyName to "SERVICE_NAME"
		logger's debugf("sutKeyName: {}", sutKeyName)

		logger's infof("Key name: {}, value: {}", {sutKeyName, sut's getValue(sutKeyName)})

	else if caseIndex is 3 then
		set testEnvPath to "/tmp/dotenv-spot.env"
		do shell script "printf '%s\\n' 'PLAIN=hello' 'URL=https://example.com/path?team=T1&id=D2' > " & quoted form of testEnvPath
		set sut to new(testEnvPath)
		logger's infof("PLAIN: {}", sut's getValue("PLAIN"))
		logger's infof("URL: {}", sut's getValue("URL"))

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new(pDotEnvFilePath)
	loggerFactory's inject(me)
	if fileUtil's posixFilePathExists(pDotEnvFilePath) is false then
		error "Dotenv file does not exist: " & pDotEnvFilePath
	end if

	script DotenvInstance
		property dotEnvFilePath : fileUtil's untilde(pDotEnvFilePath)
		property envMap : mapLib's new()

		on load()
			set dotEnvFileContents to fileUtil's readFile(POSIX file (my dotEnvFilePath))
			set envLines to paragraphs of dotEnvFileContents
			repeat with nextLine in envLines
				set nextLine to textUtil's trim(nextLine)
				if nextLine is not "" and nextLine does not start with "#" and nextLine contains "=" then
					set nextKey to textUtil's trim(textUtil's stringBefore(nextLine, "="))
					if nextKey is missing value or nextKey is "" then
						-- Skip malformed lines that start with "=".
					else
						if nextLine ends with "=" then
							set nextValue to ""
						else
							set nextValue to textUtil's trim(textUtil's stringAfter(nextLine, "="))
						end if
						envMap's putValue(nextKey, nextValue)
					end if
				end if
			end repeat
		end load


		on getValue(keyName)
			if keyName is missing value then return missing value
			if keyName is "" then return missing value

			envMap's getValue(keyName)
		end getValue
	end script

	set instance to result
	instance's load()
	instance

end new
