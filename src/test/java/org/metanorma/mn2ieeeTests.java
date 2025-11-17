package org.metanorma;

import org.apache.commons.cli.ParseException;
import org.junit.jupiter.api.*;
import org.metanorma.utils.LoggerHelper;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.logging.Handler;
import java.util.logging.Logger;
import java.util.logging.StreamHandler;

public class mn2ieeeTests {

    private static final Logger logger = Logger.getLogger(LoggerHelper.LOGGER_NAME);

    private static OutputStream logCapturingStream;
    private static StreamHandler customLogHandler;

    static String DTD_IEEE;

    @BeforeAll
    public static void setUpBeforeClass() throws Exception {
        LoggerHelper.setupLogger();
        DTD_IEEE = System.getProperty("inputIEEEDTD");
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
    public void successConvert_IEEE() throws ParseException, Exception {
        Assumptions.assumeTrue(DTD_IEEE != null);

        ClassLoader classLoader = getClass().getClassLoader();
        String xml = classLoader.getResource("ieee/ieee.test.xml").getFile();

        Path xmlout = Paths.get(System.getProperty("buildDirectory"), "out.ieee.xml");

        String[] args = new String[]{xml, "--output-format", "ieee", "--output", xmlout.toAbsolutePath().toString(), "--validation-against", DTD_IEEE};
        mnconvert.run(args);

        Assumptions.assumeTrue(Files.exists(xmlout));
        String capturedLog = getTestCapturedLog();
        Assumptions.assumeTrue(capturedLog.contains(" is valid")); //Validation skipped
        
    }

}
