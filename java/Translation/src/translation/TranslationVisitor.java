package translation;

import levelBuilder.BoardBuilder;

import com.sun.source.util.SimpleTreeVisitor;
import com.sun.source.tree.*;

/**
 * @author Nathaniel Mote
 * @author Stephanie Dietzel
 * 
 * A visitor to Trees in the Compiler API. Builds or extends for Trees using the
 * passed-in BoardBuilder. A call to visit modifies the given BoardBuilder
 * through mutation, so no return value is needed.
 * 
 */

// SimpleTreeVisitor ought to be annotated as:
// public class SimpleTreeVisitor <R extends /*@Nullable*/ Object,P> implements TreeVisitor<R,P> {
// but since it is not, suppress the warning due to this extends clause.
@SuppressWarnings("nullness")
public class TranslationVisitor extends
      SimpleTreeVisitor</* @Nullable */Void, BoardBuilder>
{
   @Override public Void visitIf(IfTree node, BoardBuilder b)
   {
      return DEFAULT_VALUE;
   }
}
