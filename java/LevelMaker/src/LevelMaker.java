import java.io.File;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.Result;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

//breaks up an xml file into managable chunks
//right now just separates the levels, saving separate files based on level name
public class LevelMaker
{
	 public static void main(String arg[])
	 {
	    try {
	 
			File arg1File = new File(arg[0]);
			File outputDirectory = null;
			if(arg.length > 1)
				outputDirectory = new File(arg[1]);

			
			if(!arg1File.isDirectory())
				createLevels(arg1File, outputDirectory);
			else
			{
				for (File file : arg1File.listFiles()) {
				    if (file.getName().toLowerCase().endsWith((".xml"))) {
				    	createLevels(file, outputDirectory);
				    }
				  }
			}
	    }
	    catch(Exception e)
	    {
	    }
	 }
	 
	 static void createLevels(File fXmlFile, File outputDirectory)
	 {
		 try {
			DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
			dbFactory.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);

			DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
			Document doc = dBuilder.parse(fXmlFile);
			
			NodeList levels = doc.getElementsByTagName("level");
			for(int i=0; i<levels.getLength(); i++)
			{
				Element level = (Element)levels.item(i);
				String name = level.getAttribute("name");
				
				DocumentBuilder docBuilder = dbFactory.newDocumentBuilder();
				Document newDoc = docBuilder.newDocument();
				Element rootElement = newDoc.createElement("world");
				newDoc.appendChild(rootElement);
				Node newLevel = newDoc.importNode(level, true);
				rootElement.appendChild(newLevel);
				// Prepare the DOM document for writing
		        Source source = new DOMSource(newDoc);

		        // Prepare the output file
		        File file;
		        if(outputDirectory != null)
		        	file = new File(outputDirectory, name+".xml");
		        else
		        	file = new File(name+".xml");
		        Result result = new StreamResult(file);

		        // Write the DOM document to the file
		        Transformer xformer = TransformerFactory.newInstance().newTransformer();
		        xformer.transform(source, result);
			}
			
	    }
	    catch(Exception e)
	    {
	    	
	    }
	 }
}
