package org.metanorma;

import org.metanorma.utils.Task;
import org.metanorma.utils.Util;
import static org.metanorma.Constants.*;

import java.io.File;
import java.io.IOException;
import java.io.StringReader;
import java.io.StringWriter;
import java.nio.file.Paths;
import java.util.logging.Level;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.sax.SAXSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.xml.sax.EntityResolver;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;
import org.xml.sax.XMLReader;
import org.xml.sax.helpers.XMLReaderFactory;

/**
 *
 * @author Alexander Dyuzhev
 */

/**
 * This class for the conversion of a DOCX file to Metanorma AsciiDoc
 */
public class DOCX2MN_XsltConverter extends XsltConverter {

    private String imagesDir = "images"; // default image dir - 'images'
    
    public DOCX2MN_XsltConverter() {
        
    }

    public void setImagesDir(String imagesDir) {
        if (imagesDir != null) {
            this.imagesDir = imagesDir;
        }
    }

    
    private void setDefaultOutputFilePath() {
        if (outputFilePath.isEmpty()) {
            String outputFilePathWithoutExtension = super.getDefaultOutputFilePath();
            outputFilePath = outputFilePathWithoutExtension + outputFormat;
        }
    }

    @Override
    public boolean process() {
        
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

            if (!outputFormat.equals("adoc") && !outputFormat.equals("xml")) {
                logger.severe(String.format(UNKNOWN_OUTPUT_FORMAT, outputFormat));
                return false;
            }

            setDefaultOutputFilePath();

            logger.info(String.format(INPUT_LOG, XML_INPUT, inputFilePath));
            if (fileXSL != null) {
                logger.info(String.format(INPUT_LOG, XSL_INPUT, fileXSL));
            }
            logger.info(String.format(OUTPUT_LOG_STS2MN, outputFormat.toUpperCase(), outputFilePath));
            logger.info("");
            
            convertsts2mn();

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
    
    private void convertsts2mn() throws IOException, TransformerException, SAXException, SAXParseException {
            
        //Source srcXSL = null;

        File fDOCXin = new File(inputFilePath);
        File fileOut = new File(outputFilePath);
        
        String inputFolder = fDOCXin.getAbsoluteFile().getParent();
        String outputFolder = fileOut.getAbsoluteFile().getParent();

        String bibdataFileName = fileOut.getName();
        String bibdataFileExt = Util.getFileExtension(bibdataFileName);
        bibdataFileName = bibdataFileName.substring(0, bibdataFileName.indexOf(bibdataFileExt) - 1);

        // skip validating 
        //found here: https://moleshole.wordpress.com/2009/10/08/ignore-a-dtd-when-using-a-transformer/
        XMLReader rdr = XMLReaderFactory.createXMLReader();
        rdr.setEntityResolver(new EntityResolver() {
            @Override
            public InputSource resolveEntity(String publicId, String systemId) throws SAXException, IOException {
                if (systemId.endsWith(".dtd")) {
                        StringReader stringInput = new StringReader(" ");
                        return new InputSource(stringInput);
                }
                else {
                        return null; // use default behavior
                }
            }
        });


        TransformerFactory factory = TransformerFactory.newInstance();
        Transformer transformer = factory.newTransformer();
        
        logger.info("Transforming...");


        String strDocumentXML = Util.unzipFileToString(Paths.get(inputFilePath), "document.xml");
        
        String strRelsXML = Util.unzipFileToString(Paths.get(inputFilePath), "document.xml.rels");
        
        String strCommentsXML = Util.unzipFileToString(Paths.get(inputFilePath), "comments.xml");
        
        String strFootnotesXML = Util.unzipFileToString(Paths.get(inputFilePath), "footnotes.xml");
        
        String strStylesXML = Util.unzipFileToString(Paths.get(inputFilePath), "styles.xml");
        
        Source src = new SAXSource(rdr, new InputSource(new StringReader(strDocumentXML)));

        Source srcXSL;
        if (fileXSL != null) { //external xsl
            srcXSL = new StreamSource(fileXSL);
        } else { // internal xsl
            srcXSL = new StreamSource(Util.getStreamFromResources(getClass().getClassLoader(), "docx2mn.adoc.xsl"));
            // for xsl:include processing (load xsl from jar)
            factory.setURIResolver(new XSLT_ResourceResolver());
        }

        transformer = factory.newTransformer(srcXSL);
        transformer.setParameter("docfile_name", bibdataFileName);
        transformer.setParameter("docfile_ext", bibdataFileExt);
        transformer.setParameter("pathSeparator", File.separator);
        transformer.setParameter("outpath", outputFolder);
        transformer.setParameter("imagesdir", imagesDir);
        transformer.setParameter("debug", isDebugMode);

        NodeList xmlRelsDocumentNodeList = getNodeList(strRelsXML);
        if (xmlRelsDocumentNodeList != null) {
            transformer.setParameter("rels", xmlRelsDocumentNodeList);
        }
        
        NodeList xmlCommentsDocumentNodeList = getNodeList(strCommentsXML);
        if (xmlCommentsDocumentNodeList != null) {
            transformer.setParameter("comments", xmlCommentsDocumentNodeList);
        }
        
        NodeList xmlFootnotesDocumentNodeList = getNodeList(strFootnotesXML);
        if (xmlFootnotesDocumentNodeList != null) {
            transformer.setParameter("footnotes", xmlFootnotesDocumentNodeList);
        }
        
        NodeList xmlStylesDocumentNodeList = getNodeList(strStylesXML);
        if (xmlStylesDocumentNodeList != null) {
            transformer.setParameter("styles", xmlStylesDocumentNodeList);
        }
        
        StringWriter resultWriter = new StringWriter();
        StreamResult sr = new StreamResult(resultWriter);

        transformer.transform(src, sr);
        

        Task.copyImagesFromZIP(Paths.get(inputFilePath), imagesDir, outputFolder);
        
    }
    
    private NodeList getNodeList(String strXML) {
        if (!strXML.isEmpty()) {
            try {
                InputSource xmlIS = new InputSource(new StringReader(strXML));
                DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
                dbFactory.setNamespaceAware(true);
                DocumentBuilder dBuilder;
                dBuilder = dbFactory.newDocumentBuilder();
                Document xmlDocument = dBuilder.parse(xmlIS);
                NodeList xmlDocumentNodeList = xmlDocument.getDocumentElement().getChildNodes();
                return xmlDocumentNodeList;
            } catch (IOException | SAXException | ParserConfigurationException ex) {
                logger.log(Level.SEVERE, "Can''t read xml string: {0}", ex.toString());
            }
        }
        return null;
    }
    
}
