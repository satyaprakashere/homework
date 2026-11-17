    #!/usr/bin/env python3

def bitcount(n):
    count = 0
    while n > 0:
        count = count + 1
        n = n & (n-1)
    return count


print("bitcount of 20: ", bitcount(20))

def quicksort(arr):
    if len(arr) <= 1:   # Base case: array of length 0 or 1 is already sorted
        return arr
    else:
        pivot   = arr[len(arr) // 2]                # Choose the pivot (in this case, the middle element)
        left    = [x for x in arr if x < pivot]     # Elements less than pivot
        middle  = [x for x in arr if x == pivot]    # Elements equal to pivot
        right   = [x for x in arr if x > pivot]     # Elements greater than pivot
        
        return quicksort(left) + middle + quicksort(right)  # Recursively sort sub-arrays

res = quicksort([3,6,3,2,6,7,3,5])
print("sorted array: ", res)