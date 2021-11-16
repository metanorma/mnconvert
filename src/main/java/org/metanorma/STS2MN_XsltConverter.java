package org.metanorma;

import org.metanorma.utils.Task;
import org.metanorma.utils.Util;
import static org.metanorma.Constants.*;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.StringReader;
import java.io.StringWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.URIResolver;
import javax.xml.transform.sax.SAXSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
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
 * This class for the conversion of an NISO/ISO XML file to Metanorma XML or AsciiDoc
 */
public class STS2MN_XsltConverter extends XsltConverter {

    private String imagesDir = "images"; // default image dir - 'images'
    
    private boolean isSplitBibdata = false;
    
    private String typeStandard = ""; // default value empty - allows to determine standard via xslt
    
    private boolean isSemanticXML = false;
    
    final String SPLIT = "///SPLIT ";
    
    public STS2MN_XsltConverter() {
        
    }

    public void setImagesDir(String imagesDir) {
        if (imagesDir != null) {
            this.imagesDir = imagesDir;
        }
    }

    public void setIsSplitBibdata(boolean isSplitBibdata) {
        this.isSplitBibdata = isSplitBibdata;
    }

    
    public void setTypeStandard(String typeStandard) {
        if (typeStandard != null) {
            this.typeStandard = typeStandard;
        }
    }

    public void setIsSemanticXML(boolean isSemanticXML) {
        this.isSemanticXML = isSemanticXML;
    }
    
    
    private void setDefaultOutputFilePath() {
        if (outputFilePath.isEmpty()) {
            
            String outputFilePathWithoutExtension = super.getDefaultOutputFilePath();
            
            if (outputFormat.equals("xml")) {
                outputFilePath = outputFilePathWithoutExtension + "mn." + outputFormat;                    
            } else { // adoc
                outputFilePath = outputFilePathWithoutExtension + outputFormat;
            }
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
                //System.out.println(String.format(INPUT_NOT_FOUND, XML_INPUT, fXMLin));
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
                //System.out.println(String.format(UNKNOWN_OUTPUT_FORMAT, outputFormat));
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

        File fXMLin = new File(inputFilePath);
        File fileOut = new File(outputFilePath);
        
        String inputFolder = fXMLin.getAbsoluteFile().getParent();
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
        //Source src = new StreamSource(fXMLin);
        Source src = new SAXSource(rdr, new InputSource(new FileInputStream(fXMLin)));

        logger.info("Transforming...");

        if (outputFormat.equals("xml") ||  isSplitBibdata) {
            Source srcXSL;
            if (fileXSL != null) { //external xsl
                srcXSL = new StreamSource(fileXSL);
            } else { // internal xsl
                srcXSL = new StreamSource(Util.getStreamFromResources(getClass().getClassLoader(), "sts2mn.xsl"));
                // for xsl:include processing (load xsl from jar)
                factory.setURIResolver(new XSLT_ResourceResolver());
            }
            
            transformer = factory.newTransformer(srcXSL);
            transformer.setParameter("split-bibdata", isSplitBibdata);
            transformer.setParameter("imagesdir", imagesDir);
            transformer.setParameter("outpath", outputFolder);
            transformer.setParameter("typestandard", typeStandard);
            transformer.setParameter("semantic", isSemanticXML);
            transformer.setParameter("debug", isDebugMode);

            StringWriter resultWriter = new StringWriter();
            StreamResult sr = new StreamResult(resultWriter);

            transformer.transform(src, sr);

            String xmlMetanorma = resultWriter.toString();

            File xmlFileOut = fileOut;
            if (isSplitBibdata) { //relaton XML
                String relatonXML = xmlFileOut.getAbsolutePath();
                relatonXML = relatonXML.substring(0, relatonXML.lastIndexOf(".")) + ".rxl";
                xmlFileOut = new File(relatonXML);
            }

            Files.createDirectories(Paths.get(xmlFileOut.getParent()));
            try (BufferedWriter writer = Files.newBufferedWriter(Paths.get(xmlFileOut.getAbsolutePath()))) {
                writer.write(xmlMetanorma);
            }

        }

        if (outputFormat.equals("adoc") || isSplitBibdata) {
            src = new SAXSource(rdr, new InputSource(new FileInputStream(fXMLin)));

            // linearize XML
            //String xmlLinearized = linearizeXML(src);

            //src = new StreamSource(new StringReader(xmlLinearized));
            
            Source srcXSL;
            if (fileXSL != null) { //external xsl
                srcXSL = new StreamSource(fileXSL);
            } else { // internal xsl
                srcXSL = new StreamSource(Util.getStreamFromResources(getClass().getClassLoader(), "sts2mn.adoc.xsl"));
                // for xsl:include processing (load xsl from jar)
                factory.setURIResolver(new XSLT_ResourceResolver());
            }

            transformer = factory.newTransformer(srcXSL);
            transformer.setParameter("split-bibdata", isSplitBibdata);
            transformer.setParameter("docfile_name", bibdataFileName);
            transformer.setParameter("docfile_ext", bibdataFileExt);
            transformer.setParameter("pathSeparator", File.separator);
            transformer.setParameter("outpath", outputFolder);
            transformer.setParameter("imagesdir", imagesDir);
            transformer.setParameter("debug", isDebugMode);

            StringWriter resultWriter = new StringWriter();
            StreamResult sr = new StreamResult(resultWriter);

            transformer.transform(src, sr);
            String adocMetanorma = resultWriter.toString();

            File adocFileOut = fileOut;
            if (isSplitBibdata) { //relaton XML
                String bibdataAdoc = adocFileOut.getAbsolutePath();
                bibdataAdoc = bibdataAdoc.substring(0, bibdataAdoc.lastIndexOf(".")) + ".adoc";
                adocFileOut = new File(bibdataAdoc);
            }

            // no need to save resulted adoc here, because it saved via xslt xsl:redirect
            /*
            try (Scanner scanner = new Scanner(adocMetanorma)) {
                String outputFile = adocFileOut.getAbsolutePath();
                StringBuilder sbBuffer = new StringBuilder();
                while (scanner.hasNextLine()) {
                    String line = scanner.nextLine();
                    if (line.startsWith(SPLIT)) {
                        writeBuffer(sbBuffer, outputFile);
                        // ///SPLIT body/body-en.doc[] --> body/body-en.doc
                        outputFile = line.substring(line.indexOf(SPLIT) + SPLIT.length(), line.length() - 2);                        
                        outputFile = Paths.get(outputFolder, outputFile).toString();
                        new File(new File(outputFile).getParent()).mkdirs();
                    }
                    else {
                        sbBuffer.append(line);
                        sbBuffer.append(System.getProperty("line.separator"));
                    }                    
                }
                writeBuffer(sbBuffer, outputFile);
            }*/
        }

        Task.copyImages(inputFolder, imagesDir, outputFolder);
    }
    
    /*private String linearizeXML(Source src) throws TransformerConfigurationException, IOException, TransformerException {
        TransformerFactory factory = TransformerFactory.newInstance();
        Source srcXSLlinearize = new StreamSource(Util.getStreamFromResources(getClass().getClassLoader(), "linearize.xsl"));
        Transformer transformer = factory.newTransformer(srcXSLlinearize);

        StringWriter resultWriteridentity = new StringWriter();
        StreamResult sridentity = new StreamResult(resultWriteridentity);
        transformer.transform(src, sridentity);
        return resultWriteridentity.toString();
    }*/
    
}
