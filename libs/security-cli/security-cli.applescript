(*
	@Purpose:
		Securely store secrets in the default keychain.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh libs/security-cli/security-cli

	@Created: Thu, May 15, 2025 at 06:39:33 AM
	@Last Modified: 2025-09-26 11:34:00
*)
use scripting additions

use script "core/Text Utilities"

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Create a secret
		Manual: Retrieve a secret
		Manual: First Username
		Manual: First Secret

		Dummy
		Dummy
		Dummy
		Dummy
		Manual: Delete a secret
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

	set sutServiceName to "spot-service"
	set sutUsername to "spot-username"
	set sutSecret to "spot-secret"

	-- [Start] Create new secret.
	-- Do not commit anything between the [Start] and [End]

	-- [End] Create new secret

	logger's infof("sutServiceName: {}", sutServiceName)
	logger's infof("sutUsername: {}", sutUsername)
	logger's infof("sutSecret: {}", sutSecret)

	if caseIndex is 1 then

	else if caseIndex is 2 then
		logger's infof("Handler result: {}", sut's createSecret(sutServiceName, sutUsername, sutSecret))

	else if caseIndex is 3 then
		logger's infof("Secret exposed: {}", sut's getSecret(sutServiceName, sutUsername))

	else if caseIndex is 4 then
		logger's infof("First username: {}", sut's getFirstUsername(sutServiceName))

	else if caseIndex is 5 then
		logger's infof("First secret: {}", sut's getFirstSecret(sutServiceName))

	else if caseIndex is 10 then
		logger's infof("Handler result: {}", sut's deleteSecret(sutServiceName, sutUsername))

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)

	script SecurityCliInstance
		(*
			Use this on an ad hoc basis only to avoid committing passwords in the version control.

			@returns true on successful creation.
		*)
		on createSecret(serviceName, username, secret)
			set command to format {"security add-generic-password \\
			    -s {} \\
			    -a {} \\
			    -w {}", {serviceName, username, secret}}
			try
				do shell script command
				return true
			end try

			false
		end createSecret


		on getFirstSecret(serviceName)
			getSecret(serviceName, getFirstUsername(serviceName))
		end getFirstSecret


		on getFirstUsername(serviceName)
			set command to format {"security find-generic-password \\
			-s '{}' \\
			-g 2>&1 \\
			| grep 'acct' \\
			| awk -F= '{ print $2 }' \\
			| tr -d '\"'", {serviceName}}
			try
				return do shell script command
			end try

			missing value
		end getFirstUsername


		on getSecret(serviceName, username)
			set command to format {"security find-generic-password \\
			    -s {} \\
			    -a {} \\
			    -w", {serviceName, username}}
			try
				return do shell script command
			end try

			missing value
		end getSecret


		(*
			@returns true on successful operation.
		*)
		on deleteSecret(serviceName, username)
			set command to format {"security delete-generic-password \\
			    -s {} \\
			    -a {}
			", {serviceName, username}}

			try
				do shell script command
				return true
			end try

			false
		end deleteSecret
	end script
end new
