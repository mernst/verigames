package nninf;

import javax.lang.model.element.Element;
import javax.lang.model.type.TypeMirror;

import checkers.basetype.BaseTypeChecker;
import checkers.inference.InferenceVisitor;
import checkers.nullness.NullnessVisitor;
import checkers.source.Result;
import checkers.types.AnnotatedTypeMirror;
import checkers.types.AnnotatedTypeMirror.AnnotatedDeclaredType;
import checkers.types.AnnotatedTypeMirror.AnnotatedExecutableType;
import checkers.util.TreeUtils;

import com.sun.source.tree.*;

public class NninfVisitor extends InferenceVisitor {

    private final NninfChecker nninfchecker;
    private final TypeMirror stringType;

    public NninfVisitor(BaseTypeChecker checker, CompilationUnitTree root,
            NninfChecker nninfchecker, boolean infer) {
        super(checker, root, infer);

        this.nninfchecker = nninfchecker;
        this.stringType = elements.getTypeElement("java.lang.String").asType();
    }

    /**
     * Ensure that the type is not of nullable.
     */
    private void checkForNullability(ExpressionTree tree, /*@CompilerMessageKey*/ String errMsg) {
        AnnotatedTypeMirror type = atypeFactory.getAnnotatedType(tree);
        mainIsNot(type, nninfchecker.NULLABLE, errMsg, tree);
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

    /** Check for null dereferencing */
    @Override
    public Void visitMemberSelect(MemberSelectTree node, Void p) {
        // Note that the ordering is important! First receiver expression, then create field access, then inequality.
        super.visitMemberSelect(node, p);
        // TODO: How do I decide whether something is a field read or update?
        // We currently create an access and then a set constraint.
        if (!TreeUtils.isSelfAccess(node)) {
            checkForNullability(node.getExpression(), "dereference.of.nullable");
        }
        logFieldAccess(node);
        return null;
    }

    /** An identifier is a field access sometimes, i.e. when there is an implicit "this". */
    @Override
    public Void visitIdentifier(IdentifierTree node, Void p) {
        Element elem = TreeUtils.elementFromUse(node);
        if (elem.getKind().isField() && !node.toString().equals("this")) {
            logFieldAccess(node);
        }
        return super.visitIdentifier(node, p);
    }

    /** Log all assignments. */
    @Override
    public Void visitAssignment(AssignmentTree node, Void p) {
        super.visitAssignment(node, p);
        logAssignment(node);
        return null;
    }

    /** Log method invocations. */
    @Override
    public Void visitMethodInvocation(MethodInvocationTree node, Void p) {
        logMethodInvocation(node);
        return super.visitMethodInvocation(node, p);
    }

    /** Class instantiation is always non-null.
     * TODO: resolve this automatically?
     */
    @Override
    public Void visitNewClass(NewClassTree node, Void p) {
        checkForNullability(node, "newclass.null");
        return super.visitNewClass(node, p);
    }

    /** Check for implicit {@code .iterator} call */
    @Override
    public Void visitEnhancedForLoop(EnhancedForLoopTree node, Void p) {
        checkForNullability(node.getExpression(), "dereference.of.nullable");
        return super.visitEnhancedForLoop(node, p);
    }

    /** Check for array dereferencing */
    @Override
    public Void visitArrayAccess(ArrayAccessTree node, Void p) {
        checkForNullability(node.getExpression(), "accessing.nullable");
        return super.visitArrayAccess(node, p);
    }

    /** Check for thrown exception nullness */
    @Override
    public Void visitThrow(ThrowTree node, Void p) {
        checkForNullability(node.getExpression(), "throwing.nullable");
        return super.visitThrow(node, p);
    }

    /** Check for synchronizing locks */
    @Override
    public Void visitSynchronized(SynchronizedTree node, Void p) {
        checkForNullability(node.getExpression(), "locking.nullable");
        return super.visitSynchronized(node, p);
    }

    @Override
    public Void visitConditionalExpression(ConditionalExpressionTree node, Void p) {
        checkForNullability(node.getCondition(), "condition.nullable");
        return super.visitConditionalExpression(node, p);
    }

    @Override
    public Void visitIf(IfTree node, Void p) {
        checkForNullability(node.getCondition(), "condition.nullable");
        return super.visitIf(node, p);
    }

    @Override
    public Void visitDoWhileLoop(DoWhileLoopTree node, Void p) {
        checkForNullability(node.getCondition(), "condition.nullable");
        return super.visitDoWhileLoop(node, p);
    }

    @Override
    public Void visitWhileLoop(WhileLoopTree node, Void p) {
        checkForNullability(node.getCondition(), "condition.nullable");
        return super.visitWhileLoop(node, p);
    }

    // Nothing needed for EnhancedForLoop, no boolean get's unboxed there.
    @Override
    public Void visitForLoop(ForLoopTree node, Void p) {
        if (node.getCondition()!=null) {
            // Condition is null e.g. in "for (;;) {...}"
            checkForNullability(node.getCondition(), "condition.nullable");
        }
        return super.visitForLoop(node, p);
    }

    /** Check for switch statements */
    @Override
    public Void visitSwitch(SwitchTree node, Void p) {
        checkForNullability(node.getExpression(), "switching.nullable");
        return super.visitSwitch(node, p);
    }

    /**
     * Unboxing case: primitive operations
     */
    @Override
    public Void visitBinary(BinaryTree node, Void p) {
        final ExpressionTree leftOp = node.getLeftOperand();
        final ExpressionTree rightOp = node.getRightOperand();

        if (NullnessVisitor.isUnboxingOperation(types, stringType, node)) {
            checkForNullability(leftOp, "unboxing.of.nullable");
            checkForNullability(rightOp, "unboxing.of.nullable");
        }

        return super.visitBinary(node, p);
    }

    /** Unboxing case: primitive operation */
    @Override
    public Void visitUnary(UnaryTree node, Void p) {
        checkForNullability(node.getExpression(), "unboxing.of.nullable");
        return super.visitUnary(node, p);
    }

    /** Unboxing case: primitive operation */
    @Override
    public Void visitCompoundAssignment(CompoundAssignmentTree node, Void p) {
        // ignore String concatenation
        if (!NullnessVisitor.isString(types, stringType, node)) {
            checkForNullability(node.getVariable(), "unboxing.of.nullable");
            checkForNullability(node.getExpression(), "unboxing.of.nullable");
        }
        return super.visitCompoundAssignment(node, p);
    }

    /** Unboxing case: casting to a primitive */
    @Override
    public Void visitTypeCast(TypeCastTree node, Void p) {
        if (NullnessVisitor.isPrimitive(node) && !NullnessVisitor.isPrimitive(node.getExpression()))
            checkForNullability(node.getExpression(), "unboxing.of.nullable");
        return super.visitTypeCast(node, p);
    }
}
