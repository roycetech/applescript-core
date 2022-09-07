set std to script "std"
set logger to std's import("logger")'s newInstance("hello")

logger's start()

logger's info("Hello AppleScript Core!")

logger's finish()
