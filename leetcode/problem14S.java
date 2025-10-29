String longestCommonPrefix(String[] strs) {
    var commonPrefix = strs[0];
    for(int i = 1 ; i < strs.length; i++) {
        while (!strs[i].startsWith(commonPrefix)) {
            commonPrefix = commonPrefix.substring(0, commonPrefix.length()-1);
        }
    }
    return commonPrefix;
}

void main(String[] args) {
        println(longestCommonPrefix(new String[]{"flower","flow","flight"}));
}
