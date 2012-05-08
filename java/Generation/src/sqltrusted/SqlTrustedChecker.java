package sqltrusted;

import trusted.TrustedChecker;
import trusted.quals.Trusted;
import trusted.quals.Untrusted;
import sqltrusted.quals.SqlTrusted;
import sqltrusted.quals.SqlUntrusted;

import javax.annotation.processing.ProcessingEnvironment;

import checkers.inference.InferenceTypeChecker;
import checkers.quals.TypeQualifiers;
import checkers.util.AnnotationUtils;


@TypeQualifiers({ SqlTrusted.class, SqlUntrusted.class })
public class SqlTrustedChecker extends TrustedChecker implements
        InferenceTypeChecker {

    @Override
    protected void setAnnotations() {
    	AnnotationUtils annoFactory = AnnotationUtils.getInstance(env);
        UNTRUSTED = annoFactory.fromClass(SqlUntrusted.class);
        TRUSTED = annoFactory.fromClass(SqlTrusted.class);
    }
}