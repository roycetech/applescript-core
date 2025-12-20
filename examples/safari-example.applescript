use safariLib : script "core/safari"

set safari to safariLib's new()

set safariTab to safari's newTab("https://example.com")
safariTab's runScript("alert('Hello from AppleScript');")
