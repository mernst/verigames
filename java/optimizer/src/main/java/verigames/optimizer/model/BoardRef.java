package verigames.optimizer.model;

import verigames.level.Board;
import verigames.level.StubBoard;

/**
 * The board held by a {@link verigames.level.Intersection.Kind#SUBBOARD SUBBOARD}
 * {@link verigames.level.Intersection Intersection}. It may be either a
 * full-fledged {@link Board} or a {@link StubBoard}.
 */
public class BoardRef {

    private final Board board;
    private final StubBoard stubBoard;

    public BoardRef(Board board) {
        this.board = board;
        this.stubBoard = null;
    }

    public BoardRef(StubBoard stubBoard) {
        this.board = null;
        this.stubBoard = stubBoard;
    }

    public boolean isStub() {
        return stubBoard != null;
    }

    public Board asBoard() {
        return board;
    }

    public StubBoard asStubBoard() {
        return stubBoard;
    }

}
