package org.metanorma;

import org.apache.commons.cli.ParseException;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Rule;
import org.junit.Test;
import org.junit.contrib.java.lang.system.EnvironmentVariables;
import org.junit.contrib.java.lang.system.ExpectedSystemExit;
import org.junit.contrib.java.lang.system.SystemOutRule;
import org.junit.rules.TestName;
import org.metanorma.utils.LoggerHelper;
import org.metanorma.utils.RegExHelper;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.logging.Handler;
import java.util.logging.Logger;
import java.util.logging.StreamHandler;

import static org.junit.Assert.assertTrue;
import static org.junit.Assume.assumeNotNull;

public class mn2ieeeTests {

    private static final Logger logger = Logger.getLogger(LoggerHelper.LOGGER_NAME);

    private static OutputStream logCapturingStream;
    private static StreamHandler customLogHandler;

    static String DTD_IEEE;

    @Rule
    public final ExpectedSystemExit exitRule = ExpectedSystemExit.none();

    @Rule
    public final SystemOutRule systemOutRule = new SystemOutRule().enableLog();

    @Rule
    public final EnvironmentVariables envVarRule = new EnvironmentVariables();

    @Rule public TestName name = new TestName();


    @BeforeClass
    public static void setUpBeforeClass() throws Exception {
        LoggerHelper.setupLogger();
        DTD_IEEE = System.getProperty("inputIEEEDTD");
    }
    
    @Before
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
    public void successConvert_IEEE() throws ParseException, Exception {
        System.out.println(name.getMethodName());

        ClassLoader classLoader = getClass().getClassLoader();
        String xml = classLoader.getResource("ieee/ieee.test.xml").getFile();

        Path xmlout = Paths.get(System.getProperty("buildDirectory"), "out.ieee.xml");

        String[] args = new String[]{xml, "--output-format", "ieee", "--output", xmlout.toAbsolutePath().toString(), "--validation-against", DTD_IEEE};
        mnconvert.main(args);

        assertTrue(Files.exists(xmlout));
        String capturedLog = getTestCapturedLog();
        assertTrue(capturedLog.contains("Validation skipped"));
        
    }

}
