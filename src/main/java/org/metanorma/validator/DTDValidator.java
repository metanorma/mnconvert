package org.metanorma.validator;

import org.metanorma.mnconvert;
import org.metanorma.utils.ResourcesUtils;
import org.metanorma.utils.Util;
import org.metanorma.utils.LoggerHelper;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import org.w3c.dom.DOMImplementation;
import org.w3c.dom.Document;
import org.w3c.dom.DocumentType;
import org.xml.sax.InputSource;

public class DTDValidator extends Validator {

    private static final Logger logger = Logger.getLogger(LoggerHelper.LOGGER_NAME);
    boolean DEBUG = false;
    
    public DTDValidator (File xml) {
        super(xml);
    }

    @Override
    public List<String> validate(Object checkAgainst) {
        
        String checkSrc;
        if (checkAgainst instanceof CheckAgainstEnum) {
            this.checkAgainst = (CheckAgainstEnum) checkAgainst;
            checkSrc = CheckAgainstMap.getMap().get(checkAgainst);
        } else {
            filepathDTDorXSD = (String) checkAgainst;
            checkSrc = filepathDTDorXSD;
        }
        
        String checkSrcPath = "/" + new File(checkSrc).getParentFile().toString();

        logger.log(Level.INFO, "Validate XML against DTD {0}...", checkSrc);

        final Path tmpfilepath = Paths.get(Util.getJavaTempDir(), UUID.randomUUID().toString());

        try {        
            DocumentBuilderFactory dbfactory = DocumentBuilderFactory.newInstance();
            dbfactory.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);
            
            DocumentBuilder builder = dbfactory.newDocumentBuilder();
            
            // copy dtd folder and xml file into the temp folder

            Files.createDirectories(tmpfilepath);
            
            // to debug jar
            //jar:file:/C:/Metanorma/mn2sts/target/mn2sts-1.1.jar!/NISO-STS-extended-1-MathML3-DTD
            //java.net.URL url = new java.net.URL("jar:file:/C:\\Metanorma\\mn2sts\\mn2sts-1.1.jar!/NISO-STS-extended-1-MathML3-DTD");
            //ResourcesUtils.copyResources(url , checkSrcPath, tmpfilepath.toFile());

            //add <!DOCTYPE standard SYSTEM "dtd path">
            TransformerFactory transformerFactory = TransformerFactory.newInstance();
            Transformer transformer = transformerFactory.newTransformer();
            transformer.setOutputProperty(OutputKeys.INDENT, "yes");
            transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "no");
            transformer.setOutputProperty(OutputKeys.METHOD, "xml");

            Document document = builder.parse(xml);
            DOMImplementation domImpl = document.getImplementation();
            DocumentType doctype;
            if (checkAgainst instanceof CheckAgainstEnum) {
                ResourcesUtils.copyResources(getClass().getResource(checkSrcPath), checkSrcPath, tmpfilepath.toFile());
                doctype = domImpl.createDocumentType("doctype",
                "",
                tmpfilepath + File.separator + checkSrc);
            } else {
                doctype = domImpl.createDocumentType("doctype",
                "",
                checkSrc);
            }
            
            //transformer.setOutputProperty(OutputKeys.DOCTYPE_PUBLIC, doctype.getPublicId());
            transformer.setOutputProperty(OutputKeys.DOCTYPE_SYSTEM, doctype.getSystemId());
            DOMSource source = new DOMSource(document);
            File xmlWithDTD = Paths.get(tmpfilepath.toString(), xml.getName()).toFile();//xmlout.getAbsolutePath() + ".tmp";
            StreamResult result = new StreamResult(xmlWithDTD);

            transformer.transform(source, result);
            
            InputStream inputStream = new FileInputStream(xmlWithDTD);
            Reader reader = new InputStreamReader(inputStream,"UTF-8");
            dbfactory = DocumentBuilderFactory.newInstance();
            dbfactory.setValidating(true);
            builder = dbfactory.newDocumentBuilder();
            builder.setErrorHandler(errorHandler);
            builder.parse(new InputSource(reader));

        } catch (Exception ex) {
            exceptions.add("Validation error: " + ex.toString());
        }
        finally {
            // flush temporary folder
            if (!DEBUG) {
                Util.FlushTempFolder(tmpfilepath);
            }
        }
        return exceptions;        
    }
    
    public void setDebug (boolean debug) 
    {
        this.DEBUG = debug;
    }
}
