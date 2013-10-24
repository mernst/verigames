package verigames.optimizer;

public class Util {

    private static boolean verbose = false;
    public static void setVerbose(boolean v) {
        verbose = v;
    }

    /**
     * Pick out the first element from a collection. On unordered collections
     * like HashSets, the result might be any element.
     * @param collection  the collection to pick from
     * @param <T>         the type of element in the collection
     * @throws java.util.NoSuchElementException if the collection is empty
     * @return            the first element of the collection
     */
    public static <T> T first(Iterable<T> collection) {
        return collection.iterator().next();
    }

    /**
     * Log a message, but only if verbose mode is enabled
     * @param o
     */
    public static void logVerbose(Object o) {
        if (verbose)
            System.err.println(o);
    }

}
