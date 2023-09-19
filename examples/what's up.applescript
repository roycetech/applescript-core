use loggerLib : script "core/logger"

property logger : loggerLib's new("what's up")

logger's info("Single quote in file name is not a problem ")
