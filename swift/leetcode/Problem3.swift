class Solution {
    func threeSum(_ nums: [Int]) -> [[Int]] {
        var result:Set<[Int]> = Set.init()
        let sorted = nums.sorted()

        for (i, num) in sorted.enumerated().dropLast(2) {
            var j = i+1
            var k = sorted.count-1
            var sum = sorted[j] + sorted[k] + num
            while (j < k) {
                if sum > 0 {
                    k -= 1
                } else if sum < 0 {
                    j += 1
                } else {
                    result.insert([sorted[i], sorted[j], sorted[k]])
                    j += 1
                }
                sum = sorted[j] + sorted[k] + num
            }

            if (sum == 0 && j != k) {
                result.insert([sorted[i], sorted[j], sorted[k]])
            }
        }
        return .init(result)
    }
}

print(Solution().threeSum([-2,0,1,1,2]))
