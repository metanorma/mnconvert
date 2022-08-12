package org.metanorma;

import static org.metanorma.Constants.*;
import org.metanorma.utils.LoggerHelper;
import org.metanorma.validator.CheckAgainstEnum;
import org.metanorma.validator.CheckAgainstMap;
import org.metanorma.validator.DTDValidator;
import org.metanorma.validator.XSDValidator;

import java.io.File;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 *
 * @author Alexander Dyuzhev
 */

/**
 * This class for validation of input STS NISO/ISO XML file
 */
public class STSValidator {

    private static final Logger logger = Logger.getLogger(LoggerHelper.LOGGER_NAME);
    
    private String xmlFilePath = "document.xml"; // default input file name
    
    private String checkType = "xsd_niso";
    private CheckAgainstEnum checkAgainst = CheckAgainstEnum.XSD_NISO_INTERCHANGE_MATHML3; // default
    private String filepathDTDorXSD = "";
    private String tagset = "interchange"; // default
    private String mathmlVersion = "3"; // default
    
    private boolean isDebugMode = false; // default no debug
    
    private static boolean isIdRefChecking = false;
    
    public STSValidator(String xmlFilePath, String checkType) {
        this.xmlFilePath = xmlFilePath;
        if (checkType != null) {
            this.checkType = checkType;
        }
    }

    public STSValidator(String xmlFilePath) {
        this.xmlFilePath = xmlFilePath;
    }
    
    public void setFilepathDTDorXSD(String DTDXSDPath) {
        this.filepathDTDorXSD = DTDXSDPath;
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

    public void setIdRefChecking(boolean isIdRefChecking) {
        this.isIdRefChecking = isIdRefChecking;
    }
        
    public void setDebugMode(boolean isDebugMode) {
        this.isDebugMode = isDebugMode;
    }
    
    private String getCtype(){
        String ctype = checkType.replace("-", "_");
        if (!checkType.equals("dtd-iso")) {
            ctype = ctype + "_" + tagset + "_" + getMathmlVersion();
        }
        return ctype.toUpperCase();
    }
    
    public boolean check() {
        try {
            
            File fXMLin = new File(xmlFilePath);
            if (!fXMLin.exists()) {
                logger.severe(String.format(INPUT_NOT_FOUND, XML_INPUT, fXMLin));
                return false;
            }
            
            List<String> exceptions; 
            
            if (!filepathDTDorXSD.isEmpty()) {
                boolean isXSDcheck = filepathDTDorXSD.toLowerCase().endsWith(".xsd");
                if (isXSDcheck) {
                    XSDValidator xsdValidator = new XSDValidator(fXMLin);
                    xsdValidator.setIdRefChecking(isIdRefChecking);
                    exceptions = xsdValidator.validate(filepathDTDorXSD);                
                } else {                
                    DTDValidator dtdValidator = new DTDValidator(fXMLin);
                    dtdValidator.setDebug(isDebugMode);
                    exceptions = dtdValidator.validate(filepathDTDorXSD);                
                }
            } else {
            
                String ctype = getCtype();
                if (CheckAgainstEnum.valueOf(ctype) != null) {
                    checkAgainst = CheckAgainstEnum.valueOf(ctype);
                } else {
                    logger.log(Level.SEVERE, "Unknown option value:  {0}", checkType);
                    return false;
                }

                String checkSrc = CheckAgainstMap.getMap().get(checkAgainst);

                boolean isXSDcheck = checkSrc.toLowerCase().endsWith(".xsd");

                if (isXSDcheck) {
                    XSDValidator xsdValidator = new XSDValidator(fXMLin);
                    xsdValidator.setIdRefChecking(isIdRefChecking);
                    exceptions = xsdValidator.validate(checkAgainst);
                } else {                
                    DTDValidator dtdValidator = new DTDValidator(fXMLin);
                    dtdValidator.setDebug(isDebugMode);
                    exceptions = dtdValidator.validate(checkAgainst);
                }
            }
            
            StringBuilder sbErrors = new StringBuilder();
            if (exceptions.isEmpty()) {
                logger.log(Level.INFO, "{0} is valid.", fXMLin.getAbsolutePath());
            } else {
                sbErrors.append(fXMLin.getAbsolutePath());
                sbErrors.append(" is NOT valid reason:");
                sbErrors.append("\n");
                exceptions.forEach((exception) -> {
                    sbErrors.append("[ERROR] ");
                    sbErrors.append(exception);
                    sbErrors.append("\n");
                });
                logger.severe(sbErrors.toString());
                return false;
            } 
        } catch (Exception e) {
            logger.severe(e.toString());
            return false;
        }
        return true;
    }

}
