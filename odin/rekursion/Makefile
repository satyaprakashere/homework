.PHONY: build run test test-features

build:
	odin build core -out:out/rekursion

run:
	build
	./out/rekursion

clean:
	rm -rf ./out

test:
	odin test tests -out:out/rekursion_test

test-features: build
	cat tests/cases/functions.scm 		 | ./out/rekursion
	cat tests/cases/lambda.scm 		 	 | ./out/rekursion
	cat tests/cases/continuations.scm 	 | ./out/rekursion
	cat tests/cases/arrays.scm 	 		 | ./out/rekursion
	cat tests/cases/tables.scm 	 		 | ./out/rekursion
	cat tests/cases/variadic.scm 		 | ./out/rekursion
