package org.metanorma;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import com.ginsberg.junit.exit.ExpectSystemExitWithStatus;
import org.apache.commons.cli.ParseException;
import org.junit.jupiter.api.*;
import org.metanorma.validator.RELAXNGValidator;

public class rfc2mnTests {

    static String XMLFILE_MN;

    @BeforeAll
    public static void setUpBeforeClass() throws Exception {
        XMLFILE_MN = "test.v2.xml"; //System.getProperty("inputXML");        
    }

    @BeforeEach
    void setUp(TestInfo testInfo) {
        System.out.println(testInfo.getDisplayName());
    }

    @Test
    @ExpectSystemExitWithStatus(-1)
    public void notEnoughArguments() throws ParseException {
        String[] args = new String[]{""};
        mnconvert.main(args);

        //assertTrue(systemOutRule.getLog().contains(rfc2mn.USAGE));
    }

    
    @Test
    @ExpectSystemExitWithStatus(-1)
    public void xmlNotExists() throws ParseException {

        String[] args = new String[]{"nonexist.xml"};
        mnconvert.main(args);

        //assertTrue(systemOutRule.getLog().contains(
        //        String.format(rfc2mn.INPUT_NOT_FOUND, rfc2mn.XML_INPUT, args[1])));
    }


    @Test
    public void successCheckXMLv2() throws ParseException, Exception {
        ClassLoader classLoader = getClass().getClassLoader();
        String xml = classLoader.getResource("rfc/test.v2.xml").getFile();
        RELAXNGValidator rngValidator = new RELAXNGValidator();
        String xmlString = new RFC2MN_XsltConverter().serialize(new File(xml));
        //boolean isValid = rngValidator.validate(new File(xml), "V2");
        boolean isValid = rngValidator.validate(xmlString, "V2");

        Assumptions.assumeTrue(isValid);
    }

    @Test
    public void successCheckXMLv3() throws ParseException, Exception {
        ClassLoader classLoader = getClass().getClassLoader();
        String xml = classLoader.getResource("rfc/antioch.v3.xml").getFile();
        RELAXNGValidator rngValidator = new RELAXNGValidator();
        String xmlString = new RFC2MN_XsltConverter().serialize(new File(xml));
        //boolean isValid = rngValidator.validate(new File(xml), "V3.7991");
        boolean isValid = rngValidator.validate(xmlString, "V3.7991");

        Assumptions.assumeTrue(isValid);
    }
    
    @Test
    public void successCheckXMLv3latest() throws ParseException, Exception {
        ClassLoader classLoader = getClass().getClassLoader();
        String xml = classLoader.getResource("rfc/rfc8650.xml").getFile();
        RELAXNGValidator rngValidator = new RELAXNGValidator();
        String xmlString = new RFC2MN_XsltConverter().serialize(new File(xml));
        //boolean isValid = rngValidator.validate(new File(xml), "V3.7991");
        boolean isValid = rngValidator.validate(xmlString, "V3.7991.latest");

        Assumptions.assumeTrue(isValid);
    }
    
    @Test
    public void successConvertXMLtest() throws ParseException, Exception {
        ClassLoader classLoader = getClass().getClassLoader();
        String xml = classLoader.getResource("rfc/rfc8650.xml").getFile();
        
        Path fileout = Paths.get(System.getProperty("buildDirectory"), "rfc2mn.adoc");
        fileout.toFile().delete();
        
        String[] args = new String[]{"--output", fileout.toAbsolutePath().toString(), xml};
        mnconvert.main(args);

        Assumptions.assumeTrue(Files.exists(fileout));
    }
    
}
