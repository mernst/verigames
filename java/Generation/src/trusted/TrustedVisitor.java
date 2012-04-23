package trusted;

import javax.lang.model.type.TypeMirror;

import checkers.basetype.BaseTypeChecker;
import checkers.inference.InferenceVisitor;

import com.sun.source.tree.*;

public class TrustedVisitor extends InferenceVisitor {

    private final TrustedChecker trustedchecker;
    private final TypeMirror stringType;

    public TrustedVisitor(BaseTypeChecker checker, CompilationUnitTree root,
            TrustedChecker trustedchecker, boolean infer) {
        super(checker, root, infer);

        this.trustedchecker = trustedchecker;
        this.stringType = elements.getTypeElement("java.lang.String").asType();
    }
}
