package hardcoded;

import com.sun.source.tree.BinaryTree;
import com.sun.source.tree.CompilationUnitTree;

import checkers.basetype.BaseTypeChecker;
import checkers.types.AnnotatedTypeMirror;
import checkers.types.BasicAnnotatedTypeFactory;
import checkers.types.TreeAnnotator;
import checkers.util.TreeUtils;

public class HardCodedAnnotatedTypeFactory extends BasicAnnotatedTypeFactory<HardCodedChecker> {

    public HardCodedAnnotatedTypeFactory(HardCodedChecker checker,
            CompilationUnitTree root) {
        super(checker, root);
        if(root != null && this.checker.currentPath != null) {
        	postInit();
        }
    }

    @Override
    public TreeAnnotator createTreeAnnotator(HardCodedChecker checker) {
        return new HardCodedTreeAnnotator(checker);
    }

    private class HardCodedTreeAnnotator extends TreeAnnotator {
        public HardCodedTreeAnnotator(BaseTypeChecker checker) {
            super(checker, HardCodedAnnotatedTypeFactory.this);
        }

        /**
         * Handles String concatenation; only @Trusted + @Trusted = @Trusted.
         * Any other concatenation results in @Untursted.
         */
        @Override
        public Void visitBinary(BinaryTree tree, AnnotatedTypeMirror type) {
            if (!type.isAnnotated()
                    && TreeUtils.isStringConcatenation(tree)) {
                AnnotatedTypeMirror lExpr = getAnnotatedType(tree.getLeftOperand());
                AnnotatedTypeMirror rExpr = getAnnotatedType(tree.getRightOperand());

                if (lExpr.hasAnnotation(checker.NOTHARDCODED) || rExpr.hasAnnotation(checker.NOTHARDCODED)) {
                    type.addAnnotation(checker.NOTHARDCODED);
                } else {
                    type.addAnnotation(checker.MAYBEHARDCODED);
                }
            }
            return super.visitBinary(tree, type);
        }
    }
}
