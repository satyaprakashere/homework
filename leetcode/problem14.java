import java.util.*;

class Solution {
    public static String longestCommonPrefix(String[] strs) {
        StringBuilder commonPrefix = new StringBuilder();
        int maxLength = Arrays.asList(strs).stream().map(String::length).reduce(Integer.valueOf(0), (a, b) -> a>b ? a : b);
        for( int i = 0 ; i < maxLength; i++) {
            Character c = null;
            for (var s : strs) {
                if (i < s.length()) {
                    if (c == null) {
                        c = s.charAt(i);
                    } else if(c != s.charAt(i)) {
                        c = null;
                        break;
                    }
                } else {
                    c = null;
                    break;
                }
            }
            if (c != null) {
                commonPrefix.append(c);
            } else {
                break;
            }
        }
        return commonPrefix.toString();
    }
    
    public static void main(String[] args) {
            System.out.println(longestCommonPrefix(new String[]{"flower","flow","flight"}));
    }
}