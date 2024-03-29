package org.metanorma.validator;

import org.metanorma.utils.ResourceResolver;
import org.metanorma.utils.Util;
import org.metanorma.utils.LoggerHelper;
import java.io.File;
import java.io.FileInputStream;
import java.io.StringReader;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.xml.XMLConstants;
import javax.xml.transform.Source;
import javax.xml.transform.stream.StreamSource;
import javax.xml.validation.Schema;
import javax.xml.validation.SchemaFactory;

public class XSDValidator extends Validator {

    private static final Logger logger = Logger.getLogger(LoggerHelper.LOGGER_NAME);
    
    protected boolean isIdRefChecking = false;
    
    public void setIdRefChecking(boolean isIdRefChecking) {
        this.isIdRefChecking = isIdRefChecking;
    }
    
    public XSDValidator(File xml) {
        super(xml);
    }

    public List<String> validate(Object checkAgainst) {
        
        String checkSrc;
        if (checkAgainst instanceof CheckAgainstEnum) {
            this.checkAgainst = (CheckAgainstEnum) checkAgainst;
            checkSrc = CheckAgainstMap.getMap().get(this.checkAgainst);
        } else {
            filepathDTDorXSD = (String) checkAgainst;
            checkSrc = filepathDTDorXSD;
        }
                
        logger.log(Level.INFO, "Validate XML against XSD {0}...", checkSrc);
        
        SchemaFactory schemaFactory = SchemaFactory.newInstance(XMLConstants.W3C_XML_SCHEMA_NS_URI);
        // associate the schema factory with the resource resolver, which is responsible for resolving the imported XSD's
        String rootResource = new File(checkSrc).getParentFile().toString() + "/";
        schemaFactory.setResourceResolver(new ResourceResolver(rootResource));
        //schemaFactory.setResourceResolver(new ResourceResolver(""));
              
        try {
            Source schemaFile;
            if (checkAgainst instanceof CheckAgainstEnum) {
                schemaFile = new StreamSource(Util.getStreamFromResources(getClass().getClassLoader(), checkSrc.replaceAll("\\\\", "/")));
            } else {
                schemaFile = new StreamSource(new File(filepathDTDorXSD));
            }
            
            Schema schema = schemaFactory.newSchema(schemaFile);
            javax.xml.validation.Validator validator = schema.newValidator();
            // Disable checking of ID/IDREF constraints. Validation will not fail if there are non-unique ID values or dangling IDREF values in the document. 
            validator.setFeature("http://apache.org/xml/features/validation/id-idref-checking", isIdRefChecking);
            validator.setErrorHandler(errorHandler);
            
            String xmlString = Util.serializeXML(xml);
            //validator.validate(new StreamSource(xml));   
            validator.validate(new StreamSource(new StringReader(xmlString)));
            
        } catch (Exception e) { 
            exceptions.add(e.toString());            
        }        
        return exceptions;
    }
    
}
