(*
	@Purpose:
		A scratchpad for testing and development.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh scratch
*)

if {"Script Editor", "Script Debugger", "osascript"} contains the name of current application then spotCheck()

on spotCheck()
    log "What will you test today?"
end spotCheck