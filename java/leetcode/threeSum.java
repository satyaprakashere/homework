import java.util.*;

class Solution {
    public ArrayList<List<Integer>> threeSum(int[] nums) {
        var resultTriplets = new ArrayList<List<Integer>>();
        for (var num : nums) {
            Arrays.asList(nums).remove(num);
            var twoSums = twoSum(nums, 0-num);
            twoSums.add(num);
            resultTriplets.add(twoSums);
        }
        return resultTriplets;
    }
    public List<List<Integer>> twoSum(int[] nums, int target) {
        Arrays.sort(nums);
        var result = new ArrayList<Integer>();
        for (int i = 0; i < nums.length; ++i) {
            int resi = Arrays.binarySearch(nums, i+1, nums.length, target-nums[i]);
        }   
        return result;
    }
}