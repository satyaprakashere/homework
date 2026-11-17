"use strict";

class NumberContainer {
    value;
    constructor(value) {
        this.value = value;
    }
    getValue() { return this.value; }
}
function runDemo() {
    console.log("\n--- 1. JavaScript Generics Demo ---");
    const c = new NumberContainer(42);
    console.log(`Value: ${c.getValue()}`);
}
runDemo();
