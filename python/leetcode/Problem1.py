from typing import List

class Solution:
    def twoSum(self, nums: List[int], target: int) -> List[int]:
        nums.sort()
        size = len(nums)
        res = []
        for (num,i) in nums, range(0, size):
            print(nums) if (nums[i+1, size]) else print()

Solution().twoSum([1, 2, 8, 5, 7, 3], 4)