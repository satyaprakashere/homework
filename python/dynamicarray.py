#!/usr/bin/env python3

class DynamicArray:
    def __init__(self, capacity: int):
        self.data = [None]*capacity
        self.size = 0
        self.capacity=capacity
    def get(self, i: int) -> int:
        return self.data[i]

    def set(self, i: int, n: int) -> None:
        self.data[i] = n

    def pushback(self, n: int) -> None:
        if self.size >= self.capacity:
            self.resize()
        self.data[self.size] = n
        self.size = self.size+1

    def popback(self) -> int:
        self.data[self.size-1] = None
        self.size = self.size-1

    def resize(self) -> None:
        self.data.extend([None]*(self.capacity))
        self.capacity = self.capacity*2

    def getSize(self) -> int:
        return self.size

    def getCapacity(self) -> int:
        return self.capacity

array = DynamicArray(1)
print(array.getSize())
print(array.getCapacity())
print(array.pushback(1))
print(array.getSize())
print(array.getCapacity())
print(array.pushback(2))
print(array.getSize())
print(array.getCapacity())
print(array.get(1))
print(array.set(1,3))
print(array.get(1))
print(array.popback())
print(array.getSize())
print(array.getCapacity())
