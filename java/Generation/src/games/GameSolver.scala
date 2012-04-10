package games

import checkers.inference._
import checkers.util.AnnotationUtils
import scala.collection.mutable.HashMap
import com.sun.source.tree.Tree.Kind
import javax.lang.model.element.AnnotationMirror
import verigames.level._
import checkers.inference.LiteralNull
import checkers.inference.AbstractLiteral

/**
 * An abstract base class for all game solvers.
 */
abstract class GameSolver(
    /** All variables used in this program. */
    variables: List[Variable],
    /** Empty, b/c there is no viewpoint adaptation (yet?). */
    combvariables: List[CombVariable],
    /** All constraints that have to be fulfilled. */
    constraints: List[Constraint],
    /** Weighting information. Currently empty & ignored, as a human solves the game. */
    weights: List[WeightInfo],
    /** The command-line parameters. */
    params: TTIRun)
  extends ConstraintSolver(variables, combvariables, constraints, weights, params) {

    def solve(): Option[Map[AbstractVariable, AnnotationMirror]] = {
      // Create the world!
      val world = createWorld()

      // Assign a layout to the world.
      verigames.layout.WorldLayout.layout(world)

      // TODO: add an option for the file name
      val xmlFile = new java.io.File("World.xml") // params.optWorldXMLFileName)
      // TODO: check for existing file
      val output = new java.io.PrintStream(new java.io.FileOutputStream(xmlFile))
      new WorldXMLPrinter().print(world, output, null)
      output.close()

      // Return as solution a mapping back to the variable IDs. This results in
      // an AFU file with "@checkers.inference.quals.VarAnnot(42)" being written.
      // When the interactive part is done it can simply replace these placeholders
      // with the inferred solutions.
      // TODO: pass the variable IDs to the correct nodes in the World.
      val res = new HashMap[AbstractVariable, AnnotationMirror]
      variables foreach { v => {
        res += (v -> v.getAnnotation())
      }} 
      Some(res.toMap)
    }

    // InferenceMain already measures the time that the solver overall takes.
    // We cannot measure the time used by the human, so just suppress this.
    def timing: String = null

    /**
     * Create the world!
     */
    def createWorld(): World = {
      val world = new World()

      // First create all the levels and boards.
      createBoards(world)
      // Then represent all the constraints.
      handleConstraints(world)
      // Optimize the world, removing unnecessary complexity.
      optimizeWorld(world)
      // Finally, add any necessary plumbing to the end of each board.
      finalizeWorld(world)

      world
    }

    /**
     * First, go through all variables and create a level for each occurring
     * class and a board for each occurring method.
     */
    def createBoards(world: World)

    /**
     * Go through all constraints and add the corresponding piping to the boards.
     */
    def handleConstraints(world: World)

    /**
     * Finalize the world by closing the scope of all variables and adding
     * the necessary edges to the output.
     */
    def finalizeWorld(world: World)

    /**
     * Sanitize a string to make it a suitable XML identifier.
     */
    def cleanUpForXML(name: String): String = {
      name.replace('(', '-')
        .replace(')', '-')
        .replace(':', '-')
        .replace('#', '-')
        .replace(';', '-')
        .replace('/', '-')
        // Constructors are named "<init>" and "<cinit>"
        .replace('<', '-')
        .replace('>', '-')
        // Arrays in bytecode
        .replace('[', '-')
    }

    /**
     * Helper method to determine the name of the subboard used for a field getter.
     */
    def getFieldAccessorName(fvp: FieldVP): String = {
      fvp.getFQName + "--GET"
    }

    /**
     * Helper method to determine the name of the subboard used for a field setter.
     */
    def getFieldSetterName(fvp: FieldVP): String = {
      fvp.getFQName + "--SET"
    }

    /**
     * Type-system independent optimizations of the world.
     */
    def optimizeWorld(world: World) {/*
      import scala.collection.JavaConversions._

      val emptyLevels = new collection.mutable.ListBuffer[String]
      world.getLevels() foreach ( kv => { val (levelName, level) = kv
        var levelEmpty = true
        level.getBoards() foreach ( kv => { val (boardName, board) = kv
          if (!board.getEdges().isEmpty()) {
            println("Board with edges: " + board.getEdges())
            levelEmpty = false
          }
        })
        if (levelEmpty) {
          emptyLevels.add(levelName)
        }
      })
      println("Empty levxxxels: " + emptyLevels)
      */
    }
}