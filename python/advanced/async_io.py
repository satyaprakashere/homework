import asyncio
import random

async def fetch_data(id):
    print(f"Task {id} fetching data...")
    
    await asyncio.sleep(random.uniform(0.5, 1.5))
    
    print(f"Task {id} done.")
    return f"Data {id}"

async def run_async_demo():
    print("\n--- 2. AsyncIO Demo ---")
    
    tasks   = [fetch_data(i) for i in range(3)]
    results = await asyncio.gather(*tasks)
    
    print(f"All results: {results}")

if __name__ == "__main__":
    asyncio.run(run_async_demo())
