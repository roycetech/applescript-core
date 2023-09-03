(*
	Utility for testing scripts that manages a property list file. This needs to
	be initialized in different places depending on when running via the test 
	via loader or as a single unit test. See "Test timed-cache-plist.applescript" 
	for example.

	@Created: July 22, 2023 10:58 PM
	@Last Modified: September 3, 2023 10:50 AM

	@Build:
		/usr/bin/osacompile -o "$HOME/Library/Script Libraries/core/test/xml-util.scpt" test/xml-util.applescript
*)
use scripting additions

use loggerFactory : script "logger-factory"

property logger : missing value

on newPlist(plistName)
	loggerFactory's inject(me)
	
	script XmlUtilInstance
		property plist : "~/applescript-core/" & plistName & ".plist"
		
		on __grepValueXml(keyName)
			set command to "key=\"" & keyName & "\";
				result=$(grep -A 1 \">$key<\" " & plist & " \\
					| tail -n 1 \\
					| awk '{$1=$1};1') \\
				&& if [[ \"$result\" != *\"/\"* ]]; then \\
					blockTagName=$(echo $result | sed -E 's/<([[:alpha:]]+)>/\\1/g');
					result=$(awk \"/>$key</,/<\\/$blockTagName>/\" " & plist & " \\
						| tail -n +2);
				fi;
				echo $result"
			do shell script command
		end __grepValueXml
		
		
		on __grepMultiLineValueXml(keyName, blockTagName)
			do shell script "awk '/>" & keyName & "</,/<\\/" & blockTagName & ">/' " & plist & " \\
				| tail -n +2"
		end __grepMultiLineValueXml
		
		
		on __readAllKeys()
			do shell script "/usr/libexec/PlistBuddy \\
				-c \"Print\" " & plist & " \\
			| grep -E '^\\s*[^[:space:]]+\\s*=' \\
			| awk '{print $1}'"
		end __readAllKeys
		
		
		on __readValue(keyName)
			try
				return do shell script "plutil -extract '" & keyName & "' raw " & plist
			end try
			missing value
		end __readValue
		
		
		on __writeString(keyName, newValue)
			__writeQuotedValue(keyName, "string", newValue)
		end __writeString
		
		(*
			@keyName - plist key name
			@xmlText - the XML value for the given key name.
		*)
		on __insertXml(keyName, xmlText)
			do shell script "plutil -insert '" & keyName & "' -xml '" & xmlText & "' " & plist
		end __insertXml
		
		(*
			NOTE: When writing nested values, do it one at a time. Root first then the
			nested key, otherwise it will fail.
		*)
		on __writeValue(keyName, keyType, newValue)
			do shell script "plutil -replace '" & keyName & "' -" & keyType & " " & newValue & " " & plist
		end __writeValue
		
		on __writeQuotedValue(keyName, keyType, newValue)
			try
				do shell script "plutil -replace '" & keyName & "' -" & keyType & " '" & newValue & "' " & plist
			end try
		end __writeQuotedValue
		
		on __deleteValue(keyName)
			try
				do shell script "plutil -remove '" & keyName & "' " & plist
			end try
		end __deleteValue
		
		on __createTestPlist()
			try
				do shell script "plutil -create xml1 " & plist
			end try
		end __createTestPlist
		
		on __deleteTestPlist()
			try
				do shell script "rm " & plist & " || true"
			end try
		end __deleteTestPlist
	end script
end newPlist