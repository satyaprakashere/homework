.PHONY: build run test test-features

build:
	mkdir -p out
	mkdir -p out/logs
	odin build core -out:out/rekursion

run: build
	./out/rekursion

clean:
	rm -rf ./out

test:
	mkdir -p out
	mkdir -p out/logs
	odin test tests -out:out/rekursion_test -define:ODIN_TEST_THREADS=1

test-features: build
	cat tests/cases/actor.scm | out/rekursion
# 	cat tests/cases/continuations.scm | out/rekursion
# 	cat tests/cases/quotes.scm | out/rekursion
# 	cat tests/cases/aliasing.scm | out/rekursion
# 	cat tests/cases/lambda.scm | out/rekursion
# 	cat tests/cases/functions.scm | out/rekursion
# 	cat tests/cases/r5rs.scm | out/rekursion

# 	for f in tests/cases/*.scm; do \
# 		echo "Running $$f..."; \
# 		cat $$f | ./out/rekursion; \
# 	done

build-wasm:
	odin build core -out:out/rekursion_wasm -target:wasi_wasm32
run-wasm: build-wasm
	./out/rekursion_wasm
test-wasm: build-wasm
	odin test tests -out:out/rekursion_test_wasm -define:ODIN_TEST_THREADS=1 -target:wasi_wasm32