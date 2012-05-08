package verigames.utilities;

/**
 * @author Brian Walker
 */

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.io.PrintStream;
import java.util.HashMap;
import java.util.Map;
import java.util.Scanner;

import verigames.level.GameResults;


public class JAIFParser {
    private static final String NON_NULL = "@nninf.quals.NonNull";
    private static final String NULL = "@nninf.quals.Nullable";

    public static void main(String[] args) throws FileNotFoundException {
        String xmlPath = "updatedXML.xml";
        String jaifPath = "inference.jaif";
        String outputFile = "updatedInference.jaif";

        if(args.length == 3) {
            xmlPath = args[0];
            jaifPath = args[1];
            outputFile = args[2];
        } else if(args.length != 0) {
            System.out.println("ERROR: Requires 0 or 3 arguments");
            System.out.println("Usage: JAIFParser [xml file] [jaif file] [output file]");
        }
        Map<Integer, Boolean> results = new HashMap<Integer, Boolean>();
        InputStream in = new FileInputStream(new File(xmlPath));
        results = GameResults.chuteWidth(in);
        parseJaif(results, jaifPath, outputFile);
    }

    /**
     * Parses the inference.jaif file provided by verigames.jar and updates the variable values
     * with a boolean of true/false depending on the results obtained from the updates xml file
     * after the user plays the game.
     * @param values Map<Integer, Boolean> where the integer is the variable id and the boolean
     * is the value to replace the variable id with.
     * @throws FileNotFoundException thrown if the file inference.jaif is not found in the current
     * directory.
     */
    private static void parseJaif(Map<Integer, Boolean> values, String jaifPath,
            String outputFile) throws FileNotFoundException {
        if(values == null) {
            throw new IllegalArgumentException("Map passed must not be null");
        }
        Scanner in = new Scanner(new File(jaifPath));
        PrintStream out = new PrintStream(new File(outputFile));
        while(in.hasNextLine()) {
            String line = in.nextLine();
            int start = -1;
            if((start = line.indexOf("@checkers.inference.quals.VarAnnot")) != -1) {
                int end = start + ("@checkers.inference.quals.varAnnot(".length());
                int key = Integer.parseInt(line.substring(end, line.length() - 1));
                out.print(line.substring(0,start));
                out.println(values.get(key)?NON_NULL:NULL);
            } else
                out.println(line);
        }
    }
}
