package tests

import "core:testing"

@(test)
actor :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/actor.scm", []string{"lib/actor.scm"})
}
