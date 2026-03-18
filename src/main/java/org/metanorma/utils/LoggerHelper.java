package org.metanorma.utils;

import org.metanorma.mnconvert;

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
        // %5$: message (formatted log message)
        // %6$: thrown (exception stack trace, if any)
        System.setProperty("java.util.logging.SimpleFormatter.format", "[mnconvert] %5$s%6$s%n");
        //System.setProperty("handlers", "java.util.logging.ConsoleHandler");
    }
}
