
public boolean isValidSudoku(char[][] board) {
    var verticalSets = new HashSet[10];
    for (int i = 0; i < verticalSets.length; i++) {
        verticalSets[i] = new HashSet<Character>(); // Initialize each set
    }
    
    int kernelSize = (board.length/3)*(board.length/3);
    Set<Character>[] kernelSets = new HashSet[kernelSize];
    
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

void main() {
    char[][] board = {
        {'5','3','.','.','7','.','.','.','.'},
        {'6','.','.','1','9','5','.','.','.'},
        {'.','9','8','.','.','.','.','6','.'},
        {'8','.','.','.','6','.','.','.','3'},
        {'4','.','.','8','.','3','.','.','1'},
        {'7','.','.','.','2','.','.','.','6'},
        {'.','6','.','.','.','.','2','8','.'},
        {'.','.','.','4','1','9','.','.','5'},
        {'.','.','.','.','8','.','.','7','9'}
    };
    IO.println(isValidSudoku(board));
}
