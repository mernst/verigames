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
class DotRunner
{
   public GraphInformation run(Board b)
   {
      Process process;
      try
      {
         process = Runtime.getRuntime().exec("dot");
      }
      catch (IOException e)
      {
         throw new RuntimeException(
               "Problem running the system \"dot\" command. Check that Graphviz is installed and that \"dot\" is in the current process's path", e);
      }
      
      outputBoard(b, process.getOutputStream());
      
      GraphInformation info = parseDot(process.getInputStream());
      
      // Ensures that the dot process has exited
      try
      {
         // throws IllegalThreadStateException if the Process hasn't yet exited
         process.exitValue();
      }
      catch(IllegalThreadStateException e)
      {
         process.destroy();
         throw new RuntimeException("External dot process did not end properly", e);
      }
      
      return info;
   }
   
   /**
    * Prints {@code b} in the DOT language to {@code os}, then closes {@code os}
    * <p>
    * Modifies: {@code os}
    */
   private static void outputBoard(Board b, OutputStream os)
   {
      DotPrinter printer = new DotPrinter();
      PrintStream out = new PrintStream(os);
      printer.print(b, out, null);
      // PrintStream closes its underlying OutputStream when closed
      out.close();
   }
   
   private static GraphInformation parseDot(InputStream is)
   {
      StringBuilder processOutput = new StringBuilder();
      
      Scanner in = new Scanner(is);
      while (in.hasNextLine())
         processOutput.append(in.nextLine() + "\n");
      // Scanner closes its underlying InputStream when closed
      in.close();
      
      DotParser parser = new DotParser();
      return parser.parse(processOutput.toString());
   }
}
