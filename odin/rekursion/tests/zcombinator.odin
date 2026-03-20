package tests

import "core:testing"

@(test)
zcombinator :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/zcombinator.scm", {"lib/recursion.scm", "lib/combinator.scm"})
}
