package org.metanorma;

public interface XsltConverter {
    void setInputFilePath(String inputFilePath);

    void setInputXslPath(String inputXslPath);

    void setOutputFilePath(String outputFilePath);

    void setDebugMode(boolean isDebugMode);

    void setOutputFormat(String outputFormat);

    boolean process();
}
