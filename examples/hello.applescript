set std to script "std"
set logger to std's import("logger")'s new("hello")
set textUtil to std's import("string")

-- logger's start()

logger's info("Hello AppleScript Core!")

try
	-- 1 / 0
on error the errorMessage number the errorNumber
	std's catch("hello", errorNumber, errorMessage)
end try

-- logger's finish()
