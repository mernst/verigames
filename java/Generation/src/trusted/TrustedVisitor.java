package trusted;

import checkers.basetype.BaseTypeChecker;
import checkers.inference.InferenceVisitor;

import com.sun.source.tree.*;

public class TrustedVisitor extends InferenceVisitor {

    public TrustedVisitor(BaseTypeChecker checker, CompilationUnitTree root,
            TrustedChecker trustedchecker, boolean infer) {
        super(checker, root, infer);
    }

    /** Log method invocations. */
    // TODO: Add a GameVisitor that does the field/method logging.
    @Override
    public Void visitMethodInvocation(MethodInvocationTree node, Void p) {
        logMethodInvocation(node);
        super.visitMethodInvocation(node, p);
        return null;
    }
}
