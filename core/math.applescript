(*
	Usage:
		use Math : script "core/math"

	@Project:
		applescript-core

	@Build:
		make build-lib SOURCE=core/math

	@Created: August 25, 2023 8:27 PM
	@Last Modified: 2023-09-30 17:55:49
*)

use framework "Foundation"
use scripting additions

use std : script "core/std"


on abs(value)
	std's ternary(value < 0, -value, value)
end abs