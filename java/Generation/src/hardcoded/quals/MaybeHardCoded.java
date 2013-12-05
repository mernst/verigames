package hardcoded.quals;

import java.lang.annotation.*;

import com.sun.source.tree.Tree;

import checkers.quals.DefaultQualifierInHierarchy;
import checkers.quals.ImplicitFor;
import checkers.quals.SubtypeOf;
import checkers.quals.TypeQualifier;

/**
 * @see MaybeHardCoded
 */
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target({ ElementType.TYPE_USE, ElementType.TYPE_PARAMETER })
@TypeQualifier
@SubtypeOf({})
@DefaultQualifierInHierarchy
@ImplicitFor(
    trees={
        Tree.Kind.BOOLEAN_LITERAL,
        Tree.Kind.CHAR_LITERAL,
        Tree.Kind.DOUBLE_LITERAL,
        Tree.Kind.FLOAT_LITERAL,
        Tree.Kind.INT_LITERAL,
        Tree.Kind.LONG_LITERAL,
        Tree.Kind.STRING_LITERAL,
    })
public @interface MaybeHardCoded {

}
