package layout;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintStream;
import java.util.Scanner;

import level.Board;

/**
 * A function object that runs Graphviz's "dot" tool on a Board and returns the
 * results as a {@link GraphInformation} object.
 * <p>
 * Graphviz must be installed on the system, and the "dot" tool must be
 * invokable from the command line.
 * 
 * @author Nathaniel Mote
 * 
 */
class GraphvizRunner
{
   private final DotPrinter printer;
   private final DotParser parser;
   private final String command;

   public GraphvizRunner(DotPrinter printer, DotParser parser, String command)
   {
      this.printer = printer;
      this.parser = parser;
      this.command = command;
   }

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
      
      GraphInformation info = parseDot(process.getInputStream());

      // Waits for the dot process to exit and checks its exit value
      int exitValue;
      try
      {
         exitValue = process.waitFor();
      }
      catch(InterruptedException e)
      {
         throw new RuntimeException(e);
      }
      if (exitValue != 0)
         throw new RuntimeException("dot exited abnormally: exit code " + exitValue);
      
      return info;
   }
   
   /**
    * Prints {@code b} in the DOT language to {@code os}, then closes {@code os}
    * <p>
    * Modifies: {@code os}
    */
   private void outputBoard(Board b, OutputStream os)
   {
      PrintStream out = new PrintStream(os);
      printer.print(b, out, null);
      // PrintStream closes its underlying OutputStream when closed
      out.close();
   }
   
   private GraphInformation parseDot(InputStream is)
   {
      StringBuilder processOutput = new StringBuilder();
      
      Scanner in = new Scanner(is);
      while (in.hasNextLine())
         processOutput.append(in.nextLine() + "\n");
      // Scanner closes its underlying InputStream when closed
      in.close();
      
      return parser.parse(processOutput.toString());
   }
}
