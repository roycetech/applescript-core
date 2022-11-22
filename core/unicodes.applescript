global std, logger, config

property initialized : false

-- spotCheck() -- IMPORTANT: Comment out on deploy

to spotCheck()
	init()
	logger's start("spotCheck")
	
	log my WORK
	log "App" & my APP_STORE_SPACE & "Store"
	
	logger's finish()
end spotCheck


property WIFI : missing value
property ELLIPSIS : missing value

(* Standard Mac OS Separator dash wrapped by space on both sides. *)
property SEPARATOR : missing value
property MAIL_SUBDASH : missing value
property ARROW_LEFT : missing value
property ARROW_RIGHT : missing value
property OMZ_ARROW : missing value
property OMZ_GIT_X : missing value
property APP_STORE_SPACE : ASCII character 202


-- Private Codes below =======================================================
(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")
	set config to std's import("config")
	
	set WIFI to config's getDefaultsValue("UNICODE_WIFI")
	set ELLIPSIS to config's getDefaultsValue("UNICODE_ELLIPSIS")
	set SEPARATOR to config's getDefaultsValue("UNICODE_SEP")
	set OMZ_ARROW to config's getDefaultsValue("UNICODE_OMZ_ARROW")
	set ARROW_LEFT to config's getDefaultsValue("UNICODE_ARROW_LEFT")
	set ARROW_RIGHT to config's getDefaultsValue("UNICODE_ARROW_RIGHT")
	set OMZ_GIT_X to config's getDefaultsValue("UNICODE_OMZ_GIT_X")
	set MAIL_SUBDASH to config's getDefaultsValue("UNICODE_MAIL_SUBDASH")
end init
