package nninf;

import javax.lang.model.element.Element;

import checkers.types.AnnotatedTypeFactory;
import checkers.types.AnnotatedTypeMirror;

import com.sun.source.tree.CompilationUnitTree;
import com.sun.source.tree.Tree;

public class NninfAnnotatedTypeFactory extends AnnotatedTypeFactory {
    NninfChecker checker;

    public NninfAnnotatedTypeFactory(NninfChecker checker,
            CompilationUnitTree root) {
        super(checker, root);

        this.checker = checker;

        postInit();
    }

    @Override
    protected void annotateImplicit(Tree tree, AnnotatedTypeMirror type) {
        if (!type.isAnnotated()) {
            // Why are these needed?? The first should be an ImplicitFor from
            // NonNull, the second one should come from the
            // DefaultQualifierInHierarchy.
            System.out.println("Tree without annotation: " + tree.getKind());

            if (tree.getKind() == Tree.Kind.NEW_CLASS) {
                type.addAnnotation(checker.NONNULL);
            } else if (tree.getKind() == Tree.Kind.NULL_LITERAL) {
                type.addAnnotation(checker.NULLABLE);
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