package org.metanorma;

import static org.metanorma.Constants.*;
import org.metanorma.utils.Util;
import org.metanorma.validator.CheckAgainstEnum;

import java.io.BufferedWriter;
import java.io.File;
import java.io.IOException;
import java.io.StringWriter;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.security.CodeSource;
import java.text.MessageFormat;
import java.util.logging.Level;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.SAXParserFactory;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import javax.xml.xpath.XPathFactory;
import org.xml.sax.SAXParseException;

/**
 *
 * @author Alexander Dyuzhev
 */

/**
 * This class for the conversion of an Metanorma XML to NISO/ISO XML file
 */
public class MN2STS_XsltConverter extends XsltConverter {

    
    private String checkType = "xsd_niso";
    private CheckAgainstEnum checkTypeEnumValue = CheckAgainstEnum.XSD_NISO_INTERCHANGE_MATHML3; 
    private String tagset = "interchange"; // default
    private String mathmlVersion = "3"; // default
    
    private OutputFormatEnum outputFormatEnumValue = OutputFormatEnum.NISO;

    
    public MN2STS_XsltConverter() {
        this.outputFormat = "NISO"; // redefine default output format to 'NISO'
    }

    public void setCheckType(String checkType) {
        if (checkType != null) {
            this.checkType = checkType;
        }
    }

    public void setTagset(String tagset) {
        if (tagset != null) {
            this.tagset = tagset;
        }
    }
    
    public String getMathmlVersion() {
        return "mathml" + mathmlVersion;
    }
    
    public void setMathmlVersion(String mathmlVersion) {
        if (mathmlVersion != null) {
            this.mathmlVersion = mathmlVersion;
        }
    }
    
    private void setDefaultOutputFilePath() {
        if (outputFilePath.isEmpty()) {
            
            String outputFilePathWithoutExtension = super.getDefaultOutputFilePath();
            
            outputFilePath = outputFilePathWithoutExtension + "sts." + outputFormat + ".xml";
        }
    }
    
    private String getCtype(){
        String ctype = checkType.replace("-", "_");
        if (!checkType.equals("dtd-iso")) {
            ctype = ctype + "_" + tagset + "_" + getMathmlVersion();
        }
        return ctype.toUpperCase();
    }
    
    @Override
    public boolean process() {
        try {
            
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
            
            
            String ctype = getCtype();
            
            if (CheckAgainstEnum.valueOf(ctype) != null) {
                checkTypeEnumValue = CheckAgainstEnum.valueOf(ctype);
            } else {
                logger.log(Level.SEVERE, "Unknown option value:  {0}", checkType);
                return false;
            }
            
            setDefaultOutputFilePath();
            
            try {
                outputFormatEnumValue = OutputFormatEnum.valueOf(outputFormat.toUpperCase());
            } catch (Exception ex) {
                logger.log(Level.SEVERE, "Unknown option value:  {0}", outputFormat);
                return false;
            }
            
            logger.info(String.format(INPUT_LOG, XML_INPUT, inputFilePath));
            if (fileXSL != null) {
                logger.info(String.format(INPUT_LOG, XSL_INPUT, fileXSL));
            }
            logger.info(String.format(OUTPUT_LOG_MN2STS, XML_OUTPUT, outputFilePath, outputFormat.toUpperCase()));
            logger.info("");
            
            convertmn2sts();
            
            // check agains XSD NISO, DTD NISO or DTD ISO
            STSValidator validator = new STSValidator(outputFilePath, checkType);
            validator.setTagset(tagset);
            validator.setMathmlVersion(mathmlVersion);
            validator.setIdRefChecking(isIdRefChecking);
            if (!validator.check()) {
                return false;
            }
            
            logger.info("End!");
        
        
        } catch (Exception e) {
            //e.printStackTrace(System.err);
            logger.severe(e.toString());
            return false;
        }
        return true;
    }

    /**
     * Converts an MN XML file to NISO STS XML file
     *
     * @param xmlin the XML source file
     * @param xsl the external XSL file
     * @param xmlout the XML output file
     * @throws IOException In case of an I/O problem
     * @throws javax.xml.transform.TransformerException
     */
    private void convertmn2sts() throws IOException, TransformerException, SAXParseException, Exception {
       
        OutputJaxpImplementationInfo();

        Source srcXSL;
        if (fileXSL != null) { //external xsl
            srcXSL = new StreamSource(fileXSL);
        } else { // internal xsl
            srcXSL = new StreamSource(Util.getStreamFromResources(getClass().getClassLoader(), "mn2sts.xsl"));
        }

        TransformerFactory factory = TransformerFactory.newInstance();
        Transformer transformer = factory.newTransformer(srcXSL);
        transformer.setParameter("debug", isDebugMode);
        transformer.setParameter("outputformat", outputFormat.toUpperCase());

        File fXmlIn = new File(inputFilePath);
        Source src = new StreamSource(fXmlIn);
        StringWriter resultWriter = new StringWriter();
        StreamResult sr = new StreamResult(resultWriter);
        logger.info("Transforming...");
        transformer.transform(src, sr);
        String xmlSTS = resultWriter.toString();

        File fXmlOut = new File(outputFilePath);
        try (BufferedWriter writer = Files.newBufferedWriter(Paths.get(fXmlOut.getAbsolutePath()))) {
            writer.write(xmlSTS);
        }
    }
    
    private void OutputJaxpImplementationInfo() {
        if (isDebugMode) {
            logger.info(getJaxpImplementationInfo("DocumentBuilderFactory", DocumentBuilderFactory.newInstance().getClass()));
            logger.info(getJaxpImplementationInfo("XPathFactory", XPathFactory.newInstance().getClass()));
            logger.info(getJaxpImplementationInfo("TransformerFactory", TransformerFactory.newInstance().getClass()));
            logger.info(getJaxpImplementationInfo("SAXParserFactory", SAXParserFactory.newInstance().getClass()));
        }
    }
    
    private String getJaxpImplementationInfo(String componentName, Class componentClass) {
        CodeSource source = componentClass.getProtectionDomain().getCodeSource();
        return MessageFormat.format(
                "{0} implementation: {1} loaded from: {2}",
                componentName,
                componentClass.getName(),
                source == null ? "Java Runtime" : source.getLocation());
    }    
}
