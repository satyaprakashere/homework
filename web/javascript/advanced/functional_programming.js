/**
 * Advanced JavaScript: Functional Programming Patterns
 * 
 * Composition, Currying, and Higher-Order Functions.
 */

console.log("%c--- 1. Function Currying ---", "color: #1abc9c; font-weight: bold;");

const curry = (fn) => {
    return function curried(...args) {
        if (args.length >= fn.length) {
            return fn.apply(this, args);
        } else {
            return function(...args2) {
                return curried.apply(this, args.concat(args2));
            }
        }
    };
};

const sum = (a, b, c) => a + b + c;
const curriedSum = curry(sum);

console.log("curriedSum(1)(2)(3):", curriedSum(1)(2)(3));
console.log("curriedSum(1, 2)(3):", curriedSum(1, 2)(3));


console.log("\n%c--- 2. Function Composition ---", "color: #1abc9c; font-weight: bold;");

const compose = (...fns) => (x) => fns.reduceRight((v, f) => f(v), x);
const pipe = (...fns) => (x) => fns.reduce((v, f) => f(v), x);

const add1 = (x) => x + 1;
const double = (x) => x * 2;
const square = (x) => x * x;

// (5 * 5) * 2 + 1 = 51
const computeCompose = compose(add1, double, square);
// ((5 + 1) * 2) ^ 2 = 144
const computePipe = pipe(add1, double, square);

console.log("Compose Result (5):", computeCompose(5));
console.log("Pipe Result (5):", computePipe(5));


console.log("\n%c--- 3. Partial Application ---", "color: #1abc9c; font-weight: bold;");

const partial = (fn, ...fixedArgs) => {
    return function(...remainingArgs) {
        return fn.apply(this, fixedArgs.concat(remainingArgs));
    };
};

const log = (level, time, message) => console.log(`[${level}] at ${time}: ${message}`);

const logErrorNow = partial(log, "ERROR", new Date().toLocaleTimeString());
logErrorNow("Something went wrong!");


console.log("\n%c--- 4. Monadic-like Chains (Optional Chaining & Nullish Coalescing) ---", "color: #1abc9c; font-weight: bold;");

const user = {
    profile: {
        settings: {
            theme: 'dark'
        }
    }
};

const theme = user?.profile?.settings?.theme ?? 'default';
const fontSize = user?.profile?.style?.fontSize ?? 16;

console.log("Theme:", theme);
console.log("Font Size:", fontSize);
