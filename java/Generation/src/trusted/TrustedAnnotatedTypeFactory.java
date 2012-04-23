package trusted;

import trusted.quals.Trusted;
import trusted.quals.Untrusted;
import checkers.basetype.BaseTypeChecker;
import checkers.types.AnnotatedTypeMirror;
import checkers.types.BasicAnnotatedTypeFactory;
import checkers.types.TreeAnnotator;
import checkers.util.TreeUtils;

import com.sun.source.tree.BinaryTree;
import com.sun.source.tree.CompilationUnitTree;

public class TrustedAnnotatedTypeFactory extends BasicAnnotatedTypeFactory<TrustedChecker> {

    public TrustedAnnotatedTypeFactory(TrustedChecker checker,
            CompilationUnitTree root) {
        super(checker, root);
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
         * Any other concatenation results in @Untursted.
         */
	    @Override
	    public Void visitBinary(BinaryTree tree, AnnotatedTypeMirror type) {
	        if (!type.isAnnotated()
	            && TreeUtils.isStringConcatenation(tree)) {
	            AnnotatedTypeMirror lExpr = getAnnotatedType(tree.getLeftOperand());
	            AnnotatedTypeMirror rExpr = getAnnotatedType(tree.getRightOperand());
	
	            if (lExpr.hasAnnotation(Trusted.class) && rExpr.hasAnnotation(Trusted.class)) {
	            	type.addAnnotation(Trusted.class);
	            } else {
	            	type.addAnnotation(Untrusted.class);
	            }
	        }
	        return super.visitBinary(tree, type);
	    }
	}
}