import decorators
import asyncio
import async_io
import typing_adv

def main():
    print("=== Python Advanced Learning Lab ===")
    
    decorators.run_decorators_demo()
    
    # Run async demo
    asyncio.run(async_io.run_async_demo())
    
    typing_adv.run_typing_demo()
    
    print("\n=== Lab Complete ===")

if __name__ == "__main__":
    main()
