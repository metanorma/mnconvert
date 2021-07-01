package org.metanorma.validator;

import java.io.File;
import java.util.EnumMap;


public class CheckAgainstMap {
    
    static final EnumMap<CheckAgainstEnum, String> checkAgainstMap = new EnumMap(CheckAgainstEnum.class) {        
        {
            put(CheckAgainstEnum.XSD_NISO, "NISO-STS-extended-1-MathML3-XSD" + File.separator + "NISO-STS-extended-1-mathml3.xsd");
            put(CheckAgainstEnum.DTD_ISO, "ISO-STS-DTD_v1.1" + File.separator + "ISOSTS.dtd");
            put(CheckAgainstEnum.DTD_NISO, "NISO-STS-extended-1-MathML3-DTD" + File.separator + "NISO-STS-extended-1-mathml3.dtd");
        }
    };
    
    public static EnumMap<CheckAgainstEnum, String> getMap() {
        return checkAgainstMap;
    }
    
}
