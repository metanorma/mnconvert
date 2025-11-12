package org.metanorma;

import java.io.File;
import java.io.IOException;
import java.io.StringReader;
import java.io.StringWriter;
import java.net.URL;
import java.util.Scanner;
import java.util.logging.Level;
import javax.net.ssl.HttpsURLConnection;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.sax.SAXSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import static org.metanorma.Constants.INPUT_LOG;
import static org.metanorma.Constants.INPUT_NOT_FOUND;
import static org.metanorma.Constants.OUTPUT_LOG_RFC2MN;
import static org.metanorma.Constants.XML_INPUT;
import static org.metanorma.Constants.XSL_INPUT;

import org.metanorma.utils.ResourcesUtils;
import org.metanorma.utils.Util;
import static org.metanorma.utils.Util.writeBuffer;
import org.metanorma.validator.RELAXNGValidator;
import org.w3c.dom.Document;
import org.xml.sax.EntityResolver;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;
import org.xml.sax.XMLReader;
import org.xml.sax.helpers.XMLReaderFactory;

/**
 *
 * @author Alexander Dyuzhev
 * 
 * This class for the conversion of an XML2RFC XML file to Metanorma Asciidoc IETF
 */
public class RFC2MN_XsltConverter extends XsltConverter {

    
    private void setDefaultOutputFilePath() {
        if (outputFilePath.isEmpty()) {

            String outputFilePathWithoutExtension = super.getDefaultOutputFilePath();

            outputFilePath = outputFilePathWithoutExtension + outputFormat; // .adoc
            
        }
    }
    
    @Override
    boolean process() {
        try {
            if (inputFilePath.toLowerCase().startsWith("http") || inputFilePath.toLowerCase().startsWith("www.")) {
                isInputFileRemote = true;
                inputFilePath = Util.downloadFile(inputFilePath, tmpfilepath);
                if (inputFilePath.isEmpty()) {
                    return false;
                }
            }
            
            if (!new File(inputFilePath).exists()) {
                logger.severe(String.format(INPUT_NOT_FOUND, XML_INPUT, inputFilePath));
                return false;
            }
            
            if (inputXslPath != null) {
                fileXSL = new File(inputXslPath);
                if (!fileXSL.exists()) {
                    logger.severe(String.format(INPUT_NOT_FOUND, XSL_INPUT, fileXSL));
                    return false;
                }
            }
            
            outputFormat = "adoc"; //RFC2MN supports only adoc output

            setDefaultOutputFilePath();
            
            logger.info(String.format(INPUT_LOG, XML_INPUT, inputFilePath));
            if (fileXSL != null) {
                logger.info(String.format(INPUT_LOG, XSL_INPUT, fileXSL));
            }
            logger.info(String.format(OUTPUT_LOG_RFC2MN, outputFormat.toUpperCase(), outputFilePath));
            logger.info("");
            
            convertrfc2mn();

            logger.info("End!");
            
        } catch (Exception e) {
            e.printStackTrace(System.err);
            return false;
        }
        
        // flush temporary folder
        if (!isDebugMode) {
            Util.FlushTempFolder(tmpfilepath);
        }
        
        return true;
    }
    
