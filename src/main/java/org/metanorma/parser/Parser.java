package org.metanorma.parser;

import java.io.BufferedWriter;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;
import org.xml.sax.SAXException;

/**
 *
 * @author Alexander Dyuzhev
 */
public class Parser {
    public static void main(String[] args) {
        SAXParserFactory saxParserFactory = SAXParserFactory.newInstance();
        try {
            SAXParser saxParser = saxParserFactory.newSAXParser();
            MetanormaHandler handler = new MetanormaHandler();
            String inputFile = args[0];
            saxParser.parse(new File(inputFile), handler);
            
            MetanormaElement metanormaDocument = handler.getRoot();
            //System.out.println(root);
            String xmlContent = metanormaDocument.toXML();
            String outputFile = inputFile + ".out.xml";
            try (BufferedWriter writer = Files.newBufferedWriter(Paths.get(outputFile))) {
                writer.write(xmlContent);
            }
        } catch (ParserConfigurationException | SAXException | IOException e) {
            e.printStackTrace();
        }
    }
}
