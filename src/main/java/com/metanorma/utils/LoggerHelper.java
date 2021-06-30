package com.metanorma.utils;

import com.metanorma.mnconvert;

/**
 *
 * @author Alexander Dyuzhev
 */
public final class LoggerHelper {
    public static final String LOGGER_NAME = mnconvert.class.getPackage().getName() + "." + mnconvert.class;
    
    private LoggerHelper() {
     
    }
    
    public static void setupLogger() {
        //System.setProperty("java.util.logging.SimpleFormatter.format", "[%1$tF %1$tT] [%4$s] %5$s%6$s%n");
        System.setProperty("java.util.logging.SimpleFormatter.format", "%5$s%6$s%n");
        //System.setProperty("handlers", "java.util.logging.ConsoleHandler");
    }
}
