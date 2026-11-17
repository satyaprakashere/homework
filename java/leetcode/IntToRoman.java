
String intToRoman(int num) {
    final var values = new int[] {1000, 900, 500, 400, 100, 90,  50, 40, 10, 9,  5, 4, 1};
    final var symbols = new String[] {"M",  "CM", "D", "CD", "C", "XC","L","XL","X","IX","V","IV","I"};
    
    final var result = new StringBuilder();
    for (int i = 0; i < values.length; ++i) {
        final var value = values[i];
        while(num > value) {
            result.append(symbols[i]);
            num -= value;
        }
    }
    
    return result.toString();
}

void main() {
    IO.println(intToRoman(37498));
}

