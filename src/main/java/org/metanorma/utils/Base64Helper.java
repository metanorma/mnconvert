package org.metanorma.utils;

import java.util.Base64;


/**
 *
 * @author Alexander Dyuzhev
 */
public class Base64Helper {
    
    public static String encodeBase64(String input) {
        return Base64.getEncoder().encodeToString(input.getBytes());
    }

}
