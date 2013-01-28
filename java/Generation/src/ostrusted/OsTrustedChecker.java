package ostrusted;

import trusted.TrustedChecker;
import ostrusted.quals.OsTrusted;
import ostrusted.quals.OsUntrusted;

import checkers.inference.InferenceTypeChecker;
import checkers.quals.TypeQualifiers;
import checkers.util.AnnotationUtils;

import javax.lang.model.util.Elements;

/**
 * 
 * @author sdietzel
 * [2]  CWE-78  Improper Neutralization of Special Elements used in an OS Command ('OS Command Injection')
 */

@TypeQualifiers({ OsTrusted.class, OsUntrusted.class })
public class OsTrustedChecker extends TrustedChecker implements
        InferenceTypeChecker {

    @Override
    protected void setAnnotations() {
    	System.out.println("OSTRUSTEDCHECKER!!!!");
        final Elements elements = processingEnv.getElementUtils();      //TODO: Makes you think a utils is being returned

        UNTRUSTED = AnnotationUtils.fromClass(elements, OsUntrusted.class);
        TRUSTED   = AnnotationUtils.fromClass(elements, OsTrusted.class);
    }
}