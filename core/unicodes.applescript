global std, config

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

to spotCheck()
	init()
	logger's start()
	
	log my SEPARATOR
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
	set logger to std's import("logger")'s new("unicodes")
	set config to std's import("config")'s new("default")
	
	set WIFI to config's getValue("UNICODE_WIFI")
	set ELLIPSIS to config's getValue("UNICODE_ELLIPSIS")
	set SEPARATOR to config's getValue("UNICODE_SEP")
	set ARROW_LEFT to config's getValue("UNICODE_ARROW_LEFT")
	set ARROW_RIGHT to config's getValue("UNICODE_ARROW_RIGHT")
	set MAIL_SUBDASH to config's getValue("UNICODE_MAIL_SUBDASH")
	set OMZ_ARROW to config's getValue("UNICODE_OMZ_ARROW")
	set OMZ_GIT_X to config's getValue("UNICODE_OMZ_GIT_X")
end init
