
int largestAltitude(int[] gain) {
    return Arrays.stream(gain)
        .mapToObj(x -> new int[]{x})
        .reduce(new int[]{0, 0}, (res, g) -> res[1]+g[0] > res[0]
                ? new int[]{res[1]+g[0], res[1]+g[0]} : new int[] {res[0], res[1]+g[0]})[0];
}

void main() {
    
}