package com.metanorma;

import static com.metanorma.Constants.*;
import com.metanorma.utils.LoggerHelper;
import com.metanorma.utils.Util;
import java.io.File;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;

/**
 * This class for the command line application for conversion between Metanorma XML and NISO/ISO STS format XML (STS <-> MN XML, STS -> MN ADOC)
 */
public class mnconvert {

    private static final Logger logger = Logger.getLogger(LoggerHelper.LOGGER_NAME);
    
    static final String CMD_STSCheckOnly = "java -jar " + APP_NAME + ".jar <input_xml_file> [-check-type type...]";
    
    static final String CMD_STStoMN = "java -jar " + APP_NAME + ".jar <input_xml_file> [options]";
    
    static String VER = Util.getAppVersion();
    
    static final Options optionsInfo = new Options() {
        {
            addOption(Option.builder("v")
                    .longOpt("version")
                    .desc("display application version")
                    .required(true)
                    .build());
        }
    };
    
    // Mode 1
    static final Options optionsSTSCheckOnly = new Options() {
        {
            addOption(Option.builder("v")
                    .longOpt("version")
                    .desc("display application version")
                    .required(false)
                    .build());
            addOption(Option.builder("ct")
                    .longOpt("check-type")
                    .desc("Check against XSD NISO (value xsd-niso), DTD ISO (dtd-iso), DTD NISO (dtd-niso) (Default: xsd-niso)")
                    .hasArg()
                    .argName("xsd-niso|dtd-iso|dtd-niso")
                    .required(true)
                    .build());
        }
    };
    
    // Mode 2. STS to Metanorma conversion
    static final Options optionsMain = new Options() {
        {
            addOption(Option.builder("if")
                    .longOpt("input-format")
                    .desc("input format")
                    .hasArg()
                    .argName("metanorma|sts")
                    .required(false)
                    .build());
            addOption(Option.builder("s")
                    .longOpt("xsl-file")
                    .desc("path to XSL file")
                    .hasArg()
                    .argName("file")
                    .required(false)
                    .build());
            addOption(Option.builder("o")
                    .longOpt("output")
                    .desc("output file name")
                    .hasArg()
                    .required(false)
                    .build());
            addOption(Option.builder("of")
                    .longOpt("output-format")
                    .desc("output format: xml|adoc(default) for Metanorma output, iso|niso(default) for STS output")
                    .hasArg()
                    .argName("xml|adoc|iso|niso")
                    .required(false)
                    .build());
            addOption(Option.builder("t")
                    .longOpt("check-type")
                    .desc("For STS output only: check against XSD NISO (value 'xsd-niso', default), DTD ISO (value 'dtd-iso'), DTD NISO (value 'dtd-niso')")
                    .hasArg()
                    .argName("xsd-niso|dtd-iso|dtd-niso")
                    .required(false)
                    .build());
            addOption(Option.builder("sb")
                    .longOpt("split-bibdata")
                    .desc("For STS input only: create MN Adoc and Relaton XML")
                    .required(false)
                    .build());
            addOption(Option.builder("img")
                    .longOpt("imagesdir")
                    .desc("For STS input only: folder with images (default 'images')")
                    .hasArg()
                    .required(false)
                    .build());
            addOption(Option.builder("t")
                    .longOpt("type")
                    .desc("For STS input only: type of standard to generate (Metanorma XML output only)")
                    .hasArg()
                    .required(false)
                    .build());
            addOption(Option.builder("ct")
                    .longOpt("check-type")
                    .desc("Check against XSD NISO (value xsd-niso), DTD ISO (dtd-iso), DTD NISO (dtd-niso) (Default: xsd-niso)")
                    .hasArg()
                    .argName("xsd-niso|dtd-iso|dtd-niso")
                    .required(false)
                    .build());
            addOption(Option.builder("d")
                    .longOpt("debug")
                    .desc("print additional debug information into output file")
                    .required(false)
                    .build());
            addOption(Option.builder("v")
                    .longOpt("version")
                    .desc("display application version")
                    .required(false)
                    .build());            
        }
    };
    
    static final String USAGE = getUsage();
    
