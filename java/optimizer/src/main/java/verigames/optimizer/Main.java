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
import verigames.optimizer.model.ReverseMapping;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.PrintStream;

public class Main {

    public static void main(String[] args) {

        Options options = new Options();
        options.addOption("h", "help", false, "print help and exit");
        options.addOption("i", "in", true, "input XML file (defaults to stdin)");
        options.addOption("o", "out", true, "output XML file (defaults to stdout)");
        options.addOption("m", "mapping", true, "output mapping file (defaults to stdout)");
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

        String inputFile = "-";
        String outputFile = "-";
        String mappingFile = "-";

        if (cmd.hasOption("help")) {
            new HelpFormatter().printHelp(80, "optimizer", "Rewrite Verigames XML files", options, "", true);
            return;
        }

        if (cmd.hasOption("in")) {
            inputFile = cmd.getOptionValue("in");
        }

        if (cmd.hasOption("out")) {
            outputFile = cmd.getOptionValue("out");
        }

        if (cmd.hasOption("mapping")) {
            mappingFile = cmd.getOptionValue("mapping");
        }

        // Enable verbose logging if the user wanted it
        Util.setVerbose(cmd.hasOption("verbose"));

        System.err.println("Reading world...");
        WorldXMLParser parser = new WorldXMLParser();
        World world;
        try {
            world = parser.parse(Util.getInputStream(inputFile));
        } catch (FileNotFoundException e) {
            System.err.println("Failed to open input XML file '" + inputFile + "' for reading");
            System.exit(1);
            return;
        }

        System.err.println("Starting optimization...");
        Optimizer optimizer = new Optimizer();
        ReverseMapping mapping = new ReverseMapping();
        world = optimizer.optimizeWorld(world, mapping);

        System.err.println("Writing world...");
        try {
            PrintStream printStream = new PrintStream(Util.getOutputStream(outputFile));
            WorldXMLPrinter writer = new WorldXMLPrinter();
            writer.print(world, printStream, null);
        } catch (FileNotFoundException e) {
            System.err.println("Failed to open output XML file '" + outputFile + "' for writing");
            System.exit(1);
            return;
        }

        System.err.println("Writing reverse mapping...");
        try {
            mapping.export(Util.getOutputStream(mappingFile));
        } catch (FileNotFoundException e) {
            System.err.println("Failed to open mapping output file '" + mappingFile + "' for writing");
            System.exit(1);
            return;
        } catch (IOException e) {
            System.err.println("Failed to write mapping file '" + mappingFile + "': " + e);
            System.exit(1);
            return;
        }

        System.err.println("Done");

    }

}
