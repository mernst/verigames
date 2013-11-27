package ostrusted.quals;

import checkers.quals.PolymorphicQualifier;
import checkers.quals.TypeQualifier;

import java.lang.annotation.*;

/**
 * A polymorphic qualifier for the Tainting type system.
 *
 * @checker_framework_manual #tainting-checker Tainting Checker
 */
@Documented
@TypeQualifier
@PolymorphicQualifier
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.TYPE_USE, ElementType.TYPE_PARAMETER})
public @interface PolyOsTrusted {}
