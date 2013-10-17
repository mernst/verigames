package verigames.visualizer;

import org.apache.commons.cli.BasicParser;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import verigames.layout.LayoutDebugger;
import verigames.level.World;
import verigames.level.WorldXMLParser;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStream;

public class Main {

    public static void main(String[] args) {

        Options options = new Options();
        options.addOption("h", "help", false, "print help and exit");
        options.addOption("i", "in", true, "input XML file (defaults to stdin)");
        options.addOption("o", "out", true, "output folder");

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
        File outputFolder;

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
            outputFolder = new File(filename);
        } else {
            System.err.println("Missing argument '-o FOLDER' or '--out FOLDER'");
            System.exit(1);
            return;
        }

        WorldXMLParser parser = new WorldXMLParser();
        World world = parser.parse(input);
        String path = outputFolder.getAbsolutePath();

        boolean success = outputFolder.mkdirs();
        if (!success) {
            System.err.println("Failed to create folder '" + path + "'");
            System.exit(1);
            return;
        }

        LayoutDebugger.layout(world, path);

    }

}
