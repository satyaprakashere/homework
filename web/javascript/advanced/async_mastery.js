/**
 * Advanced JavaScript: Async Mastery
 * 
 * Beyond basic async/await. Handling multiple promises, cancellation, and error boundaries.
 */

const delay = (ms, value, shouldReject = false) => 
    new Promise((resolve, reject) => 
        setTimeout(() => shouldReject ? reject(`Error: ${value}`) : resolve(value), ms)
    );

console.log("%c--- 1. Promise Combinators ---", "color: #e67e22; font-weight: bold;");

async function combinatorsDemo() {
    console.log("Starting Promise.allSettled demo...");
    
    // Promise.allSettled never rejects, it returns an array of results with status
    const results = await Promise.allSettled([
        delay(100, "First Success"),
        delay(200, "Second Success"),
        delay(150, "Failure", true)
    ]);
    
    console.log("All Settled Results:", results);

    console.log("\nStarting Promise.any demo...");
    try {
        // Returns the first fulfilled promise
        const firstSuccess = await Promise.any([
            delay(300, "Slow Success"),
            delay(100, "Fast Success"),
            delay(50, "Fast Error", true)
        ]);
        console.log("First Success found by Promise.any:", firstSuccess);
    } catch (e) {
        console.log("All promises were rejected");
    }
}

combinatorsDemo();


console.log("\n%c--- 2. Async Iteration (for await...of) ---", "color: #e67e22; font-weight: bold;");

async function* asyncGenerator() {
    yield await delay(500, "Batch 1");
    yield await delay(500, "Batch 2");
    yield await delay(500, "Batch 3");
}

(async () => {
    for await (const val of asyncGenerator()) {
        console.log("Received via async iteration:", val);
    }
})();


console.log("\n%c--- 3. Handling Concurrent Limits (Simple Batching) ---", "color: #e67e22; font-weight: bold;");

async function batchProcess(items, batchSize, processFn) {
    const results = [];
    for (let i = 0; i < items.length; i += batchSize) {
        const batch = items.slice(i, i + batchSize);
        console.log(`Processing batch starting at index ${i}...`);
        const batchResults = await Promise.all(batch.map(processFn));
        results.push(...batchResults);
    }
    return results;
}

const itemsToProcess = [1, 2, 3, 4, 5, 6, 7, 8];
batchProcess(itemsToProcess, 3, (item) => delay(200, `Processed ${item}`))
    .then(res => console.log("Batch Process Completed:", res));


console.log("\n%c--- 4. AbortController (Request Cancellation) ---", "color: #e67e22; font-weight: bold;");

function fetchWithTimeout(url, timeoutMs) {
    const controller = new AbortController();
    const id = setTimeout(() => controller.abort(), timeoutMs);

    return fetch(url, { signal: controller.signal })
        .then(response => {
            clearTimeout(id);
            return response.json();
        })
        .catch(err => {
            if (err.name === 'AbortError') {
                console.log('Fetch aborted due to timeout');
            } else {
                throw err;
            }
        });
}

// fetchWithTimeout('https://jsonplaceholder.typicode.com/posts/1', 10).catch(() => {});
