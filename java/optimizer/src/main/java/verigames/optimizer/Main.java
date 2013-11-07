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

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintStream;

public class Main {

    public static void main(String[] args) {

        Options options = new Options();
        options.addOption("h", "help", false, "print help and exit");
        options.addOption("i", "in", true, "input XML file (defaults to stdin)");
        options.addOption("o", "out", true, "output XML file (defaults to stdout)");
        options.addOption("m", "mapping", true, "output mapping file (defaults to map.txt, give - to use stdout)");
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
        String mappingFilename = "map.txt";

        if (cmd.hasOption("help")) {
            new HelpFormatter().printHelp(80, "optimizer", "Rewrite Verigames XML files", options, "", true);
            return;
        }

        if (cmd.hasOption("in") && !cmd.getOptionValue("in").equals("-")) {
            String filename = cmd.getOptionValue("in");
            try {
                input = new FileInputStream(filename);
            } catch (FileNotFoundException e) {
                System.err.println("Failed to open input file '" + filename + "' for reading");
                System.exit(1);
                return;
            }
        }

        if (cmd.hasOption("out") && !cmd.getOptionValue("out").equals("-")) {
            String filename = cmd.getOptionValue("out");
            try {
                output = new FileOutputStream(filename);
            } catch (FileNotFoundException e) {
                 System.err.println("Failed to open output file '" + filename + "' for writing");
                 System.exit(1);
                 return;
            }
        }

        if (cmd.hasOption("mapping")) {
            mappingFilename = cmd.getOptionValue("mapping");
        }

        // Enable verbose logging if the user wanted it
        Util.setVerbose(cmd.hasOption("verbose"));

        System.err.println("Reading world...");
        WorldXMLParser parser = new WorldXMLParser();
        World world = parser.parse(input);

        System.err.println("Starting optimization...");
        Optimizer optimizer = new Optimizer();
        ReverseMapping mapping = new ReverseMapping();
        world = optimizer.optimizeWorld(world, mapping);

        System.err.println("Writing world...");
        PrintStream printStream = new PrintStream(output);
        WorldXMLPrinter writer = new WorldXMLPrinter();
        writer.print(world, printStream, null);

        System.err.println("Writing reverse mapping...");
        try (OutputStream mappingOutputStream = mappingFilename.equals("-") ? System.out : new FileOutputStream(mappingFilename)) {
            mapping.export(mappingOutputStream);
        } catch (FileNotFoundException e) {
            System.err.println("Failed to open mapping output file '" + mappingFilename + "' for writing");
            System.exit(1);
            return;
        } catch (IOException e) {
            System.err.println("Failed to write mapping file: " + e);
            System.exit(1);
            return;
        }

        System.err.println("Done");

    }

}
