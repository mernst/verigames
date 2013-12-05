package verigames.optimizer;

import org.apache.commons.cli.BasicParser;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import verigames.level.World;
import verigames.level.WorldXMLParser;
import verigames.level.WorldXMLPrinter;
import verigames.optimizer.model.MismatchException;
import verigames.optimizer.model.NodeGraph;
import verigames.optimizer.model.ReverseMapping;
import verigames.optimizer.model.Solution;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.PrintStream;

/**
 * Main class for the tool that transfers solutions from optimized boards to
 * unoptimized ones.
 */
public class SolutionTransferMain {

    public static void err(Object msg) {
        System.err.println(msg);
        System.exit(1);
    }

    public static void missing(String argname) {
        err("Missing argument: '" + argname + "'");
    }

    public static void main(String[] args) {

        Options options = new Options();
        options.addOption("h", "help", false, "print help and exit");
        options.addOption("f", "from", true, "optimized XML file to read solution from (required; use '-' for stdin)");
        options.addOption("t", "to", true, "unoptimized XML file to transfer solution to (required; use '-' for stdin)");
        options.addOption("m", "mapping", true, "mapping file (required; use '-' for stdin)");
        options.addOption("o", "out", true, "output file to write to (defaults to stdout)");
        options.addOption("v", "verbose", false, "enable excessive logging to stderr");

        CommandLineParser commandLineParser = new BasicParser();
        CommandLine cmd;
        try {
            cmd = commandLineParser.parse(options, args);
        } catch (ParseException e) {
            System.err.println("Failed to parse command-line options: " + e);
            System.exit(1);
            return; // because Java's flow analysis can't tell that System.exit stops flow
        }

        if (cmd.hasOption("help")) {
            new HelpFormatter().printHelp(80, "transfer-solution", "Transfer solutions from optimized worlds", options, "", true);
            return;
        }

        // Enable verbose logging if the user wanted it
        Util.setVerbose(cmd.hasOption("verbose"));

        // Read arguments
        String fromFile = cmd.getOptionValue("from");
        String toFile = cmd.getOptionValue("to");
        String mappingFile = cmd.getOptionValue("mapping");
        String outputFile = cmd.getOptionValue("out", "-");

        if (fromFile == null) { missing("from"); return; }
        if (toFile == null) { missing("to"); return; }
        if (mappingFile == null) { missing("mapping"); return; }

        final WorldXMLParser worldParser = new WorldXMLParser(true, false);
        final World optimized;
        final Solution optimizedSolution;
        try {
            optimized = worldParser.parse(Util.getInputStream(fromFile));
            optimizedSolution = new Solution(optimized);
        } catch (FileNotFoundException e) {
            err("Failed to open optimized XML file '" + fromFile + "' for reading");
            return;
        }

        final World unoptimized;
        try {
            unoptimized = worldParser.parse(Util.getInputStream(toFile));
        } catch (FileNotFoundException e) {
            err("Failed to open unoptimized XML file '" + toFile + "' for reading");
            return;
        }

        final ReverseMapping mapping;
        try {
            mapping = ReverseMapping.load(Util.getInputStream(mappingFile));
        } catch (FileNotFoundException e) {
            err("Failed to open mapping file '" + toFile + "' for reading");
            return;
        } catch (IOException e) {
            err("Failed to read mapping file '" + toFile + "': " + e);
            return;
        }

        try {
            Solution solution = mapping.solutionForUnoptimized(
                    new NodeGraph(unoptimized),
                    new NodeGraph(optimized),
                    optimizedSolution);
            solution.applyTo(unoptimized);
        } catch (MismatchException e) {
            err("Solution transfer failed: " + e);
            System.exit(1);
            return;
        }

        try {
            new WorldXMLPrinter().print(
                    unoptimized,
                    new PrintStream(Util.getOutputStream(outputFile)),
                    null);
        } catch (FileNotFoundException e) {
            err("Failed to open output file '" + outputFile + "' for writing");
            System.exit(1);
            return;
        }

    }

}
