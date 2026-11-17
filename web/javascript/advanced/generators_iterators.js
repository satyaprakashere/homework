/**
 * Advanced JavaScript: Generators and Iterators
 * 
 * Generators are functions that can be paused and resumed, yielding values over time.
 */

console.log("%c--- 1. Simple Iterator Implementation ---", "color: #2ecc71; font-weight: bold;");

const range = {
    from: 1,
    to: 5,
    [Symbol.iterator]() {
        let current = this.from;
        const last = this.to;
        return {
            next() {
                if (current <= last) {
                    return { value: current++, done: false };
                } else {
                    return { done: true };
                }
            }
        };
    }
};

console.log("Iterating over custom range object:");
for (let num of range) {
    console.log(num);
}


console.log("\n%c--- 2. Generator Basics ---", "color: #2ecc71; font-weight: bold;");

function* fibonacciGenerator() {
    let [prev, curr] = [0, 1];
    while (true) {
        yield curr;
        [prev, curr] = [curr, prev + curr];
    }
}

const fib = fibonacciGenerator();
console.log("First 5 Fibonacci numbers:");
console.log(fib.next().value);
console.log(fib.next().value);
console.log(fib.next().value);
console.log(fib.next().value);
console.log(fib.next().value);


console.log("\n%c--- 3. Two-way Communication with Generators ---", "color: #2ecc71; font-weight: bold;");

function* conversation() {
    const name = yield "What is your name?";
    const color = yield `Nice to meet you, ${name}. What is your favorite color?`;
    yield `I love ${color} too, ${name}!`;
}

const chat = conversation();
console.log(chat.next().value);        // "What is your name?"
console.log(chat.next("Alice").value); // "Nice to meet you, Alice. What is your favorite color?"
console.log(chat.next("Blue").value);  // "I love Blue too, Alice!"


console.log("\n%c--- 4. Delegating Generators (yield*) ---", "color: #2ecc71; font-weight: bold;");

function* inner() {
    yield "Inner 1";
    yield "Inner 2";
}

function* outer() {
    yield "Outer Start";
    yield* inner();
    yield "Outer End";
}

for (let val of outer()) {
    console.log(val);
}
