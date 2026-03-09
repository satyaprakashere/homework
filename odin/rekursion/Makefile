.PHONY: build run test test-features

build:
	mkdir -p out
	mkdir -p out/logs
	odin build core -out:out/rekursion

run:
	build
	./out/rekursion

clean:
	rm -rf ./out

test:
	mkdir -p out
	mkdir -p out/logs
	odin test tests -out:out/rekursion_test

test-features: build
	cat tests/cases/aliasing.scm 		 | ./out/rekursion
	cat tests/cases/function.scm 		 | ./out/rekursion
	cat tests/cases/lambda.scm 		 	 | ./out/rekursion
	cat tests/cases/continuations.scm 	 | ./out/rekursion
	cat tests/cases/arrays.scm 	 		 | ./out/rekursion
	cat tests/cases/tables.scm 	 		 | ./out/rekursion
	cat tests/cases/variadic.scm 		 | ./out/rekursion
	cat tests/cases/actor_test.scm 		 | ./out/rekursion
