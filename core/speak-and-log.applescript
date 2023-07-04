
		on emitSynchronously(rawTex)
			logger's info(rawText)
			speakSynchronously(rawText)
		end speakSynchronouslyWithLogging


		on emit(rawText)
			speak(rawText)
			if synchronous then
				set prefix to "S+ "
			else
				set prefix to "S* "
			end if
			
			logger's info(prefix & rawText)
		end speakAndLog
