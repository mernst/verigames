package trusted;

import checkers.basetype.BaseTypeChecker;
import games.GameVisitor;

import com.sun.source.tree.*;

public class TrustedVisitor extends GameVisitor {

    public TrustedVisitor(BaseTypeChecker checker, CompilationUnitTree root,
            TrustedChecker trustedchecker, boolean infer) {
        super(checker, root, infer);
    }
}
