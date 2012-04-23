package trusted;

import checkers.types.BasicAnnotatedTypeFactory;

import com.sun.source.tree.CompilationUnitTree;

public class TrustedAnnotatedTypeFactory extends BasicAnnotatedTypeFactory<TrustedChecker> {

    public TrustedAnnotatedTypeFactory(TrustedChecker checker,
            CompilationUnitTree root) {
        super(checker, root);
    }
}