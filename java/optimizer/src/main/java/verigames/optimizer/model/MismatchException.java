package verigames.optimizer.model;

/**
 * Thrown by {@link ReverseMapping#apply(verigames.level.World, verigames.level.World)}
 * when the mapping does not seem to describe the given worlds.
 */
public class MismatchException extends Exception {

    public MismatchException(String message) {
        super(message);
    }

}
