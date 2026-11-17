/**
 * Advanced JavaScript: Proxies and Reflection
 * 
 * Proxies allow you to intercept and customize operations performed on objects.
 */

console.log("%c--- 1. Validation Proxy ---", "color: #9b59b6; font-weight: bold;");

const userSchema = {
    name: "string",
    age: "number",
    email: "string"
};

const validator = {
    set(target, prop, value) {
        if (prop in userSchema) {
            if (typeof value !== userSchema[prop]) {
                throw new TypeError(`Property ${prop} must be a ${userSchema[prop]}`);
            }
        }
        
        if (prop === 'age' && value < 0) {
            throw new RangeError("Age cannot be negative");
        }

        return Reflect.set(target, prop, value);
    }
};

const user = new Proxy({}, validator);

user.name = "John Doe";
user.age = 30;
console.log("User Object:", user);

try {
    user.age = "thirty"; // Throws TypeError
} catch (e) {
    console.error("Caught error:", e.message);
}


console.log("\n%c--- 2. Building a Reactive State (Mini-Observer) ---", "color: #9b59b6; font-weight: bold;");

function createReactiveObject(initialState, callback) {
    return new Proxy(initialState, {
        set(target, prop, value) {
            const oldValue = target[prop];
            const result = Reflect.set(target, prop, value);
            if (oldValue !== value) {
                callback(prop, value, oldValue);
            }
            return result;
        }
    });
}

const state = createReactiveObject({ count: 0, theme: 'light' }, (prop, val, old) => {
    console.log(`State change detected! [${prop}]: ${old} -> ${val}`);
});

state.count++;
state.theme = 'dark';


console.log("\n%c--- 3. Negative Indexing for Arrays ---", "color: #9b59b6; font-weight: bold;");

const wrapArray = (arr) => new Proxy(arr, {
    get(target, prop) {
        if (typeof prop === 'string') {
            const index = Number(prop);
            if (index < 0) {
                return target[target.length + index];
            }
        }
        return Reflect.get(target, prop);
    }
});

const myArr = wrapArray(['A', 'B', 'C', 'D']);
console.log("Last element (myArr[-1]):", myArr[-1]); // 'D'
console.log("Second to last (myArr[-2]):", myArr[-2]); // 'C'


console.log("\n%c--- 4. Reflection API Basics ---", "color: #9b59b6; font-weight: bold;");

const obj = { a: 1 };
Reflect.defineProperty(obj, 'b', { value: 2, enumerable: true });
console.log("Has 'a'?", Reflect.has(obj, 'a'));
console.log("Keys:", Reflect.ownKeys(obj));
