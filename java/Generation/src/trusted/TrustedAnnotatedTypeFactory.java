package trusted;

import javax.lang.model.element.Element;
import javax.lang.model.element.ElementKind;

import checkers.types.AnnotatedTypeFactory;
import checkers.types.AnnotatedTypeMirror;

import com.sun.source.tree.CompilationUnitTree;
import com.sun.source.tree.Tree;

public class TrustedAnnotatedTypeFactory extends AnnotatedTypeFactory {
    TrustedChecker checker;

    public TrustedAnnotatedTypeFactory(TrustedChecker checker,
            CompilationUnitTree root) {
        super(checker, root);

        this.checker = checker;

        postInit();
    }

    @Override
    protected void annotateImplicit(Tree tree, AnnotatedTypeMirror type) {
    	System.out.println("Tree: " + tree.getKind() + ", class: " + tree.toString());
        if (!type.isAnnotated()) {
            System.out.println("Tree without annotation (trusted2): " + tree.getKind());
            
            if (tree.getKind() == Tree.Kind.STRING_LITERAL) {
                type.addAnnotation(checker.TRUSTED);
                System.out.println("Annotating String: " + tree.toString() + " as trusted.");
            }
        }
    }

    @Override
    protected void annotateImplicit(Element elt, AnnotatedTypeMirror type) {
        if (!type.isAnnotated()) {
            // System.out.println("Element without annotation: " +
            // elt.getKind());
            // type.addAnnotation(checker.NULLABLE);
        }
    }
}