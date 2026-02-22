.PHONY: build run test test-features

build:
	odin build src -out:out/rekursion

run: build
	./out/rekursion

test:
	odin test src -out:out/rekursion_test

test-features: build
<<<<<<< HEAD
	cat tests/tests.scm 		 | ./out/rekursion
=======
	cat tests/simple.scm 		 | ./out/rekursion
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)
# 	cat tests/tests_features.scm | ./out/rekursion
# 	cat tests/tests_arrays.scm 	 | ./out/rekursion
# 	cat tests/tests_tables.scm 	 | ./out/rekursion
# 	cat tests/tests_variadic.scm | ./out/rekursion
