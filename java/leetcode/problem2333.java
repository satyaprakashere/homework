import java.util.stream.*;

void main() {
    
}

public int[] shortestDistanceAfterQueries(int n, int[][] queries) {
    int[][] shortestDistance = IntStream.range(0, n)
        .mapToObj(i -> IntStream.range(0, n)
        .map(j -> j-i)
        .toArray()).toArray(int[][]::new);

    final var result = new int[queries.length];
    var j = 0;
    for (var point : queries) {
        shortestDistance[point[0]][point[1]] = 1;
        for(int i = 0; i < point[0] ; ++i) {
            shortestDistance[i][point[1]] = Math.min(shortestDistance[i][point[0]] + 1 , shortestDistance[i][point[1]]);
            shortestDistance[i][n-1] = Math.min(shortestDistance[i][point[1]] + shortestDistance[point[1]][n-1] , shortestDistance[i][n-1]);
        }
        for(int i = point[1]; i < n ; ++i) {
            shortestDistance[0][i] = Math.min(shortestDistance[0][point[1]] + shortestDistance[point[1]][i] , shortestDistance[0][i]);
        }

        for (int k = 0; k < n ; ++k) {
            for (int l = k+1; l < n; ++l) {
                shortestDistance[0][l] = Math.min(shortestDistance[0][k] + shortestDistance[k][l], shortestDistance[0][l]);;
            }
        }
        result[j] = shortestDistance[0][n-1];
        j++;
    }

    return result;
}
