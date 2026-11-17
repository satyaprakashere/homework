/**
 * Advanced JavaScript: Closures and Lexical Scope
 * 
 * A closure is the combination of a function bundled together (enclosed) with references 
 * to its surrounding state (the lexical environment).
 */

console.log("%c--- 1. The Module Pattern ---", "color: #3498db; font-weight: bold;");

const CounterModule = (function() {
    // Private variable
    let count = 0;

    // Private function
    function changeBy(val) {
        count += val;
    }

    // Public API
    return {
        increment() {
            changeBy(1);
        },
        decrement() {
            changeBy(-1);
        },
        value() {
            return count;
        }
    };
})();

CounterModule.increment();
CounterModule.increment();
console.log("Counter Value:", CounterModule.value()); // 2
CounterModule.decrement();
console.log("Counter Value after decrement:", CounterModule.value()); // 1
// console.log(CounterModule.count); // undefined (it's private!)


console.log("\n%c--- 2. Function Factories ---", "color: #3498db; font-weight: bold;");

function makeAdder(x) {
    return function(y) {
        return x + y;
    };
}

const add5 = makeAdder(5);
const add10 = makeAdder(10);

console.log("add5(2):", add5(2));  // 7
console.log("add10(2):", add10(2)); // 12


console.log("\n%c--- 3. Memory Efficient Memoization ---", "color: #3498db; font-weight: bold;");

function memoize(fn) {
    const cache = new Map();
    return function(...args) {
        const key = JSON.stringify(args);
        if (cache.has(key)) {
            console.log("Fetching from cache for:", key);
            return cache.get(key);
        }
        const result = fn.apply(this, args);
        cache.set(key, result);
        return result;
    };
}

const expensiveCalculation = memoize((n) => {
    console.log("Computing...");
    return n * n;
});

console.log(expensiveCalculation(5)); // Computing... 25
console.log(expensiveCalculation(5)); // Fetching from cache... 25


console.log("\n%c--- 4. Practical Closure: Event Throttling ---", "color: #3498db; font-weight: bold;");

function throttle(func, limit) {
    let inThrottle;
    return function() {
        const args = arguments;
        const context = this;
        if (!inThrottle) {
            func.apply(context, args);
            inThrottle = true;
            setTimeout(() => inThrottle = false, limit);
        }
    }
}

const throttledLog = throttle(() => console.log("Throttled log executed!"), 1000);
// If called multiple times quickly, it only runs once per second
throttledLog();
throttledLog();
throttledLog();
