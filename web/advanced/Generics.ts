interface Container<T> {
    value: T;
    getValue(): T;
}

class NumberContainer implements Container<number> {
    constructor(public value: number) {}
    getValue() { return this.value; }
}

function runDemo() {
    console.log("\n--- 1. TypeScript Generics Demo ---");
    const c = new NumberContainer(42);
    console.log(`Value: ${c.getValue()}`);
}

runDemo()