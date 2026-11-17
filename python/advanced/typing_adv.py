from typing import TypeVar, List, Protocol

T = TypeVar('T')

def get_first(items: List[T]) -> T:
    """Generic function to get first item"""
    return items[0]

class Drawable(Protocol):
    """Static Duck Typing with Protocol"""
    def draw(self) -> None:
        ...

class Circle:
    def draw(self) -> None:
        print("Drawing a Circle")

class Square:
    def draw(self) -> None:
        print("Drawing a Square")

def render(obj: Drawable) -> None:
    obj.draw()

def run_typing_demo():
    print("\n--- 3. Advanced Typing & Protocols ---")
    print(f"First element: {get_first([1, 2, 3])}")
    
    render(Circle())
    render(Square())

run_typing_demo()
