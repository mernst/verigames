package verigames.optimizer;

import verigames.level.Chute;

public class Util {

    /////////// Config
    private static boolean verbose = false;

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
     * Enable or disable the output of {@link #logVerbose(Object)}
     * @param v true to enable verbose logging, false to disable
     */
    public static void setVerbose(boolean v) {
        verbose = v;
    }

    /**
     * Log a message, but only if verbose mode is enabled
     * @param o the object to log
     * @see #setVerbose(boolean)
     */
    public static void logVerbose(Object o) {
        if (verbose)
            System.err.println(o);
    }

    public static Chute immutableChute() {
        Chute result = new Chute();
        result.setEditable(false);
        return result;
    }

    public static Chute mutableChute() {
        Chute result = new Chute();
        result.setEditable(true);
        return result;
    }

}
