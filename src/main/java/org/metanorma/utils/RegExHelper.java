package org.metanorma.utils;

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
    
    public static String escapeFormattingCommands(String text) {
        StringBuilder parts = new StringBuilder();
        
        //Words in Asciidoc are delimited by blank space or punctuation (,;".?!).
        String delimeters = "\\s\\(,;\"\\.\\?\\!\\)";
        String regexDelimeters = "[" + delimeters + "]+";
        
        String regexWord = "[^" + delimeters + "]+";
        Pattern pWord = Pattern.compile(regexWord);
        
        String regexParts = regexWord + "|" + regexDelimeters;
        Pattern pParts = Pattern.compile(regexParts);
        
        // formatting characters *_`#~^
        String formattingCharacters = "[*_`#~\\^]";
        
        
        // For any formatting character <F>,
        // \A(<F>)(.+)\1\Z => \\\1\2\1: escape an initial formatting character only 
        // if they occur at the start and end of the word. So _abc_ => \_abc_, but not a_bc_ and not _abc.
        String regexRule1 = "^(" + formattingCharacters +")" + "(.*)" + "\\1$";
        Pattern pRule1 = Pattern.compile(regexRule1);
        
        // \A(.*)(<F>)\2(.+)\2\2(.*)\Z => \1\\\2\2\3\2\2\4: escape the first of four formatting character, 
        // only if there is are two instances of pairs of the formatting character within the word (at any place). 
        // So a__b__c_d => a\__b__c_d, but not a_b__c or __abc
        String regexRule2 = "^(.*)(" + formattingCharacters + ")\\2(.+)\\2\\2(.*)$";
        Pattern pRule2 = Pattern.compile(regexRule2);
        
        Matcher m = pParts.matcher(text);
        while (m.find()) {
            String part = m.group();
            //System.out.println("group="+part);
            
            Matcher mWord = pWord.matcher(part);
            if (mWord.find()) {
                //System.out.println("is Word");
                Matcher mRule1 = pRule1.matcher(part);
                if (mRule1.find()) {
                    part = mRule1.replaceFirst("\\\\$1$2$1");
                } else {
                    Matcher mRule2 = pRule2.matcher(part);
                    if (mRule2.find()) {
                        part = mRule2.replaceFirst("$1\\\\$2$2$3$2$2$4");
                    }
                }   
            }
            parts.append(part);
        }
        
        return parts.toString();
    }
    
    /*public static void main(String[] args) {
        String test = escapeFormattingCommands("a__b__c_d a_b__c __abc");
        System.out.println(test);
    }*/

}
