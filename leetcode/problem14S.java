class Solution {
    public static String longestCommonPrefix(String[] strs) {
        var commonPrefix = strs[0];
        for(int i = 1 ; i < strs.length; i++) {
            while (!strs[i].startsWith(commonPrefix)) {
                commonPrefix = commonPrefix.substring(0, commonPrefix.length()-1);
            }
        }
        return commonPrefix;
    }

    public static void main(String[] args) {
            System.out.println(longestCommonPrefix(new String[]{"flower","flow","flight"}));
    }
}
