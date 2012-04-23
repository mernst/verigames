package nninf;

import javax.annotation.processing.ProcessingEnvironment;
import javax.lang.model.element.Element;
import javax.lang.model.element.ExecutableElement;
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
        if (!atypeFactory.isAnyEnclosingThisDeref(node)) {
            // TODO: determining whether something is "this" doesn't seem to work correctly,
            // as I still get constraints with LiteralThis.
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

    @Override
    public Void visitVariable(VariableTree node, Void p) {
        scan(node.getModifiers(), p);
        scan(node.getType(), p);
        scan(node.getInitializer(), p);

        return super.visitVariable(node, p);
    }

    /** Log method invocations. */
    @Override
    public Void visitMethodInvocation(MethodInvocationTree node, Void p) {
        ProcessingEnvironment env = nninfchecker.getProcessingEnvironment();
        ExecutableElement mapGet =  TreeUtils.getMethod("java.util.Map", "get", 1, env);
        if (TreeUtils.isMethodInvocation(node, mapGet, env)) {
            // TODO: log the call to Map.get. 
        } else {
            logMethodInvocation(node);
        }
        super.visitMethodInvocation(node, p);
        return null;
    }

    /** Class instantiation is always non-null.
     * TODO: resolve this automatically?
     */
    @Override
    public Void visitNewClass(NewClassTree node, Void p) {
        super.visitNewClass(node, p);
        checkForNullability(node, "newclass.null");
        return null;
    }

    @Override
    public Void visitReturn(ReturnTree node, Void p) {
        // Don't try to check return expressions for void methods.
        if (node.getExpression() == null) {
            return null;
        }

        scan(node.getExpression(), p);

        MethodTree enclosingMethod =
            TreeUtils.enclosingMethod(getCurrentPath());

        AnnotatedExecutableType methodType = atypeFactory.getAnnotatedType(enclosingMethod);
        commonAssignmentCheck(methodType.getReturnType(), node.getExpression(),
                "return.type.incompatible");

        return null;
    }

    /** Check for implicit {@code .iterator} call */
    @Override
    public Void visitEnhancedForLoop(EnhancedForLoopTree node, Void p) {
        super.visitEnhancedForLoop(node, p);
        checkForNullability(node.getExpression(), "dereference.of.nullable");
        return null;
    }

    /** Check for array dereferencing */
    @Override
    public Void visitArrayAccess(ArrayAccessTree node, Void p) {
        super.visitArrayAccess(node, p);
        checkForNullability(node.getExpression(), "accessing.nullable");
        return null;
    }

    /** Check for thrown exception nullness */
    @Override
    public Void visitThrow(ThrowTree node, Void p) {
        super.visitThrow(node, p);
        checkForNullability(node.getExpression(), "throwing.nullable");
        return null;
    }

    /** Check for synchronizing locks */
    @Override
    public Void visitSynchronized(SynchronizedTree node, Void p) {
        super.visitSynchronized(node, p);
        checkForNullability(node.getExpression(), "locking.nullable");
        return null;
    }

    @Override
    public Void visitConditionalExpression(ConditionalExpressionTree node, Void p) {
        super.visitConditionalExpression(node, p);
        checkForNullability(node.getCondition(), "condition.nullable");
        return null;
    }

    @Override
    public Void visitIf(IfTree node, Void p) {
        super.visitIf(node, p);
        checkForNullability(node.getCondition(), "condition.nullable");
        return null;
    }

    @Override
    public Void visitDoWhileLoop(DoWhileLoopTree node, Void p) {
        super.visitDoWhileLoop(node, p);
        checkForNullability(node.getCondition(), "condition.nullable");
        return null;
    }

    @Override
    public Void visitWhileLoop(WhileLoopTree node, Void p) {
        super.visitWhileLoop(node, p);
        checkForNullability(node.getCondition(), "condition.nullable");
        return null;
    }

    // Nothing needed for EnhancedForLoop, no boolean get's unboxed there.
    @Override
    public Void visitForLoop(ForLoopTree node, Void p) {
        super.visitForLoop(node, p);
        if (node.getCondition()!=null) {
            // Condition is null e.g. in "for (;;) {...}"
            checkForNullability(node.getCondition(), "condition.nullable");
        }
        return null;
    }

    /** Check for switch statements */
    @Override
    public Void visitSwitch(SwitchTree node, Void p) {
        super.visitSwitch(node, p);
        checkForNullability(node.getExpression(), "switching.nullable");
        return null;
    }

    /**
     * Unboxing case: primitive operations
     */
    @Override
    public Void visitBinary(BinaryTree node, Void p) {
        super.visitBinary(node, p);
        final ExpressionTree leftOp = node.getLeftOperand();
        final ExpressionTree rightOp = node.getRightOperand();

        if (NullnessVisitor.isUnboxingOperation(types, stringType, node)) {
            checkForNullability(leftOp, "unboxing.of.nullable");
            checkForNullability(rightOp, "unboxing.of.nullable");
        }

        return null;
    }

    /** Unboxing case: primitive operation */
    @Override
    public Void visitUnary(UnaryTree node, Void p) {
        super.visitUnary(node, p);
        checkForNullability(node.getExpression(), "unboxing.of.nullable");
        return null;
    }

    /** Unboxing case: primitive operation */
    @Override
    public Void visitCompoundAssignment(CompoundAssignmentTree node, Void p) {
        super.visitCompoundAssignment(node, p);
        // ignore String concatenation
        if (!NullnessVisitor.isString(types, stringType, node)) {
            checkForNullability(node.getVariable(), "unboxing.of.nullable");
            checkForNullability(node.getExpression(), "unboxing.of.nullable");
        }
        return null;
    }

    /** Unboxing case: casting to a primitive */
    @Override
    public Void visitTypeCast(TypeCastTree node, Void p) {
        super.visitTypeCast(node, p);
        if (NullnessVisitor.isPrimitive(node) && !NullnessVisitor.isPrimitive(node.getExpression()))
            checkForNullability(node.getExpression(), "unboxing.of.nullable");
        return null;
    }
}
