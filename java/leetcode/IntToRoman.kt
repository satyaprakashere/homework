fun intToRoman(num: Int): String {
    val values = arrayOf(1000, 900, 500, 400, 100, 90,  50, 40, 10, 9,  5, 4, 1)
    val symbols = arrayOf("M",  "CM", "D", "CD", "C", "XC","L","XL","X","IX","V","IV","I")
    var result = StringBuilder();
    
    var temp = num
    for ((value, symbol) in values.zip(symbols)) {
        while(temp > value) {
            result.append(symbol);
            temp -= value;
        }
    }
    
    return result.toString();
}

fun main() {
    println(intToRoman(3749));
}

