package nninf;

import javax.annotation.processing.ProcessingEnvironment;
import javax.lang.model.element.AnnotationMirror;

import nninf.quals.NonNull;
import nninf.quals.Nullable;
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

@TypeQualifiers({ NonNull.class, Nullable.class })
public class NninfChecker extends BaseTypeChecker implements
        InferenceTypeChecker {
    public AnnotationMirror NULLABLE, NONNULL;

    @Override
    public void initChecker(ProcessingEnvironment env) {
        super.initChecker(env);
        AnnotationUtils annoFactory = AnnotationUtils.getInstance(env);
        NULLABLE = annoFactory.fromClass(Nullable.class);
        NONNULL = annoFactory.fromClass(NonNull.class);
    }

    @Override
    public AnnotatedTypeFactory createFactory(CompilationUnitTree root) {
        return new NninfAnnotatedTypeFactory(this, root);
    }

    @Override
    protected NninfVisitor createSourceVisitor(CompilationUnitTree root) {
        // The false turns off inference and enables checking the type system.
        return new NninfVisitor(this, root, this, false);
    }

    @Override
    public boolean isValidUse(AnnotatedDeclaredType declarationType,
            AnnotatedDeclaredType useType) {
        return true;
    }

    @Override
    public boolean needsAnnotation(AnnotatedTypeMirror ty) {
        return !(ty instanceof AnnotatedPrimitiveType
                || ty instanceof AnnotatedTypeVariable);
    }

    @Override
    public AnnotationMirror defaultQualifier() {
        return this.NULLABLE;
    }

    @Override
    public AnnotationMirror selfQualifier() {
        return this.NONNULL;
    }

    @Override
    public boolean withCombineConstraints() {
        return false;
    }

    @Override
    public boolean isSubtype(AnnotatedTypeMirror sub, AnnotatedTypeMirror sup) {
        if (sub.getEffectiveAnnotations().isEmpty() ||
                sup.getEffectiveAnnotations().isEmpty()) {
            // TODO: The super method complains about empty annotations. Prevent this.
            return true;
        }
        return super.isSubtype(sub, sup);
    }
}