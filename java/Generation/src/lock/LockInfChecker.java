package lock;

import javax.annotation.processing.ProcessingEnvironment;
import javax.lang.model.element.AnnotationMirror;
import javax.lang.model.util.Elements;

import com.sun.source.tree.CompilationUnitTree;

import games.GameChecker;
import lock.quals.*;
import checkers.quals.Unqualified;
import checkers.quals.TypeQualifiers;
import checkers.types.AnnotatedTypeFactory;
import checkers.types.AnnotatedTypeMirror;
import checkers.types.AnnotatedTypeMirror.AnnotatedPrimitiveType;
import checkers.types.AnnotatedTypeMirror.AnnotatedTypeVariable;
import javacutils.AnnotationUtils;
import checkers.util.GraphQualifierHierarchy;
import checkers.util.MultiGraphQualifierHierarchy;

@TypeQualifiers({GuardedBy.class})
public class LockInfChecker extends GameChecker<LockInfAnnotatedTypeFactory> {
	public AnnotationMirror GUARDEDBY, UNQUALIFIED;

    public void init(ProcessingEnvironment processingEnv) {
        super.init(processingEnv);
        initChecker(); //TODO: DECIDE IF ALL InferenceTypeCheckers are going to be Checkers and add a good spot for this
    }
    @Override
    public void initChecker() {
        super.initChecker();
        final Elements elements = processingEnv.getElementUtils();

        GUARDEDBY = AnnotationUtils.fromClass(elements, GuardedBy.class);
        UNQUALIFIED  = AnnotationUtils.fromClass(elements, Unqualified.class);
    }

    @Override
    public LockInfAnnotatedTypeFactory createFactory(CompilationUnitTree root) {
        return new LockInfAnnotatedTypeFactory(this, root);
    }

    @Override // TODO make match LockChecker
    protected MultiGraphQualifierHierarchy.MultiGraphFactory createQualifierHierarchyFactory() {
        return new MultiGraphQualifierHierarchy.MultiGraphFactory(this);
        /*
    	MultiGraphQualifierHierarchy.MultiGraphFactory factory = createQualifierHierarchyFactory();

        factory.addQualifier(GUARDEDBY);
        factory.addQualifier(UNQUALIFIED);
        factory.addSubtype(UNQUALIFIED, GUARDEDBY);

        return factory;
        */
    }

    // TODO: how do we use this??
    private final class LockQualifierHierarchy extends GraphQualifierHierarchy {

        public LockQualifierHierarchy(MultiGraphQualifierHierarchy.MultiGraphFactory factory) {
            super(factory, UNQUALIFIED);
        }

        @Override
        public boolean isSubtype(AnnotationMirror rhs, AnnotationMirror lhs) {
            if (AnnotationUtils.areSameIgnoringValues(rhs, UNQUALIFIED)
                    && AnnotationUtils.areSameIgnoringValues(lhs, GUARDEDBY)) {
                return true;
            }
            // Ignore annotation values to ensure that annotation is in supertype map.
            if (AnnotationUtils.areSameIgnoringValues(lhs, GUARDEDBY)) {
                lhs = GUARDEDBY;
            }
            if (AnnotationUtils.areSameIgnoringValues(rhs, GUARDEDBY)) {
                rhs = GUARDEDBY;
            }
            return super.isSubtype(rhs, lhs);
        }
    }

    @Override
    protected LockInfVisitor createSourceVisitor(CompilationUnitTree root) {
        // The false turns off inference and enables checking the type system.
        return new LockInfVisitor(this, root, this, false);
    }

	@Override
	public boolean needsAnnotation(AnnotatedTypeMirror ty) {
        return !(ty instanceof AnnotatedPrimitiveType
                || ty instanceof AnnotatedTypeVariable);
	}

	@Override
	public AnnotationMirror defaultQualifier() {
		return this.UNQUALIFIED;
	}

	@Override
	public AnnotationMirror selfQualifier() {
		return this.UNQUALIFIED;
	}

	@Override
	public boolean withCombineConstraints() {
		return false;
	}

}
