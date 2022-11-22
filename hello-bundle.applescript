use script "Core Text Utilities"
use scripting additions

set std to script "std"
set logger to std's import("logger")'s new("spot")
logger's start()

logger's info("Hello world")
set interpolated to format {"hello: {}", {"world"}}
logger's infof("interpolated: {}", interpolated)

logger's finish()