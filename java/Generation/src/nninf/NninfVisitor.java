package nninf;

import checkers.basetype.BaseTypeChecker;
import checkers.inference.InferenceVisitor;
import checkers.source.Result;
import checkers.types.AnnotatedTypeMirror;
import checkers.types.AnnotatedTypeMirror.AnnotatedDeclaredType;
import checkers.types.AnnotatedTypeMirror.AnnotatedExecutableType;
import checkers.util.TreeUtils;

import com.sun.source.tree.*;

public class NninfVisitor extends InferenceVisitor {

    private final NninfChecker nninfchecker;

    public NninfVisitor(BaseTypeChecker checker, CompilationUnitTree root,
            NninfChecker nninfchecker, boolean infer) {
        super(checker, root, infer);

        this.nninfchecker = nninfchecker;
    }

    /**
     * Nninf does not use receiver annotations, forbid them.
     */
    @Override
    public Void visitMethod(MethodTree node, Void p) {
        if (!node.getReceiverAnnotations().isEmpty()) {
            checker.report(Result.failure("receiver.annotations.forbidden"),
                    node);
        }

        return super.visitMethod(node, p);
    }

    /**
     * Ignore method receiver annotations.
     */
    @Override
    protected boolean checkMethodInvocability(AnnotatedExecutableType method,
            MethodInvocationTree node) {
        return true;
    }

    /**
     * Ignore constructor receiver annotations.
     */
    @Override
    protected boolean checkConstructorInvocation(AnnotatedDeclaredType dt,
            AnnotatedExecutableType constructor, Tree src) {
        return true;
    }

    /**
     * Validate a method invocation.
     * 
     * @param node
     *            the method invocation.
     * @param p
     *            not used.
     */
    @Override
    public Void visitMethodInvocation(MethodInvocationTree node, Void p) {
        assert node != null;

        // Also log that there was a method call.
        logMethodInvocation(node);

        ExpressionTree recvTree = TreeUtils.getReceiverTree(node.getMethodSelect());
        if (recvTree != null) {
            AnnotatedTypeMirror recvType = atypeFactory.getAnnotatedType(recvTree);
            if (recvType != null) {
                mainIsNot(recvType, nninfchecker.NULLABLE, "receiver.null",
                        node);
            }
        }

        return super.visitMethodInvocation(node, p);
    }

    /**
     * Validate an assignment.
     * 
     * @param node
     *            the assignment.
     * @param p
     *            not used.
     */
    @Override
    public Void visitAssignment(AssignmentTree node, Void p) {
        assert node != null;

        ExpressionTree recvTree = TreeUtils.getReceiverTree(node.getVariable());
        if (recvTree != null) {
            AnnotatedTypeMirror recvType = atypeFactory.getAnnotatedType(recvTree);

            if (recvType != null) {
                mainIsNot(recvType, nninfchecker.NULLABLE, "receiver.null",
                        node);
            }
        }

        return super.visitAssignment(node, p);
    }

    @Override
    public Void visitNewClass(NewClassTree node, Void p) {
        assert node != null;

        AnnotatedTypeMirror nType = atypeFactory.getAnnotatedType(node);
        mainIsNot(nType, nninfchecker.NULLABLE, "newclass.null", node);

        return super.visitNewClass(node, p);
    }
}