    /**
     * Main method.
     *
     * @param args command-line arguments
     * @throws org.apache.commons.cli.ParseException
     */
    public static void main(String[] args) throws ParseException {

        LoggerHelper.setupLogger();
        
        CommandLineParser parser = new DefaultParser();
               
        boolean cmdFail = false;
        
        try {
            CommandLine cmdInfo = parser.parse(optionsInfo, args);
            printVersion(cmdInfo.hasOption("version"));            
        } catch (ParseException exp) {
            cmdFail = true;
        }
        
        if(cmdFail) {
            try {
                CommandLine cmdSTSCheckOnly = parser.parse(optionsSTSCheckOnly, args);
                System.out.print(APP_NAME + " ");
                printVersion(cmdSTSCheckOnly.hasOption("version"));
                System.out.println("\n");
                
                List<String> arglist = cmdSTSCheckOnly.getArgList();
                if (arglist.isEmpty() || arglist.get(0).trim().length() == 0) {
                    throw new ParseException("");
                }

                String argXmlIn = arglist.get(0);
                
                STSValidator validator = new STSValidator(argXmlIn, cmdSTSCheckOnly.getOptionValue("check-type"));
                
                if (!validator.check()) {
                    System.exit(ERROR_EXIT_CODE);
                }
                
                cmdFail = false;
            } catch (ParseException exp) {
                cmdFail = true;
            }
        }
        
        if(cmdFail) {            
            try {
                CommandLine cmdMain = parser.parse(optionsMain, args);
                
                System.out.print(APP_NAME + " ");
                printVersion(cmdMain.hasOption("version"));
                System.out.println("\n");
                
                List<String> arglist = cmdMain.getArgList();
                if (arglist.isEmpty() || arglist.get(0).trim().length() == 0) {
                    throw new ParseException("");
                }
                
                String argXmlIn = arglist.get(0);
                
                File fXMLin = new File(argXmlIn);
                if (!fXMLin.exists()) {
                    logger.severe(String.format(INPUT_NOT_FOUND, XML_INPUT, fXMLin));
                    System.exit(ERROR_EXIT_CODE);
                }
                
                String inputFormat = cmdMain.getOptionValue("input-format");
                if (inputFormat != null) {
                    inputFormat = inputFormat.toLowerCase();
                } else {
                    // determine input xml file format
                    inputFormat = Util.getXMLFormat(argXmlIn);
                }
                
                boolean result = false;
                
                switch (inputFormat) {
                    case "sts":
                        {
                            STS2MN_XsltConverter converter = new STS2MN_XsltConverter();
                            converter.setInputFilePath(argXmlIn);
                            converter.setInputXslPath(cmdMain.getOptionValue("xsl-file"));
                            converter.setOutputFilePath(cmdMain.getOptionValue("output"));
                            converter.setOutputFormat(cmdMain.getOptionValue("output-format"));
                            converter.setImagesDir(cmdMain.getOptionValue("imagesdir"));
                            converter.setIsSplitBibdata(cmdMain.hasOption("split-bibdata"));
                            converter.setDebugMode(cmdMain.hasOption("debug"));
                            converter.setTypeStandard(cmdMain.getOptionValue("type"));
                            result = converter.process();
                            break;
                        }
                    case "metanorma":
                        {
                            MN2STS_XsltConverter converter = new MN2STS_XsltConverter();
                            converter.setInputFilePath(argXmlIn);
                            converter.setInputXslPath(cmdMain.getOptionValue("xsl-file"));
                            converter.setOutputFilePath(cmdMain.getOptionValue("output"));
                            converter.setOutputFormat(cmdMain.getOptionValue("output-format"));
                            converter.setDebugMode(cmdMain.hasOption("debug"));
                            converter.setCheckType(cmdMain.getOptionValue("check-type"));
                            result = converter.process();
                            break;
                        }
                    default:
                        logger.log(Level.SEVERE, "Unknown input file format ''{0}''", inputFormat);
                        System.exit(ERROR_EXIT_CODE);
                }
                
                if (!result) {
                    System.exit(ERROR_EXIT_CODE);
                }
                cmdFail = false;
                
            } catch (ParseException exp) {
                cmdFail = true;
            }
        }
        
        
        if (cmdFail) {
            System.out.println(USAGE);
            System.exit(ERROR_EXIT_CODE);
        }
        
    }
    
    
    private static String getUsage() {
        StringWriter stringWriter = new StringWriter();
        PrintWriter pw = new PrintWriter(stringWriter);
        HelpFormatter formatter = new HelpFormatter();
        formatter.printHelp(pw, 80, CMD_STSCheckOnly, "", optionsSTSCheckOnly, 0, 0, "");
        pw.write("\nOR\n\n");
        formatter.printHelp(pw, 80, CMD_STStoMN, "", optionsMain, 0, 0, "");
        pw.flush();
        return stringWriter.toString();
    }


    private static void printVersion(boolean print) {
        if (print) {            
            System.out.println(VER);
        }
    }       

}