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

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintStream;

public class Main {

    public static void main(String[] args) {

        Options options = new Options();
        options.addOption("h", "help", false, "print help and exit");
        options.addOption("i", "in", true, "input XML file (defaults to stdin)");
        options.addOption("o", "out", true, "output XML file (defaults to stdout)");
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

        InputStream input = System.in;
        OutputStream output = System.out;

        if (cmd.hasOption("help")) {
            new HelpFormatter().printHelp(80, "optimizer", "Rewrite Verigames XML files", options, "", true);
            return;
        }

        if (cmd.hasOption("in")) {
            String filename = cmd.getOptionValue("in");
            try {
                input = new FileInputStream(filename);
            } catch (FileNotFoundException e) {
                System.err.println("Failed to open input file '" + filename + "' for reading");
                System.exit(1);
                return;
            }
        }

        if (cmd.hasOption("out")) {
            String filename = cmd.getOptionValue("out");
            try {
                output = new FileOutputStream(filename);
            } catch (FileNotFoundException e) {
                 System.err.println("Failed to open output file '" + filename + "' for writing");
                 System.exit(1);
                 return;
            }
        }

        // Enable verbose logging if the user wanted it
        Util.setVerbose(cmd.hasOption("verbose"));

        WorldXMLParser parser = new WorldXMLParser();
        World world = parser.parse(input);

        Optimizer optimizer = new Optimizer();
        world = optimizer.optimizeWorld(world);

        try (PrintStream printStream = new PrintStream(output)) {
            WorldXMLPrinter writer = new WorldXMLPrinter();
            writer.print(world, printStream, null);
        }

    }

}
