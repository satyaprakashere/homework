void main() {

}

record IntKernel(int prev, int next) {}

// interface SIntStream extends IntStream {
//     SIntStream reduceWith(IntKernel kernel);
// }

static class SIntStream {
    private int[] array;
    SIntStream(int[] arr) {
        this.array = arr;
    }
    
    SIntStream reduceWith(int initialValue, IntKernel kernel) {
        return null;
    }
    
    static SIntStream from(int[] array) {
        return new SIntStream(array);
    }
}
