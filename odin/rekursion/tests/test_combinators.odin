package tests

import "core:testing"

@(test)
test_combinators :: proc(t: ^testing.T) {
	run_scm_tests(
		t,
		"tests/cases/test_combinators.scm",
		{"lib/recursion.scm", "lib/combinator.scm", "lib/scheme.scm"},
	)
}
