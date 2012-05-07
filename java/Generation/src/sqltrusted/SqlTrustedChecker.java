package sqltrusted;

import trusted.TrustedChecker;
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
    public void initChecker(ProcessingEnvironment env) {
    	AnnotationUtils annoFactory = AnnotationUtils.getInstance(env);
        initChecker(env, annoFactory.fromClass(SqlTrusted.class), annoFactory.fromClass(SqlUntrusted.class));
    }

}