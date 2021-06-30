package com.metanorma;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 *
 * @author Alexander Dyuzhev
 */
public class RegExHelper {
    
    public static String matches(String regex, String input) {
        boolean b = Pattern.matches(regex, input);
        return Boolean.toString(b);
    }

}
