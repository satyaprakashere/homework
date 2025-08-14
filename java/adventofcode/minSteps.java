// Java program to find minimum moves to 
// reach target if we can move i steps in
// i-th move.

int minSteps(int d) {

    // Handling negatives by symmetry
    d = Math.abs(d);

    // Keep moving while sum is 
    // smaller or difference is odd.
    int sum = 0, step = 0;
    while (sum < d || (sum - d) % 2 != 0) {
        System.out.println(step);
        System.out.println(sum);
        
        step++;
        sum += step;
    }
    return step;
}

void main() {
    int d = 5;
    System.out.println(minSteps(d));
}