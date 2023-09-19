(*
	Usage:
		use Math : script "core/math"

	@Created: August 25, 2023 8:27 PM
	@Last Modified: 2023-09-18 22:33:06
*)

use framework "Foundation"
use scripting additions

use std : script "core/std"


on abs(value)
	std's ternary(value < 0, -value, value)
end abs