use script "Core Text Utilities"
use scripting additions

tell application "System Events" to set scriptName to get name of (path to me)
set std to script "std"
set logger to std's import("logger")'s new(scriptName)

logger's info("Hello world")
set interpolated to format {"hello: {}", {"world"}}
logger's infof("interpolated: {}", interpolated)
