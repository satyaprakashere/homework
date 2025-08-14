import java.util.*;

String intToRoman(int num) {
    var values = new int[] {1000, 900, 500, 400, 100, 90,  50, 40, 10, 9,  5, 4, 1};
    var symbols = new String[] {"M",  "CM", "D", "CD", "C", "XC","L","XL","X","IX","V","IV","I"};
    
    var result = new StringBuilder();
    for (int i = 0; i < values.length; ++i) {
        while(num > values[i]) {
            result.append(symbols[i]);
            num -= values[i];
        }
    }
    
    return result.toString();
}
void main() {
    System.out.println(intToRoman(3749));
}

