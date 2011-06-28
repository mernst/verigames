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

public class TranslationVisitor extends
      SimpleTreeVisitor</* @Nullable */Void, BoardBuilder>
{
   @Override public Void visitIf(IfTree node, BoardBuilder b)
   {
      return DEFAULT_VALUE;
   }
}
