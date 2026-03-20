package tests

import "core:testing"

@(test)
maps :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/maps.scm")
}

@(test)
map_full :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/map_test.scm")
}
