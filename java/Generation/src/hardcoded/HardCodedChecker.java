package hardcoded;

import games.GameChecker;

import javax.lang.model.element.AnnotationMirror;
import javax.lang.model.util.Elements;

import trusted.TrustedAnnotatedTypeFactory;
import trusted.TrustedVisitor;
import hardcoded.quals.*;
import checkers.quals.TypeQualifiers;
import checkers.types.AnnotatedTypeFactory;
import checkers.types.AnnotatedTypeMirror;
import checkers.types.AnnotatedTypeMirror.AnnotatedPrimitiveType;
import checkers.types.AnnotatedTypeMirror.AnnotatedTypeVariable;
import javacutils.AnnotationUtils;

import com.sun.source.tree.CompilationUnitTree;

/**
 * [7]  CWE-798  Use of Hard-coded Credentials
 * @author sdietzel
 *
 */
@TypeQualifiers({ MaybeHardCoded.class, NotHardCoded.class })
public class HardCodedChecker extends GameChecker<HardCodedAnnotatedTypeFactory> {
    public AnnotationMirror MAYBEHARDCODED, NOTHARDCODED;

    @Override
    public void initChecker() {
    	super.initChecker();
    	setAnnotations();
    }

    protected void setAnnotations() {
        final Elements elements = processingEnv.getElementUtils();
        MAYBEHARDCODED = AnnotationUtils.fromClass(elements, MaybeHardCoded.class);
        NOTHARDCODED   = AnnotationUtils.fromClass(elements, NotHardCoded.class);
    }

    @Override
    public HardCodedAnnotatedTypeFactory createFactory(CompilationUnitTree root) {
        return new HardCodedAnnotatedTypeFactory(this, root);
    }

    @Override
    protected HardCodedVisitor createSourceVisitor(CompilationUnitTree root) {
        // The false turns off inference and enables checking the type system.
        return new HardCodedVisitor(this, root, this, false);
    }

//    @Override
//    public boolean isValidUse(AnnotatedDeclaredType declarationType,
//            AnnotatedDeclaredType useType) {
//        return true;
//    }

    @Override
    public boolean needsAnnotation(AnnotatedTypeMirror ty) {
        return !(ty instanceof AnnotatedPrimitiveType
                || ty instanceof AnnotatedTypeVariable);
    }

    @Override
    public AnnotationMirror defaultQualifier() {
        return this.MAYBEHARDCODED;
    }

    @Override
    public AnnotationMirror selfQualifier() {
        return this.NOTHARDCODED;
    }

    @Override
    public boolean withCombineConstraints() {
        return false;
    }
}
