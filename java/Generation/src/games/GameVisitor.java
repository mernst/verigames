package games;

import javax.lang.model.element.Element;

import nninf.NninfChecker;

import com.sun.source.tree.AssignmentTree;
import com.sun.source.tree.CompilationUnitTree;
import com.sun.source.tree.IdentifierTree;
import com.sun.source.tree.VariableTree;

import checkers.basetype.BaseTypeChecker;
import checkers.inference.InferenceVisitor;
import checkers.util.TreeUtils;

public class GameVisitor extends InferenceVisitor {
	public GameVisitor(BaseTypeChecker checker, CompilationUnitTree root, boolean infer) {
		super(checker, root, infer);
	}

    @Override
    public Void visitVariable(VariableTree node, Void p) {
        scan(node.getModifiers(), p);
        scan(node.getType(), p);
        scan(node.getInitializer(), p);

        return super.visitVariable(node, p);
    }
}
