package tests

import "core:testing"

@(test)
test_quotes :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/quotes.scm")
}
