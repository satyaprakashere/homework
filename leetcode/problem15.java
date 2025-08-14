import java.util.*;

class Solution {
    public static List<List<Integer>> threeSum(int[] nums) {
        var resultTriplets = new ArrayList<List<Integer>>();
        for (var num : nums) {
            var twoSums = twosum(nums, nums.length-1);
            resultTriplets.addAll(twoSums);
        }
        return resultTriplets;
    }
    
    public static List<List<Integer>> twosum(int[] nums, int end) {
        
        for (int i = 0; i <end; i++) {
            
        }
        return null;
    }
    
    public static void main(String[] args) {
            
    }
}