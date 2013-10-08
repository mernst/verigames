package games;

import checkers.basetype.BaseTypeChecker;
import checkers.inference.InferenceAnnotatedTypeFactory;
import checkers.inference.InferenceTypeChecker;
import checkers.types.AnnotatedTypeMirror;
import checkers.types.SubtypingAnnotatedTypeFactory;
import checkers.types.TypeHierarchy;

public abstract class GameChecker<REAL_TYPE_FACTORY extends SubtypingAnnotatedTypeFactory<?>>
       extends BaseTypeChecker<REAL_TYPE_FACTORY> implements InferenceTypeChecker {

    @Override
    protected TypeHierarchy createTypeHierarchy() {
        return new TypeHierarchy(this, getQualifierHierarchy()) {
        	@Override
        	public boolean isSubtype(AnnotatedTypeMirror sub, AnnotatedTypeMirror sup) {
        	
		        if (sub.getEffectiveAnnotations().isEmpty() ||
		                sup.getEffectiveAnnotations().isEmpty()) {
		            // TODO: The super method complains about empty annotations. Prevent this.
		            return true;
		        }
		        	return super.isSubtype(sub, sup);
		    	}
        };
    }

}
