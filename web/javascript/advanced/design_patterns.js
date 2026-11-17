/**
 * Advanced JavaScript: Design Patterns
 * 
 * Common architectural patterns implemented in modern JS.
 */

console.log("%c--- 1. Singleton Pattern ---", "color: #f1c40f; font-weight: bold;");

class DatabaseConnection {
    constructor() {
        if (DatabaseConnection.instance) {
            return DatabaseConnection.instance;
        }
        this.connectionString = "db://localhost:5432";
        DatabaseConnection.instance = this;
    }

    connect() {
        console.log(`Connecting to ${this.connectionString}...`);
    }
}

const db1 = new DatabaseConnection();
const db2 = new DatabaseConnection();

console.log("Are db1 and db2 the same instance?", db1 === db2); // true


console.log("\n%c--- 2. Observer (Pub/Sub) Pattern ---", "color: #f1c40f; font-weight: bold;");

class EventEmitter {
    constructor() {
        this.events = {};
    }

    on(event, listener) {
        if (!this.events[event]) {
            this.events[event] = [];
        }
        this.events[event].push(listener);
    }

    emit(event, ...args) {
        if (this.events[event]) {
            this.events[event].forEach(listener => listener(...args));
        }
    }

    off(event, listenerToRemove) {
        if (!this.events[event]) return;
        this.events[event] = this.events[event].filter(l => l !== listenerToRemove);
    }
}

const bus = new EventEmitter();
const onUserLogin = (user) => console.log(`Welcome, ${user}!`);

bus.on('login', onUserLogin);
bus.emit('login', 'Alice');
bus.off('login', onUserLogin);
bus.emit('login', 'Bob'); // Nothing happens


console.log("\n%c--- 3. Factory Pattern ---", "color: #f1c40f; font-weight: bold;");

class Developer {
    constructor(name) {
        this.name = name;
        this.type = "Developer";
    }
}

class Designer {
    constructor(name) {
        this.name = name;
        this.type = "Designer";
    }
}

class EmployeeFactory {
    static create(name, type) {
        switch(type) {
            case 1: return new Developer(name);
            case 2: return new Designer(name);
            default: return null;
        }
    }
}

const employees = [];
employees.push(EmployeeFactory.create("Alice", 1));
employees.push(EmployeeFactory.create("Bob", 2));

employees.forEach(emp => {
    console.log(`Employee: ${emp.name}, Type: ${emp.type}`);
});


console.log("\n%c--- 4. Decorator Pattern (Modern Class Decorators) ---", "color: #f1c40f; font-weight: bold;");

// Note: This is a conceptual implementation of the pattern using a wrapper function
function logMethod(target, key, descriptor) {
    const originalMethod = descriptor.value;
    descriptor.value = function(...args) {
        console.log(`Calling ${key} with:`, args);
        return originalMethod.apply(this, args);
    }
    return descriptor;
}

// In vanilla JS without build tools, we'd use a wrapper:
const withLogging = (obj, methodName) => {
    const original = obj[methodName];
    obj[methodName] = (...args) => {
        console.log(`[LOG] Calling ${methodName} with args:`, args);
        return original.apply(obj, args);
    };
};

const calculator = {
    add: (a, b) => a + b
};

withLogging(calculator, 'add');
console.log("Result:", calculator.add(5, 3));
