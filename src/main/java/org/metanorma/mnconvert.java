package org.metanorma;

import static org.metanorma.Constants.*;
import org.metanorma.utils.LoggerHelper;
import org.metanorma.utils.Util;
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
 * This class for the command line application for conversion between NISO/ISO STS format XML and Metanorma XML/ADOC (MN XML -> STS , STS -> MN ADOC)
 */
public class mnconvert {

    private static final Logger logger = Logger.getLogger(LoggerHelper.LOGGER_NAME);
    
    static final String CMD_STSCheckOnly = "java -jar " + APP_NAME + ".jar <input_xml_file> [--check-type type...]";
    
    static final String CMD_STSCheckOnlyExternal = "java -jar " + APP_NAME + ".jar <input_xml_file> [--validation-against <path to DTD/XSD>]";
    
    static final String CMD_STSorRFCtoMN = "java -jar " + APP_NAME + ".jar <input_xml_file> [options]";
    
    static final String CMD_DOCXtoMN = "java -jar " + APP_NAME + ".jar <input_docx_file> [options]";
    
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
                    .desc("Check against XSD NISO (value 'xsd-niso', default), DTD ISO (value 'dtd-iso'), DTD NISO (value 'dtd-niso')")
                    .hasArg()
                    .argName("xsd-niso|dtd-iso|dtd-niso")
                    .required(true)
                    .build());
            addOption(Option.builder("ts")
                    .longOpt("tagset")
                    .desc("use Interchange (value 'interchange', default) or Extended (value 'extended') NISO STS Tag Set in NISO DTD/XSD validation")
                    .hasArg()
                    .argName("interchange|extended")
                    .required(false)
                    .build());
            addOption(Option.builder("m")
                    .longOpt("mathml")
                    .desc("use MathML version 2 (value '2') or 3 (value '3', default) in NISO DTD/XSD validation")
                    .hasArg()
                    .argName("2|3")
                    .required(false)
                    .build());
            addOption(Option.builder("idref")
                    .longOpt("idrefchecking")
                    .desc("Enable checking of ID/IDREF constraints (for XSD NISO only)")
                    .required(false)
                    .build());
        }
    };
    
    // Mode 1.1 (External)
    static final Options optionsSTSCheckOnlyExternal = new Options() {
        {
            addOption(Option.builder("v")
                    .longOpt("version")
                    .desc("display application version")
                    .required(false)
                    .build());
            addOption(Option.builder("va")
                    .longOpt("validation-against")
                    .desc("Path to DTD/XSD")
                    .hasArg()
                    .required(true)
                    .build());
            addOption(Option.builder("idref")
                    .longOpt("idrefchecking")
                    .desc("Enable checking of ID/IDREF constraints (for XSD only)")
                    .required(false)
                    .build());
        }
    };
    
    // Mode 2. STS to Metanorma, or XML2RFC to Metanorma conversion
    static final Options optionsMain = new Options() {
        {
            addOption(Option.builder("if")
                    .longOpt("input-format")
                    .desc("input format")
                    .hasArg()
                    .argName("metanorma|sts|ieee|rfc")
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
                    .desc("output format: adoc for Metanorma output, iso|niso(default) for STS output, or ieee for IEEE format output")
                    .hasArg()
                    .argName("xml|adoc|iso|niso|ieee")
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
            addOption(Option.builder("st")
                    .longOpt("type")
                    .desc("For STS input only: type of standard to generate (Metanorma XML output only)")
                    .hasArg()
                    .required(false)
                    .build());
            /*addOption(Option.builder("sx")
                    .longOpt("semantic")
                    .desc("For STS input only: generate semantic XML (Metanorma XML output only)")
                    .required(false)
                    .build());*/
            addOption(Option.builder("ct")
                    .longOpt("check-type")
                    .desc("For STS output only: check against XSD NISO (value 'xsd-niso', default), DTD ISO (value 'dtd-iso'), DTD NISO (value 'dtd-niso')")
                    .hasArg()
                    .argName("xsd-niso|dtd-iso|dtd-niso")
                    .required(false)
                    .build());
            addOption(Option.builder("ts")
                    .longOpt("tagset")
                    .desc("For STS NISO output only: use Interchange (value 'interchange', default) or Extended (value 'extended') NISO STS Tag Set in DTD/XSD validation")
                    .hasArg()
                    .argName("interchange|extended")
                    .required(false)
                    .build());
            addOption(Option.builder("m")
                    .longOpt("mathml")
                    .desc("For STS NISO output only: use MathML version 2 (value '2') or 3 (value '3', default) in DTD/XSD validation")
                    .hasArg()
                    .argName("2|3")
                    .required(false)
                    .build());
            addOption(Option.builder("va")
                    .longOpt("validation-against")
                    .desc("Path to DTD/XSD")
                    .hasArg()
                    .required(false)
                    .build());
            addOption(Option.builder("idref")
                    .longOpt("idrefchecking")
                    .desc("Enable checking of ID/IDREF constraints (for XSD NISO only)")
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
    
    // Mode 3. Docx to Metanorma Adoc conversion
    static final Options optionsMainDocx = new Options() {
        {
            addOption(Option.builder("o")
                    .longOpt("output")
                    .desc("output file name")
                    .hasArg()
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
                validator.setTagset(cmdSTSCheckOnly.getOptionValue("tagset"));
                validator.setMathmlVersion(cmdSTSCheckOnly.getOptionValue("mathml"));
                validator.setDebugMode(cmdSTSCheckOnly.hasOption("debug"));
                validator.setIdRefChecking(cmdSTSCheckOnly.hasOption("idrefchecking"));
                
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
                CommandLine cmdSTSCheckOnlyExternal = parser.parse(optionsSTSCheckOnlyExternal, args);
                System.out.print(APP_NAME + " ");
                printVersion(cmdSTSCheckOnlyExternal.hasOption("version"));
                System.out.println("\n");
                
                List<String> arglist = cmdSTSCheckOnlyExternal.getArgList();
                if (arglist.isEmpty() || arglist.get(0).trim().length() == 0) {
                    throw new ParseException("");
                }

                String argXmlIn = arglist.get(0);
                
                STSValidator validator = new STSValidator(argXmlIn);
                validator.setFilepathDTDorXSD(cmdSTSCheckOnlyExternal.getOptionValue("validation-against"));
                
                validator.setDebugMode(cmdSTSCheckOnlyExternal.hasOption("debug"));
                validator.setIdRefChecking(cmdSTSCheckOnlyExternal.hasOption("idrefchecking"));
                
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
                
                boolean isFileNotFound = false;
                if (argXmlIn.toLowerCase().startsWith("http") || argXmlIn.toLowerCase().startsWith("www.")) {
                    if (!Util.isUrlExists(argXmlIn)) {
                        isFileNotFound = true;
                    }
                } else if (!fXMLin.exists()) {
                    isFileNotFound = true;
                }
                if (isFileNotFound) {
                    logger.severe(String.format(INPUT_NOT_FOUND, XML_INPUT, fXMLin));
                    System.exit(ERROR_EXIT_CODE);
                }
                
                String inputFormat = cmdMain.getOptionValue("input-format");
                if (inputFormat != null) {
                    inputFormat = inputFormat.toLowerCase();
                } else {
                    // determine input file format (xml or docx)
                    inputFormat = Util.getInputFormat(argXmlIn);
                }

                XsltConverter converter = null;
                String defaultOutputFormat = null;
                switch (inputFormat) {
                    case "ieee":
                    case "sts":
                        {
                            STS2MN_XsltConverter sts2mn = new STS2MN_XsltConverter();
                            sts2mn.setImagesDir(cmdMain.getOptionValue("imagesdir"));
                            sts2mn.setIsSplitBibdata(cmdMain.hasOption("split-bibdata"));
                            sts2mn.setTypeStandard(cmdMain.getOptionValue("type"));
                            //sts2mn.setIsSemanticXML(cmdMain.hasOption("semantic"));
                            defaultOutputFormat = "adoc";
                            converter = sts2mn;
                            break;
                        }
                    case "metanorma":
                        {
                            MN2STS_XsltConverter mn2sts = new MN2STS_XsltConverter();
                            mn2sts.setCheckType(cmdMain.getOptionValue("check-type"));
                            mn2sts.setTagset(cmdMain.getOptionValue("tagset"));
                            mn2sts.setMathmlVersion(cmdMain.getOptionValue("mathml"));
                            mn2sts.setFilepathDTDorXSD(cmdMain.getOptionValue("validation-against"));
                            defaultOutputFormat = "niso";
                            converter = mn2sts;
                            break;
                        }
                    case "rfc":
                        {
                            RFC2MN_XsltConverter rfc2mn = new RFC2MN_XsltConverter();
                            converter = rfc2mn;
                            break;
                        }
                    case "docx":
                        {
                            DOCX2MN_XsltConverter docx2mn = new DOCX2MN_XsltConverter();
                            converter = docx2mn;
                            break;
                        }
                    default:
                        logger.log(Level.SEVERE, "Unknown input file format ''{0}''", inputFormat);
                        System.exit(ERROR_EXIT_CODE);
                }

                converter.setInputFilePath(argXmlIn);
                converter.setOutputFormat(cmdMain.getOptionValue("output-format", defaultOutputFormat));
                converter.setInputXslPath(cmdMain.getOptionValue("xsl-file"));
                converter.setOutputFilePath(cmdMain.getOptionValue("output"));
                converter.setDebugMode(cmdMain.hasOption("debug"));
                converter.setIdRefChecking(cmdMain.hasOption("idrefchecking"));
                
                if (!converter.process()) {
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
        formatter.printHelp(pw, 80, CMD_STSCheckOnlyExternal, "", optionsSTSCheckOnlyExternal, 0, 0, "");
        pw.write("\nOR\n\n");
        formatter.printHelp(pw, 80, CMD_STSorRFCtoMN, "", optionsMain, 0, 0, "");
        pw.write("\nOR\n\n");
        formatter.printHelp(pw, 80, CMD_DOCXtoMN, "", optionsMainDocx, 0, 0, "");
        pw.flush();
        return stringWriter.toString();
    }


    private static void printVersion(boolean print) {
        if (print) {            
            System.out.println(VER);
        }
    }       

}