package internal.quals;

import java.lang.annotation.*;

import com.sun.source.tree.Tree;

import checkers.quals.DefaultQualifierInHierarchy;
import checkers.quals.ImplicitFor;
import checkers.quals.SubtypeOf;
import checkers.quals.TypeQualifier;

/**
 * @see Public
 */
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target({ ElementType.TYPE_USE, ElementType.TYPE_PARAMETER })
@TypeQualifier
@SubtypeOf({})
@DefaultQualifierInHierarchy
@ImplicitFor(
	    trees={
	        Tree.Kind.STRING_LITERAL
	    })
public @interface Internal {}