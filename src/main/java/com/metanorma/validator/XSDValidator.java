package com.metanorma.validator;

import com.metanorma.utils.ResourceResolver;
import com.metanorma.utils.Util;
import com.metanorma.utils.LoggerHelper;
import java.io.File;
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
    
    public XSDValidator(File xml) {
        super(xml);
    }

    public List<String> validate(CheckAgainstEnum checkAgainst) {
        this.checkAgainst = checkAgainst;
        
        String checkSrc = CheckAgainstMap.getMap().get(checkAgainst);
                
        //System.out.println("Validate XML againts XSD " + checkSrc + "...");
        logger.log(Level.INFO, "Validate XML againts XSD {0}...", checkSrc);
        
        SchemaFactory schemaFactory = SchemaFactory.newInstance(XMLConstants.W3C_XML_SCHEMA_NS_URI);
        // associate the schema factory with the resource resolver, which is responsible for resolving the imported XSD's
        String rootResource = new File(checkSrc).getParentFile().toString() + "/";
        schemaFactory.setResourceResolver(new ResourceResolver(rootResource));
        //schemaFactory.setResourceResolver(new ResourceResolver(""));
              
        try {
            Source schemaFile = new StreamSource(Util.getStreamFromResources(getClass().getClassLoader(), checkSrc.replaceAll("\\\\", "/")));
            Schema schema = schemaFactory.newSchema(schemaFile);
            javax.xml.validation.Validator validator = schema.newValidator();
            validator.setErrorHandler(errorHandler);
            validator.validate(new StreamSource(xml));            
        } catch (Exception e) { 
            exceptions.add(e.toString());            
        }        
        return exceptions;
    }
    
}
