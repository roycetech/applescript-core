on new()
	script SpotTestStubInstance
		on setSessionCaseIndex(newCaseIndex)
		end setSessionCaseIndex
		
		(* 
		@pCaseId test case identifier.
		@pCases the list of test cases usually retrieved from the session.
	*)
		on new(pCaseId, pCases)
			script SpotTestCaseInstance
				
				(* @returns {caseId, caseDescription} *)
				on start()
				end start
				
				
				on setAutoIncrement(newValue)
				end setAutoIncrement
				
				
				on finish()
				end finish
			end script
		end new
	end script
end new
