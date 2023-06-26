use script "Core Text Utilities"
use scripting additions

use loggerLib : script "logger"

property logger : missing value

tell application "System Events" to set scriptName to get name of (path to me)

set my logger to loggerLib's new(scriptName)

logger's info("Hello world")
set interpolated to format {"hello: {}", {"world"}}
logger's infof("interpolated: {}", interpolated)
