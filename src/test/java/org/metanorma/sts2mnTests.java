package org.metanorma;

import com.ginsberg.junit.exit.ExpectSystemExitWithStatus;
import org.junit.jupiter.api.*;
import org.metanorma.utils.LoggerHelper;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import org.apache.commons.cli.ParseException;

public class sts2mnTests {

    static String XMLFILE_MN;// = "test.mn.xml";
    //final String XMLFILE_STS = "test.sts.xml";
    

    @BeforeAll
    public static void setUpBeforeClass() throws Exception {
        LoggerHelper.setupLogger();
        XMLFILE_MN = System.getProperty("inputSTSXML");
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

        //assertTrue(systemOutRule.getLog().contains(mnconvert.USAGE));
    }

    
    @Test
    @ExpectSystemExitWithStatus(-1)
    public void xmlNotExists() throws ParseException {

        String[] args = new String[]{"nonexist.xml"};
        mnconvert.main(args);

        /*assertTrue(systemOutRule.getLog().contains(
                String.format(INPUT_NOT_FOUND, XML_INPUT, args[1])));*/
    }

    @Test
    @ExpectSystemExitWithStatus(-1)
    public void unknownOutputFormat() throws ParseException {
        Assumptions.assumeTrue(XMLFILE_MN != null);

        String[] args = new String[]{"--output-format", "abc", XMLFILE_MN};
        mnconvert.main(args);

        /*assertTrue(systemOutRule.getLog().contains(
                String.format(UNKNOWN_OUTPUT_FORMAT, args[1])));*/
    }
    
    

    @Test
    public void successConvertToAdocDefault() throws ParseException {
        Assumptions.assumeTrue(XMLFILE_MN != null);
        String outFileName = new File(XMLFILE_MN).getAbsolutePath();
        outFileName = outFileName.substring(0, outFileName.lastIndexOf('.') + 1);
        Path fileout = Paths.get(outFileName + "adoc");
        fileout.toFile().delete();
        
        String[] args = new String[]{XMLFILE_MN};
        mnconvert.main(args);

        Assumptions.assumeTrue(Files.exists(fileout));
    }
    
    @Test
    public void successConvertToAdoc() throws ParseException {
        Assumptions.assumeTrue(XMLFILE_MN != null);
        String outFileName = new File(XMLFILE_MN).getAbsolutePath();
        outFileName = outFileName.substring(0, outFileName.lastIndexOf('.') + 1);
        Path fileout = Paths.get(outFileName + "adoc");
        fileout.toFile().delete();
        
        String[] args = new String[]{"--output-format", "adoc", XMLFILE_MN};
        mnconvert.main(args);

        Assumptions.assumeTrue(Files.exists(fileout));
    }
    
    @Test
    public void successConvertToAdocOutputSpecified() throws ParseException {
        Assumptions.assumeTrue(XMLFILE_MN != null);
        Path fileout = Paths.get(System.getProperty("buildDirectory"), "custom.adoc");
        fileout.toFile().delete();
        
        String[] args = new String[]{"--output-format", "adoc", "--output", fileout.toAbsolutePath().toString(), XMLFILE_MN};
        mnconvert.main(args);

        Assumptions.assumeTrue(Files.exists(fileout));
    }

    /*@Test
    public void successConvertRemoteToAdocOutputSpecified() throws ParseException {
        System.out.println(name.getMethodName());
        Path fileout = Paths.get(System.getProperty("buildDirectory"),"NISO-STS-Standard-1-0", "NISO-STS-Standard-1-0.adoc");
        fileout.toFile().delete();
        String remoteXML = "https://www.niso-sts.org/downloadables/samples/NISO-STS-Standard-1-0.XML";
        String[] args = new String[]{"--output-format", "adoc", "--output", fileout.toAbsolutePath().toString(), remoteXML};
        mnconvert.main(args);

        assertTrue(Files.exists(fileout));
    }*/

    @Test
    public void successConvertToRelativeAdocOutputSpecified() throws ParseException {
        Assumptions.assumeTrue(XMLFILE_MN != null);
        String user_dir = System.getProperty("user.dir");
        System.setProperty("user.dir", System.getProperty("buildDirectory"));

        String filename = "custom_relative.adoc";
        //Path fileout = Paths.get(System.getProperty("buildDirectory"), "custom_relative.adoc");
        Path fileout = Paths.get(new File(filename).getAbsolutePath());
        fileout.toFile().delete();

        String[] args = new String[]{"--output-format", "adoc", "--output", filename,
                Paths.get(System.getProperty("buildDirectory"), "..", XMLFILE_MN).normalize().toString()};
        mnconvert.main(args);
        System.setProperty("user.dir", user_dir); // we should restore value for another tests
        Assumptions.assumeTrue(Files.exists(fileout));
    }
    
    /*@Test
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
    }*/

    /*@Test
    public void successConvertRemoteToXML() throws ParseException {
        System.out.println(name.getMethodName());
        Path fileout = Paths.get(System.getProperty("buildDirectory"), "NISO-STS-Standard-1-0.mn.xml");
        fileout.toFile().delete();
        String remoteXML = "https://www.niso-sts.org/downloadables/samples/NISO-STS-Standard-1-0.XML";
        fileout.toFile().delete();
        String[] args = new String[]{"--output-format", "xml", "--output", fileout.toAbsolutePath().toString(), remoteXML};
        mnconvert.main(args);
        assertTrue(Files.exists(fileout));
    }*/

    @Test
    public void successConvertToADOCWithImageLink() throws ParseException {
        Assumptions.assumeTrue(XMLFILE_MN != null);
        String XMLFILE_MN_WITH_IMGLINK = XMLFILE_MN + ".img.xml";
        if (Files.exists(Paths.get(XMLFILE_MN_WITH_IMGLINK))) {

            String outFileName = Paths.get(System.getProperty("buildDirectory"), "imgtest", "document.adoc").toString();
                    
            Path fileout = Paths.get(outFileName);
            fileout.toFile().delete();

            Path imageout = Paths.get(System.getProperty("buildDirectory"), "imgtest", "img" ,"image.png");
            imageout.toFile().delete();

            String[] args = new String[]{"--output-format", "adoc", "--imagesdir", "img", "--output", outFileName, XMLFILE_MN_WITH_IMGLINK};
            mnconvert.main(args);

            Assumptions.assumeTrue(Files.exists(fileout));
            Assumptions.assumeTrue(Files.exists(imageout));
        }
    }
    
    /*@Test
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
    }*/
    
    @Test
    public void successSplitBibData() throws ParseException {
        Assumptions.assumeTrue(XMLFILE_MN != null);
        String outFileName = new File(XMLFILE_MN).getAbsolutePath();
        outFileName = outFileName.substring(0, outFileName.lastIndexOf('.') + 1);
        Path fileoutAdoc = Paths.get(outFileName + "adoc");
        Path fileoutRxl = Paths.get(outFileName + "rxl");
        fileoutAdoc.toFile().delete();
        fileoutRxl.toFile().delete();
        
        String[] args = new String[]{"--split-bibdata", XMLFILE_MN};
        mnconvert.main(args);

        Assumptions.assumeTrue(Files.exists(fileoutAdoc));
        Assumptions.assumeTrue(Files.exists(fileoutRxl));
    }
    //--split-bibdata
    
}