    private void convertrfc2mn() throws IOException, TransformerException, SAXException, SAXParseException, ParserConfigurationException {
        
        File fXMLin = new File(inputFilePath);
        File fileOut = new File(outputFilePath);
        
        String xmlString = serialize(fXMLin);
        
        // Checking inputXML against RelaxNG schema
        RELAXNGValidator rngValidator = new RELAXNGValidator();
        boolean isValid = rngValidator.isValid(xmlString); // fXMLin
        
        if(isValid) {
            logger.log(Level.INFO, "{0} is valid.", fXMLin);
        } else {
            String error = rngValidator.getValidationInfo();
            logger.severe(error);
        }
        
        XMLReader rdr = XMLReaderFactory.createXMLReader();
        //rdr.setEntityResolver(entityResolver);

        TransformerFactory factory = TransformerFactory.newInstance();
        Transformer transformer = factory.newTransformer();

        logger.info("Transforming...");
        
        Source src = new SAXSource(rdr, new InputSource(new StringReader(xmlString))); //new FileInputStream(fXMLin)
        
        // linearize XML
        /*Source srcXSLidentity = new StreamSource(Util.getStreamFromResources(getClass().getClassLoader(), "linearize.xsl"));
        transformer = factory.newTransformer(srcXSLidentity);

        StringWriter resultWriteridentity = new StringWriter();
        StreamResult sridentity = new StreamResult(resultWriteridentity);
        transformer.transform(src, sridentity);
        String xmlidentity = resultWriteridentity.toString();*/

        // load linearized xml
        //src = new StreamSource(new StringReader(xmlidentity));
        
        Source srcXSL;
        
        if (fileXSL != null) { //external xsl
            srcXSL = new StreamSource(fileXSL);
        } else { // internal xsl
            srcXSL = new StreamSource(ResourcesUtils.getStreamFromResources(getClass().getClassLoader(), "rfc2mn.adoc.xsl"));
        }
        
        transformer = factory.newTransformer(srcXSL);
            
        StringWriter resultWriter = new StringWriter();
        StreamResult sr = new StreamResult(resultWriter);

        transformer.transform(src, sr);
        String adocRFC = resultWriter.toString();

        File adocFileOut = fileOut;

        try (Scanner scanner = new Scanner(adocRFC)) {
            String outputFile = adocFileOut.getAbsolutePath();
            StringBuilder sbBuffer = new StringBuilder();
            while (scanner.hasNextLine()) {
                String line = scanner.nextLine();
                sbBuffer.append(line);
                sbBuffer.append(System.getProperty("line.separator"));
            }
            writeBuffer(sbBuffer, outputFile);
        }
        
    }
    
    public String serialize(File fXMLin) throws ParserConfigurationException, TransformerException, SAXException, IOException {
        // for xi:include processing
        DocumentBuilderFactory dbfactory = DocumentBuilderFactory.newInstance();
        dbfactory.setNamespaceAware(true);
        dbfactory.setXIncludeAware(true);
        DocumentBuilder dBuilder = dbfactory.newDocumentBuilder();
        
        // skip DTD validating 
        // found here: https://moleshole.wordpress.com/2009/10/08/ignore-a-dtd-when-using-a-transformer/
        EntityResolver entityResolver = new EntityResolver() {
            @Override
            public InputSource resolveEntity(String publicId, String systemId) throws SAXException, IOException {
                if (systemId.endsWith(".dtd")) {
                        StringReader stringInput = new StringReader(" ");
                        return new InputSource(stringInput);
                }
                else if (systemId.toLowerCase().startsWith("https")) {
                    
                    HttpsTrustManager.allowAllSSL();
                    
                    URL obj = new URL(systemId);
                    HttpsURLConnection conn = (HttpsURLConnection) obj.openConnection();

                    int status = conn.getResponseCode();
                    if ((status != HttpsURLConnection.HTTP_OK) &&
                        (status == HttpsURLConnection.HTTP_MOVED_TEMP
                        || status == HttpsURLConnection.HTTP_MOVED_PERM
                        || status == HttpsURLConnection.HTTP_SEE_OTHER)) {

                        String newUrl = conn.getHeaderField("Location");
                        conn = (HttpsURLConnection) new URL(newUrl).openConnection();
                    }
                    
                    return new InputSource(conn.getInputStream());

                } else {
                    return null; // use default behavior
                }
            }
        };
        dBuilder.setEntityResolver(entityResolver);
        
        Document doc = dBuilder.parse(fXMLin);
        doc.getDocumentElement().normalize();
        Transformer transformer = TransformerFactory.newInstance().newTransformer();
        StreamResult result = new StreamResult(new StringWriter());
        DOMSource source = new DOMSource(doc);
        transformer.transform(source, result);
        return result.getWriter().toString();
      }
}
