//go:build ignore
package main

import "fmt"

func main() {
    res := 0
    current_sum := 0
    res_start := 0
    res_end := 0
    
    start, end := 0, 0
    
    nums := {1, -2, 3, -2}
    
    for i:=0; i< nums.count; i+=1 {
        if nums[i] > 0 {
            current_sum += nums[i]
            if res < current_sum {
                
            }
        }
        
        if nums[i] < 0 && (0-nums[i]) > current_sum {
            res
        }
    }
}


Given a circular integer array nums of length n, return the maximum possible sum of a non-empty subarray of nums. 

A circular array means the end of the array connects to the beginning of the array. Formally, the next element of nums[i] is nums[(i + 1) % n] and the previous element of nums[i] is nums[(i - 1 + n) % n]. 

Example 1: 

Input: nums = [1,-2,3,-2] 
Output: 3 
Explanation: Subarray [3] has maximum sum 3. 

Example 2: 

Input: nums = [5,-3,5] 
Output: 10 
Explanation: Subarray [5,5] has maximum sum 5 + 5 = 10.