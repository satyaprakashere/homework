func testMap() {
    var array = Array(0..<10)
    let res = array.map {
        x in x*3
    }
    print(res)
    
    func map<T>(_ arr: inout Array<T>, fn: (T) -> T) {
        for (i, e) in arr.enumerated() {
            arr[i] = fn(e)
        }
    }
    
    map(&array) {
        x in x*2
    }
    print(array)
}

testMap()