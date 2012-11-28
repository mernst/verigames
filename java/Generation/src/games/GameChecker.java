package games;

import checkers.basetype.BaseTypeChecker;
import checkers.inference.InferenceTypeChecker;
import checkers.types.AnnotatedTypeMirror;
import checkers.types.TypeHierarchy;

public abstract class GameChecker extends BaseTypeChecker implements InferenceTypeChecker {

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
