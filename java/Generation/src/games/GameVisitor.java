package games;

import javax.annotation.processing.ProcessingEnvironment;
import javax.lang.model.element.Element;
import javax.lang.model.element.ExecutableElement;

import checkers.inference.ConstraintManager;
import checkers.inference.InferenceChecker;
import checkers.inference.InferenceMain;
import checkers.source.SourceVisitor;
import checkers.types.AnnotatedTypeMirror;
import com.sun.source.tree.*;

import checkers.basetype.BaseTypeChecker;
import checkers.inference.InferenceVisitor;
import checkers.types.AnnotatedTypeMirror.AnnotatedExecutableType;
import checkers.types.AnnotatedTypeMirror.AnnotatedTypeVariable;
import javacutils.InternalUtils;
import javacutils.Pair;
import javacutils.TreeUtils;

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
        /* TODO: Re-orderings were causing duplicate constraints. Revisit whether we can do
         * this smarter.
        scan(node.getModifiers(), p);
        scan(node.getType(), p);
        */
        scan(node.getInitializer(), p);
        return super.visitVariable(node, p);
    }
    

    /** An identifier is a field access sometimes, i.e. when there is an implicit "this". */
    @Override
    public Void visitIdentifier(IdentifierTree node, Void p) {
        Element elem = TreeUtils.elementFromUse(node);
        if (elem.getKind().isField() && !node.toString().equals("this")) { //TODO JB: Ask Werner if I should protect against
            logFieldAccess(node);                                          //TODO JB: Calling assignments field accesses here
        }

        return super.visitIdentifier(node, p);
    }

    private boolean holdCheck = false;

    /** Log all assignments. */
    @Override
    public Void visitAssignment(AssignmentTree node, Void p) {

        if( infer ) {
            Pair<Tree, AnnotatedTypeMirror> preAssCtxt = visitorState.getAssignmentContext();
            visitorState.setAssignmentContext(Pair.of((Tree) node.getVariable(), atypeFactory.getAnnotatedType(node.getVariable())));
            try {
                //This is a reimplementation of what happens in BaseTypeVisitor/SourceVisitor
                //But with commonAssignmentCheck happening after visiting of the left and right side
                //of an assignment.  This is necessary because we are getting SubtypeConstraints BEFORE
                //method calls and other constraints are generated for the RHS
                Void result = scan( node.getVariable(), p);
                reduce(scan(node.getExpression(), p), result);

                final Element leftElem = TreeUtils.elementFromUse( node.getVariable() );
                if(!InferenceMain.isPerformingFlow() && leftElem!=null && leftElem.getKind().isField() ) {
                    logAssignment(node);
                }

                commonAssignmentCheck(node.getVariable(), node.getExpression(),
                        "assignment.type.incompatible");
            } finally {
                visitorState.setAssignmentContext(preAssCtxt);
            }
        } else {
            super.visitAssignment(node, p);
        }
        return null;
    }

    @Override
    public Void visitMethod(MethodTree methodTree, Void p) {
        logReceiverClassConstraints(methodTree);

        if( TreeUtils.isConstructor(methodTree) ) {
          logConstructorConstraints( methodTree );
        }
        return super.visitMethod( methodTree, p );
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

        if ( infer & !InferenceMain.isPerformingFlow() ) {
            if (TreeUtils.isMethodInvocation(node, mapGet, env)) {
                // TODO: log the call to Map.get.
            } else {
                scan(node.getMethodSelect(), p);
                logMethodInvocation(node);
            }
        } else {
            super.visitMethodInvocation(node, p);
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
                "return.type.incompatible", false);

        return null;
    }

    @Override
    public Void visitNewClass( NewClassTree newClassTree, Void p) {
        logConstructorInvocationConstraints( newClassTree );
        return super.visitNewClass( newClassTree, p);
    }

    @Override
    public Void visitTypeParameter( TypeParameterTree typeParameterTree, Void p) {
        //TODO JB: Because the resulting type of typeParameterTree always has the type in front
        //TODO JB: of the parameter on the upper and lower bounds, create the constraint between
        //TODO JB: these two here.  Potential fix: change the Checker-Framework behavior
        logTypeParameterConstraints( typeParameterTree );

        return super.visitTypeParameter(typeParameterTree, p);
    }
}
