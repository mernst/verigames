package trusted;

import checkers.basetype.BaseTypeChecker;
import checkers.inference.InferenceUtils;
import checkers.types.AnnotatedTypeMirror;
import checkers.types.SubtypingAnnotatedTypeFactory;
import checkers.types.TreeAnnotator;
import javacutils.TreeUtils;

import com.sun.source.tree.BinaryTree;
import com.sun.source.tree.CompilationUnitTree;

public class TrustedAnnotatedTypeFactory extends SubtypingAnnotatedTypeFactory<TrustedChecker> {

    public TrustedAnnotatedTypeFactory(TrustedChecker checker,
            CompilationUnitTree root) {
        super(checker, root);
        if(root != null && this.checker.currentPath != null) {
        	postInit();
        }
    }

    @Override
    public TreeAnnotator createTreeAnnotator(TrustedChecker checker) {
        return new TrustedTreeAnnotator(checker);
    }

    private class TrustedTreeAnnotator extends TreeAnnotator {
        public TrustedTreeAnnotator(BaseTypeChecker checker) {
            super(checker, TrustedAnnotatedTypeFactory.this);
        }

        /**
         * Handles String concatenation; only @Trusted + @Trusted = @Trusted.
         * Any other concatenation results in @Untrusted.
         */
        @Override
        public Void visitBinary(BinaryTree tree, AnnotatedTypeMirror type) {
            if ( !InferenceUtils.isAnnotated( type )
                    && TreeUtils.isStringConcatenation(tree)) {
                AnnotatedTypeMirror lExpr = getAnnotatedType(tree.getLeftOperand());
                AnnotatedTypeMirror rExpr = getAnnotatedType(tree.getRightOperand());

                if (lExpr.hasAnnotation(checker.TRUSTED) && rExpr.hasAnnotation(checker.TRUSTED)) {
                    type.addAnnotation(checker.TRUSTED);
                } else {
                    type.addAnnotation(checker.UNTRUSTED);
                }
            }
            return super.visitBinary(tree, type);
        }
    }
}
