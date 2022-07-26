package org.metanorma;

import org.metanorma.utils.LoggerHelper;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import org.apache.commons.cli.ParseException;

import org.junit.BeforeClass;
import org.junit.Rule;
import org.junit.Test;
import static org.junit.Assert.assertTrue;
import static org.junit.Assume.assumeNotNull;

import org.junit.contrib.java.lang.system.EnvironmentVariables;
import org.junit.contrib.java.lang.system.ExpectedSystemExit;
import org.junit.contrib.java.lang.system.SystemOutRule;
import org.junit.rules.TestName;

public class sts2mnTests {

    static String XMLFILE_MN;// = "test.mn.xml";
    //final String XMLFILE_STS = "test.sts.xml";
    
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
        XMLFILE_MN = System.getProperty("inputSTSXML");
    }
    
    @Test
    public void notEnoughArguments() throws ParseException {
        System.out.println(name.getMethodName());
        exitRule.expectSystemExitWithStatus(-1);
        String[] args = new String[]{""};
        mnconvert.main(args);

        //assertTrue(systemOutRule.getLog().contains(mnconvert.USAGE));
    }

    
    @Test
    public void xmlNotExists() throws ParseException {
        System.out.println(name.getMethodName());
        exitRule.expectSystemExitWithStatus(-1);

        String[] args = new String[]{"nonexist.xml"};
        mnconvert.main(args);

        /*assertTrue(systemOutRule.getLog().contains(
                String.format(INPUT_NOT_FOUND, XML_INPUT, args[1])));*/
    }

    @Test
    public void unknownOutputFormat() throws ParseException {
        assumeNotNull(XMLFILE_MN);
        System.out.println(name.getMethodName());
        exitRule.expectSystemExitWithStatus(-1);

        String[] args = new String[]{"--output-format", "abc", XMLFILE_MN};
        mnconvert.main(args);

        /*assertTrue(systemOutRule.getLog().contains(
                String.format(UNKNOWN_OUTPUT_FORMAT, args[1])));*/
    }
    
    

    @Test
    public void successConvertToAdocDefault() throws ParseException {
        assumeNotNull(XMLFILE_MN);
        System.out.println(name.getMethodName());
        String outFileName = new File(XMLFILE_MN).getAbsolutePath();
        outFileName = outFileName.substring(0, outFileName.lastIndexOf('.') + 1);
        Path fileout = Paths.get(outFileName + "adoc");
        fileout.toFile().delete();
        
        String[] args = new String[]{XMLFILE_MN};
        mnconvert.main(args);

        assertTrue(Files.exists(fileout));        
    }
    
    @Test
    public void successConvertToAdoc() throws ParseException {
        assumeNotNull(XMLFILE_MN);
        System.out.println(name.getMethodName());
        String outFileName = new File(XMLFILE_MN).getAbsolutePath();
        outFileName = outFileName.substring(0, outFileName.lastIndexOf('.') + 1);
        Path fileout = Paths.get(outFileName + "adoc");
        fileout.toFile().delete();
        
        String[] args = new String[]{"--output-format", "adoc", XMLFILE_MN};
        mnconvert.main(args);

        assertTrue(Files.exists(fileout));        
    }
    
    @Test
    public void successConvertToAdocOutputSpecified() throws ParseException {
        assumeNotNull(XMLFILE_MN);
        System.out.println(name.getMethodName());
        Path fileout = Paths.get(System.getProperty("buildDirectory"), "custom.adoc");
        fileout.toFile().delete();
        
        String[] args = new String[]{"--output-format", "adoc", "--output", fileout.toAbsolutePath().toString(), XMLFILE_MN};
        mnconvert.main(args);

        assertTrue(Files.exists(fileout));
    }

    @Test
    public void successConvertToRelativeAdocOutputSpecified() throws ParseException {
        assumeNotNull(XMLFILE_MN);
        String user_dir = System.getProperty("user.dir");
        System.setProperty("user.dir", System.getProperty("buildDirectory"));

        String filename = "custom_relative.adoc";
        System.out.println(name.getMethodName());
        //Path fileout = Paths.get(System.getProperty("buildDirectory"), "custom_relative.adoc");
        Path fileout = Paths.get(new File(filename).getAbsolutePath());
        fileout.toFile().delete();

        String[] args = new String[]{"--output-format", "adoc", "--output", filename,
                Paths.get(System.getProperty("buildDirectory"), "..", XMLFILE_MN).normalize().toString()};
        mnconvert.main(args);
        System.setProperty("user.dir", user_dir); // we should restore value for another tests
        assertTrue(Files.exists(fileout));
    }
    
    @Test
    public void successConvertToXML() throws ParseException {
        assumeNotNull(XMLFILE_MN);
        System.out.println(name.getMethodName());
        String outFileName = new File(XMLFILE_MN).getAbsolutePath();
        outFileName = outFileName.substring(0, outFileName.lastIndexOf('.') + 1);
        Path fileout = Paths.get(outFileName + "mn.xml");
        fileout.toFile().delete();
        
        String[] args = new String[]{"--output-format", "xml", XMLFILE_MN};
        mnconvert.main(args);

        assertTrue(Files.exists(fileout));        
    }
    
    @Test
    public void successConvertToADOCWithImageLink() throws ParseException {
        assumeNotNull(XMLFILE_MN);
        System.out.println(name.getMethodName());
        String XMLFILE_MN_WITH_IMGLINK = XMLFILE_MN + ".img.xml";
        if (Files.exists(Paths.get(XMLFILE_MN_WITH_IMGLINK))) {

            String outFileName = Paths.get(System.getProperty("buildDirectory"), "imgtest", "document.adoc").toString();
                    
            Path fileout = Paths.get(outFileName);
            fileout.toFile().delete();

            Path imageout = Paths.get(System.getProperty("buildDirectory"), "imgtest", "img" ,"image.png");
            imageout.toFile().delete();

            String[] args = new String[]{"--output-format", "adoc", "--imagesdir", "img", "--output", outFileName, XMLFILE_MN_WITH_IMGLINK};
            mnconvert.main(args);

            assertTrue(Files.exists(fileout));
            assertTrue(Files.exists(imageout));
        }
    }
    
    @Test
    public void successConvertToXMLWithImageLink() throws ParseException {
        assumeNotNull(XMLFILE_MN);
        System.out.println(name.getMethodName());
        String XMLFILE_MN_WITH_IMGLINK = XMLFILE_MN + ".img.xml";
        if (Files.exists(Paths.get(XMLFILE_MN_WITH_IMGLINK))) {

            String outFileName = Paths.get(System.getProperty("buildDirectory"), "imgtest", "document.xml").toString();
                    
            Path fileout = Paths.get(outFileName);
            fileout.toFile().delete();

            Path imageout = Paths.get(System.getProperty("buildDirectory"), "imgtest", "img" ,"image.png");
            imageout.toFile().delete();
            
            String[] args = new String[]{"--output-format", "xml", "--imagesdir", "img", "--output", outFileName, XMLFILE_MN_WITH_IMGLINK};
            mnconvert.main(args);

            
            assertTrue(Files.exists(fileout));
            assertTrue(Files.exists(imageout));
        }
    }
    
    @Test
    public void successSplitBibData() throws ParseException {
        assumeNotNull(XMLFILE_MN);
        System.out.println(name.getMethodName());
        String outFileName = new File(XMLFILE_MN).getAbsolutePath();
        outFileName = outFileName.substring(0, outFileName.lastIndexOf('.') + 1);
        Path fileoutAdoc = Paths.get(outFileName + "adoc");
        Path fileoutRxl = Paths.get(outFileName + "rxl");
        fileoutAdoc.toFile().delete();
        fileoutRxl.toFile().delete();
        
        String[] args = new String[]{"--split-bibdata", XMLFILE_MN};
        mnconvert.main(args);

        assertTrue(Files.exists(fileoutAdoc));
        assertTrue(Files.exists(fileoutRxl));
    }
    //--split-bibdata
    
}
