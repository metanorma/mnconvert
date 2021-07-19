package org.metanorma.validator;

import java.io.StringReader;
import javax.xml.XMLConstants;
import javax.xml.transform.Source;
import javax.xml.transform.sax.SAXSource;
import javax.xml.transform.stream.StreamSource;
import javax.xml.validation.Schema;
import javax.xml.validation.SchemaFactory;
import javax.xml.validation.Validator;
import org.metanorma.utils.ResourceResolver;
import org.metanorma.utils.Util;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.XMLReader;
import org.xml.sax.helpers.XMLReaderFactory;

/**
 *
 * @author Alexander Dyuzhev
 */
public class RELAXNGValidator {
    
    String sMessage = "";
    
    
    
    public RELAXNGValidator() {
        
    }
    
    public boolean isValid(String xmlString) {

        boolean isValid = validate(xmlString, "V2") ||
                validate(xmlString, "V3.7991") || 
                validate(xmlString, "V3.7991.draft") ||
                validate(xmlString, "V3.7991.latest");
        
        return isValid;
    }
    
    public String getValidationInfo() {
        return sMessage;
    }
    
    public boolean validate(String xmlString, String version) {
        try {
            
            
            String rngFilename = "";
            if (version.toLowerCase().equals("v2")) {
                rngFilename = "xml2rfcv2.rnc";
            } else if (version.toLowerCase().equals("v3.7991")) {
                rngFilename = "xml2rfcv3.rfc7991.rnc";
            } else if (version.toLowerCase().equals("v3.7991.draft")) {
                rngFilename = "xml2rfcv3.rfc7991bis-03.rnc";
            } else  {
                rngFilename = "xml2rfcv3.rng";
            }
            
            
            
            // https://stackoverflow.com/questions/1541253/how-to-validate-an-xml-document-using-a-relax-ng-schema-and-jaxp
            if (rngFilename.toLowerCase().endsWith(".rnc")) { // Relax NG compact
                System.setProperty(SchemaFactory.class.getName() + ":" + XMLConstants.RELAXNG_NS_URI, "com.thaiopensource.relaxng.jaxp.CompactSyntaxSchemaFactory");
            } else { // .rng Relax NG
                System.setProperty(SchemaFactory.class.getName() + ":" + XMLConstants.RELAXNG_NS_URI, "com.thaiopensource.relaxng.jaxp.XMLSyntaxSchemaFactory");
            }
            
            SchemaFactory factory = SchemaFactory.newInstance(XMLConstants.RELAXNG_NS_URI);
            if (rngFilename.toLowerCase().endsWith(".rng")) {
                // associate the schema factory with the resource resolver, which is responsible for resolving the imported RNG's
                factory.setResourceResolver(new ResourceResolver("RFC/")); // path in resources
            }
            
            
            
            Source srcRNG = new StreamSource(Util.getStreamFromResources(getClass().getClassLoader(), "RFC/" + rngFilename));
            Schema schema = factory.newSchema(srcRNG);
            Validator validator = schema.newValidator();
            
            
            XMLReader rdr = XMLReaderFactory.createXMLReader();
            //rdr.setEntityResolver(new EntityResolver() {
            
            Source src = new SAXSource(rdr, new InputSource(new StringReader(xmlString))); //new FileInputStream(xmlFile)
            
            try
            {
                validator.validate(src);
                return true;
            }
            catch (SAXException ex)
            {
                sMessage = "XML is not valid because: " + ex.toString();
            }
        } catch (Exception ex) {
            sMessage = ex.toString();
        }
        
        return false;
    }
}
