(*
	Usage:
		use Math : script "math"

	@Created: August 25, 2023 8:27 PM
	@Last Modified: 2023-08-25 20:29:23
*)

use framework "Foundation"
use scripting additions

use std : script "std"


on abs(value)
	std's ternary(value < 0, -value, value)
end abs