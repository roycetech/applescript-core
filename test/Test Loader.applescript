(*!
	@header
	@abstract
		Template test loader.
	@charset macintosh
	@CReated 
*)
property parent : script "com.lifepillar/ASUnit"

tell application "Finder"
	set coreTestFolder to folder "core" of folder of file (path to me)
end tell

set suite to makeTestLoader()'s loadTestsFromFolder(coreTestFolder)
autorun(suite)
 