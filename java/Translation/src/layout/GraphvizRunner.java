package layout;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintStream;
import java.util.Scanner;

import level.Board;

/**
 * An object that runs an arbitrary Graphviz tool on a {@link level.Board} and
 * returns the results as a {@link GraphInformation} object.
 * <p>
 * Graphviz must be installed on the system, and the tool used must be invokable
 * from the command line.
 * 
 * @author Nathaniel Mote
 */
class GraphvizRunner
{
   private final GraphvizPrinter printer;
   private final String command;

   /**
    * Constructs a new {@code GraphvizRunner} object that runs the given
    * Graphviz command, and writes output with the given GraphvizPrinter.
    *
    * @param printer
    * The GraphvizPrinter used to convert {@link level.Board}s into the DOT
    * language.
    *
    * @param command
    * The Graphviz command line command to run.
    */
   public GraphvizRunner(GraphvizPrinter printer, String command)
   {
      this.printer = printer;
      this.command = command;
   }

   /**
    * Runs Graphviz on {@code b} and returns the output as a {@link
    * GraphInformation} object.
    *
    * @param b
    * The {@link Board} to run Graphviz on
    */
   public GraphInformation run(Board b)
   {
      Process process;
      try
      {
         process = Runtime.getRuntime().exec(command);
      }
      catch (IOException e)
      {
         throw new RuntimeException(
               "Problem running the system \"" + command +
               "\" command. Check that Graphviz is installed and that \"" +
               command + "\" is in the current process's path", e);
      }
      
      outputBoard(b, process.getOutputStream());
      
      String output = getOutput(process.getInputStream());

      // Waits for the dot process to exit and checks its exit value
      int exitValue;
      try
      {
         exitValue = process.waitFor();
      }
      catch(InterruptedException e)
      {
         // This should not happen -- if it does, it's a fatal error
         throw new RuntimeException(e);
      }
      if (exitValue != 0)
         throw new RuntimeException("dot exited abnormally: exit code " + exitValue);
      
      return DotParser.parse(output);
   }
   
   /**
    * Prints {@code b} in the DOT language to {@code os}, then closes {@code os}
    * <p>
    * Modifies: {@code os}
    * <p>
    * Requires: {@code os} is open.
    */
   private void outputBoard(Board b, OutputStream os)
   {
      PrintStream out = new PrintStream(os);
      printer.print(b, out, null);
      // PrintStream closes its underlying OutputStream when closed
      out.close();
   }
   
   /**
    * Parses the text from {@code is} using {@code DotParser} and outputs the
    * results.
    */
   private String getOutput(InputStream is)
   {
      StringBuilder processOutput = new StringBuilder();
      
      Scanner in = new Scanner(is);
      while (in.hasNextLine())
         processOutput.append(in.nextLine() + "\n");
      // Scanner closes its underlying InputStream when closed
      in.close();
      
      return processOutput.toString();
   }
}
