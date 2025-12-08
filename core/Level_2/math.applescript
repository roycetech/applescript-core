(*
	Usage:
		use Math : script "core/math"

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/Level_2/math

	@Created: August 25, 2023 8:27 PM
	@Last Modified: 2024-09-21 12:14:08
*)

use framework "Foundation"
use scripting additions

use std : script "core/std"

on abs(value as number)
	std's ternary(value < 0, -value, value)
end abs