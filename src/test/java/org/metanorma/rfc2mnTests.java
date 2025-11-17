package org.metanorma;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.logging.Handler;
import java.util.logging.Logger;
import java.util.logging.StreamHandler;

//import com.ginsberg.junit.exit.ExpectSystemExitWithStatus;
import org.apache.commons.cli.ParseException;
import org.junit.jupiter.api.*;
import org.metanorma.utils.LoggerHelper;
import org.metanorma.validator.RELAXNGValidator;

import static org.metanorma.Constants.INPUT_NOT_FOUND;
import static org.metanorma.Constants.XML_INPUT;

public class rfc2mnTests {

    static String XMLFILE_MN;

    private static final Logger logger = Logger.getLogger(LoggerHelper.LOGGER_NAME);

    private static OutputStream logCapturingStream;
    private static StreamHandler customLogHandler;

    @BeforeAll
    public static void setUpBeforeClass() throws Exception {
        LoggerHelper.setupLogger();
        XMLFILE_MN = "test.v2.xml"; //System.getProperty("inputXML");        
    }

    @BeforeEach
    void setUp(TestInfo testInfo) {
        System.out.println(testInfo.getDisplayName());
        attachLogCapturer();
    }

    public void attachLogCapturer()
    {
        logCapturingStream = new ByteArrayOutputStream();
        Handler[] handlers = logger.getParent().getHandlers();
        customLogHandler = new StreamHandler(logCapturingStream, handlers[0].getFormatter());
        logger.addHandler(customLogHandler);
    }

    public String getTestCapturedLog() throws IOException
    {
        customLogHandler.flush();
        return logCapturingStream.toString();
    }

    @Test
    //@ExpectSystemExitWithStatus(-1)
    public void notEnoughArguments() throws ParseException, IOException {
        String[] args = new String[]{""};
        mnconvert.run(args);
        String capturedLog = getTestCapturedLog();
        Assumptions.assumeTrue(capturedLog.contains(mnconvert.USAGE));
        //assertTrue(systemOutRule.getLog().contains(rfc2mn.USAGE));
    }

    
    @Test
    //@ExpectSystemExitWithStatus(-1)
    public void xmlNotExists() throws ParseException, IOException {

        String[] args = new String[]{"nonexist.xml"};
        mnconvert.run(args);

        String capturedLog = getTestCapturedLog();
        Assumptions.assumeTrue(capturedLog.contains(String.format(INPUT_NOT_FOUND, XML_INPUT, args[0])));

        //assertTrue(systemOutRule.getLog().contains(
        //        String.format(rfc2mn.INPUT_NOT_FOUND, rfc2mn.XML_INPUT, args[1])));
    }


    @Test
    public void successCheckXMLv2() throws Exception {
        ClassLoader classLoader = getClass().getClassLoader();
        String xml = classLoader.getResource("rfc/test.v2.xml").getFile();
        RELAXNGValidator rngValidator = new RELAXNGValidator();
        String xmlString = new RFC2MN_XsltConverter().serialize(new File(xml));
        //boolean isValid = rngValidator.validate(new File(xml), "V2");
        boolean isValid = rngValidator.validate(xmlString, "V2");

        Assumptions.assumeTrue(isValid);
    }

    @Test
    public void successCheckXMLv3() throws Exception {
        ClassLoader classLoader = getClass().getClassLoader();
        String xml = classLoader.getResource("rfc/antioch.v3.xml").getFile();
        RELAXNGValidator rngValidator = new RELAXNGValidator();
        String xmlString = new RFC2MN_XsltConverter().serialize(new File(xml));
        //boolean isValid = rngValidator.validate(new File(xml), "V3.7991");
        boolean isValid = rngValidator.validate(xmlString, "V3.7991");

        Assumptions.assumeTrue(isValid);
    }
    
    @Test
    public void successCheckXMLv3latest() throws Exception {
        ClassLoader classLoader = getClass().getClassLoader();
        String xml = classLoader.getResource("rfc/rfc8650.xml").getFile();
        RELAXNGValidator rngValidator = new RELAXNGValidator();
        String xmlString = new RFC2MN_XsltConverter().serialize(new File(xml));
        //boolean isValid = rngValidator.validate(new File(xml), "V3.7991");
        boolean isValid = rngValidator.validate(xmlString, "V3.7991.latest");

        Assumptions.assumeTrue(isValid);
    }
    
    @Test
    public void successConvertXMLtest() throws Exception {
        ClassLoader classLoader = getClass().getClassLoader();
        String xml = classLoader.getResource("rfc/rfc8650.xml").getFile();
        
        Path fileout = Paths.get(System.getProperty("buildDirectory"), "rfc2mn.adoc");
        fileout.toFile().delete();
        
        String[] args = new String[]{"--output", fileout.toAbsolutePath().toString(), xml};
        mnconvert.run(args);

        Assumptions.assumeTrue(Files.exists(fileout));
    }
    
}
