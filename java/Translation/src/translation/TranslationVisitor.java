package translation;

import levelBuilder.BoardBuilder;

import com.sun.source.util.SimpleTreeVisitor;

/**
 * @author Nathaniel Mote
 * @author Stephanie Dietzel
 * 
 * A visitor to Trees in the Compiler API. Builds or extends for Trees
 * using the passed-in BoardBuilder. A call to visit modifies the given
 * BoardBuilder through mutation, so no return value is needed.
 * 
 */

public class TranslationVisitor extends SimpleTreeVisitor<Void, BoardBuilder>
{
   
}
