package tests

import "core:testing"

@(test)
combinators :: proc(t: ^testing.T) {
	run_scm_tests(
		t,
		"tests/cases/combinators.scm",
		{"lib/recursion.scm", "lib/combinator.scm", "lang/scheme.scm"},
	)
}
