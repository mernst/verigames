class While {
    void test(boolean b) {
       String a = "";
       while (b) {
            a.toString();
            if (a != null) {
                a = null;
            }
       }

/*       String a = ""; // 4
        while (b) { // 6 + 4 => 7, 7 + 4 => 7
            a.toString(); // 4, 7
            if (b) {
                a = "" // 5
            }
            // 4 + 5 => 6
            // 5 + 7 => 7
            a.toString() // 6
        }*/
    }
}
