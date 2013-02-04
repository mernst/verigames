package hardcoded;

import games.GameVisitor;
import checkers.basetype.BaseTypeChecker;

import com.sun.source.tree.CompilationUnitTree;

public class HardCodedVisitor extends GameVisitor {

    public HardCodedVisitor(BaseTypeChecker checker, CompilationUnitTree root,
            HardCodedChecker hardcodedchecker, boolean infer) {
        super(checker, root, infer);
    }
}
