print("Hello There to Swift Collections!")
let arr     = testArrays()
let slice   = testArraySlice(arr: arr)
let set     = testSet(slice: slice)

func testArrays() -> [Int] {
    var arr = Array(repeating: 0, count: 10)
    let size = arr.count

    arr[size-1] = size

    print(size)
    for (i, e) in arr.enumerated() {
        arr[i] = i
        print("Array elem at ", i, " = ", e)
    }
    return arr
}

func testArraySlice(arr: Array<Int>) -> ArraySlice<Int> {
    var slice = arr[2..<5]
    let size = slice.count

    slice[size-1] = size

    print(size)
    for (i, e) in slice.enumerated() {
        print("Slice elem at ", i, " = ", e)
    }
    
    return slice
}

func testSet(slice: ArraySlice<Int>) -> Set<Int> {
    let set = Set(0..<100)
    print(set)
    print(set.contains(12))
    print(set.union(121..<144))
    return set
}
