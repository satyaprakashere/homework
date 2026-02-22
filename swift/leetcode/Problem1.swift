import Foundation

class Solution {
    func twoSum(_ nums: [Int], target: Int) -> [Int] {
        let valueToIndex = nums.enumerated().reduce(into: [Int: Int]()) { dict, pair in
            let (index, value) = pair
            dict[value] = index
        }
        for num in nums {
            if let value = valueToIndex[target-num] {
                if value != valueToIndex[num] {
                    return [valueToIndex[num]!, value]
                }
            }
        }
        return [-1,-1]
    }
}

func randomArray(ofSize n: Int, range: Range<Int> = 0..<100) -> [Int] {    return (0..<n).map { _ in Int.random(in: range) }}

print(Solution().twoSum(randomArray(ofSize: 100000), target: 76))
