package trusted;


import javax.annotation.processing.ProcessingEnvironment;
import javax.lang.model.element.AnnotationMirror;
import javax.lang.model.util.Elements;

import trusted.quals.Trusted;
import trusted.quals.Untrusted;
import checkers.basetype.BaseTypeChecker;
import checkers.inference.InferenceTypeChecker;
import checkers.quals.TypeQualifiers;
import checkers.types.AnnotatedTypeFactory;
import checkers.types.AnnotatedTypeMirror;
import checkers.types.AnnotatedTypeMirror.AnnotatedDeclaredType;
import checkers.types.AnnotatedTypeMirror.AnnotatedPrimitiveType;
import checkers.types.AnnotatedTypeMirror.AnnotatedTypeVariable;
import checkers.util.AnnotationUtils;

import com.sun.source.tree.CompilationUnitTree;

/**
 * 
 * The Trusted checker is a generic checker for expressing objects as "trusted" or not.
 * It should most likely be only used abstractly; specific subtypes with their own
 * qualifiers should be created to represent most categories of trusted (e.g. for SQL
 * or OS commands).
 * 
 */
@TypeQualifiers({ Trusted.class, Untrusted.class })
public class TrustedChecker extends BaseTypeChecker implements
        InferenceTypeChecker {
    public AnnotationMirror UNTRUSTED, TRUSTED;

    @Override
    public void initChecker() {
    	super.initChecker();
    	setAnnotations();
    }

    protected void setAnnotations() {
        final Elements elements = processingEnv.getElementUtils();
        UNTRUSTED = AnnotationUtils.fromClass(elements, Untrusted.class);
        TRUSTED   = AnnotationUtils.fromClass(elements, Trusted.class);
    }

    @Override
    public AnnotatedTypeFactory createFactory(CompilationUnitTree root) {
        return new TrustedAnnotatedTypeFactory(this, root);
    }

    @Override
    protected TrustedVisitor createSourceVisitor(CompilationUnitTree root) {
        // The false turns off inference and enables checking the type system.
        return new TrustedVisitor(this, root, this, false);
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
        return this.UNTRUSTED;
    }

    @Override
    public AnnotationMirror selfQualifier() {
        return this.TRUSTED;
    }

    @Override
    public boolean withCombineConstraints() {
        return false;
    }
//
//    @Override
//    public boolean isSubtype(AnnotatedTypeMirror sub, AnnotatedTypeMirror sup) {
//        if (sub.getEffectiveAnnotations().isEmpty() ||
//                sup.getEffectiveAnnotations().isEmpty()) {
//            // TODO: The super method complains about empty annotations. Prevent this.
//            return true;
//        }
//        return super.isSubtype(sub, sup);
//    }
}