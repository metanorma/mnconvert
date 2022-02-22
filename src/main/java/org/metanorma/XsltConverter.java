package org.metanorma;

import java.io.File;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;
import java.util.logging.Logger;
import org.metanorma.utils.LoggerHelper;

public abstract class XsltConverter {
    
    protected static final Logger logger = Logger.getLogger(LoggerHelper.LOGGER_NAME);
    
    protected final String TMPDIR = System.getProperty("java.io.tmpdir");
    protected final Path tmpfilepath  = Paths.get(TMPDIR, UUID.randomUUID().toString());
    
    protected String inputFilePath = "document.xml"; // default input file name
    
    protected boolean isInputFileRemote = false; // true, if inputFilePath starts from http, https, www.
    
    protected String inputXslPath = null; // default xsl is null (will be used from jar)
    protected File fileXSL = null;
    
    protected String outputFilePath = ""; // default output file name
    
    protected String outputFormat = "adoc"; // default output format is 'adoc'
    
    protected boolean isDebugMode = false; // default no debug
    
    protected boolean isIdRefChecking = false;
    
    public void setInputFilePath(String inputFilePath) {
        this.inputFilePath = inputFilePath;
    }

    public void setInputXslPath(String inputXslPath) {
        this.inputXslPath = inputXslPath;
    }
    
    public void setOutputFilePath(String outputFilePath) {
        if (outputFilePath != null) {
            this.outputFilePath = outputFilePath;
        }
    }
    
    public void setOutputFormat(String outputFormat) {
        if (outputFormat != null) {
            this.outputFormat = outputFormat.toLowerCase();
        }
    }
    
    public void setDebugMode(boolean isDebugMode) {
        this.isDebugMode = isDebugMode;
    }
    
    public void setIdRefChecking(boolean isIdRefChecking) {
        this.isIdRefChecking = isIdRefChecking;
    }
    
    public String getDefaultOutputFilePath() {
        if (outputFilePath.isEmpty()) {
            File fInputFilePath = new File(inputFilePath);
            String outFilePath = fInputFilePath.getAbsolutePath();
            if (isInputFileRemote) {
                outFilePath = Paths.get(System.getProperty("user.dir"), new File(outFilePath).getName()).toString();
            }
            String outputFilePathWithoutExtension = outFilePath.substring(0, outFilePath.lastIndexOf('.') + 1);
            return outputFilePathWithoutExtension;
        }
        return outputFilePath;
    }
    
    abstract boolean process();
}
