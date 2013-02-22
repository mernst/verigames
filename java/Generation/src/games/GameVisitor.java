package games;

import javax.annotation.processing.ProcessingEnvironment;
import javax.lang.model.element.Element;
import javax.lang.model.element.ExecutableElement;

import com.sun.source.tree.AssignmentTree;
import com.sun.source.tree.CompilationUnitTree;
import com.sun.source.tree.IdentifierTree;
import com.sun.source.tree.MethodInvocationTree;
import com.sun.source.tree.MethodTree;
import com.sun.source.tree.ReturnTree;
import com.sun.source.tree.VariableTree;

import checkers.basetype.BaseTypeChecker;
import checkers.inference.InferenceVisitor;
import checkers.types.AnnotatedTypeMirror.AnnotatedExecutableType;
import checkers.util.TreeUtils;

/**
 * This Visitor is a superclass of all Visitors in the game. Its purpose is to abstract common 
 * behavior and collect reorderings of constraints, since the GameSolvers often fail if the 
 * constraints are presented in a different order.
 *
 */
public class GameVisitor extends InferenceVisitor {
	public GameVisitor(BaseTypeChecker checker, CompilationUnitTree root, boolean infer) {
		super(checker, root, infer);
	}

	/**
	 * Re-orders the visitation of variables. Ensures that the modifiers, type, and initializer
	 * are visited before the super call, which will generate other constraints (e.g. Subtype 
	 * constraints) which depend on the other constraints having already been represented.
	 */
    @Override
    public Void visitVariable(VariableTree node, Void p) {
        scan(node.getModifiers(), p);
        scan(node.getType(), p);
        scan(node.getInitializer(), p);

        return super.visitVariable(node, p);
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
        ProcessingEnvironment env = checker.getProcessingEnvironment();
        ExecutableElement mapGet =  TreeUtils.getMethod("java.util.Map", "get", 1, env);
        /*Element elem = TreeUtils.elementFromUse(node.getMethodSelect()).getEnclosingElement();
        System.out.println("Elem: " + elem);
        System.out.println("Kind: " + elem.getKind());
        if (elem.getKind().isField()) {
        	System.out.println("inside: " + elem);
        	logFieldAccess(node);
        }*/
        super.visitMethodInvocation(node, p);
        if (TreeUtils.isMethodInvocation(node, mapGet, env)) {
            // TODO: log the call to Map.get.
        } else {
            logMethodInvocation(node);
        }
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
}
