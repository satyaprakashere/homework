import java.util.*;

class Solution {
    public boolean isValidSudoku(char[][] board) {
        HashSet<Character>[] verticalSets = new HashSet[10];
        for (int i = 0; i < verticalSets.length; i++) {
            verticalSets[i] = new HashSet<>(); // Initialize each set
        }
        
        int kernelSize = (board.length/3)*(board.length/3);
        HashSet<Character>[] kernelSets = new HashSet[kernelSize];
        
        for (int i = 0; i < kernelSize; i++) {
            kernelSets[i] = new HashSet<>(); // Initialize each set
        }
        for (int i = 0; i <board.length; ++i) {
            var set = new HashSet<Character>(10);
            for (int j = 0; j <board.length; ++j) {
                if (kernelSets[i + j/3].contains(board[i][j])) {
                    return false;
                } else {
                    kernelSets[i+j/3].add(board[i][j]);
                }
                if (verticalSets[j].contains(board[i][j])) {
                    return false;
                } else {
                    verticalSets[j].add(board[i][j]);
                }
                if (set.contains(board[i][j])) {
                    return false;
                } else {
                    set.add(board[i][j]);
                }
            }
        }
        return true;
    }
    
    public static void main(String[] args) {
        new Solution().isValidSudoku(null);
    }
}