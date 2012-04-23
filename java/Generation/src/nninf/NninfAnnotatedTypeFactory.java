package nninf;

import java.util.List;

import javax.lang.model.element.Element;

import checkers.types.AnnotatedTypeFactory;
import checkers.types.AnnotatedTypeMirror;
import checkers.types.AnnotatedTypeMirror.AnnotatedExecutableType;
import checkers.util.Pair;

import com.sun.source.tree.CompilationUnitTree;
import com.sun.source.tree.MethodInvocationTree;
import com.sun.source.tree.Tree;
import com.sun.source.util.TreePath;

public class NninfAnnotatedTypeFactory extends AnnotatedTypeFactory {
    NninfChecker checker;
    MapGetHeuristics mapGetHeuristics;

    public NninfAnnotatedTypeFactory(NninfChecker checker,
            CompilationUnitTree root) {
        super(checker, root);

        this.checker = checker;

        // TODO: why is this not a KeyForAnnotatedTypeFactory?
        // What qualifiers does it insert? The qualifier hierarchy is null.
        AnnotatedTypeFactory mapGetFactory = new AnnotatedTypeFactory(checker.getProcessingEnvironment(), null, root, null);
        mapGetHeuristics = new MapGetHeuristics(env, this, mapGetFactory);

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

    /*
     * It looks like BaseTypeVisitor will call this method in visitMethodInvocation?
     * So do we need to do anything else?
     * 
     * 
     * (non-Javadoc)
     * @see checkers.types.AnnotatedTypeFactory#methodFromUse(com.sun.source.tree.MethodInvocationTree)
     */
    @Override
    public Pair<AnnotatedExecutableType, List<AnnotatedTypeMirror>> methodFromUse(MethodInvocationTree tree) {
        Pair<AnnotatedExecutableType, List<AnnotatedTypeMirror>> mfuPair = super.methodFromUse(tree);
        AnnotatedExecutableType method = mfuPair.first;

        TreePath path = this.getPath(tree);
        if (path!=null) {
            mapGetHeuristics.handle(path, method);
        }
        return mfuPair;
    }
}