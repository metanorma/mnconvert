package org.metanorma.parser;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 *
 * @author Alexander Dyuzhev
 */
public class MetanormaElement {
    
    //Attributes attributes;
    
    Map<String, String> attributes = new LinkedHashMap<>();
    
    String name = "";

    String text = "";
    
    List<MetanormaElement> childElements = new ArrayList<>();
    
    public MetanormaElement(String name, Map<String, String> attributes) {
        this.name = name;
        this.attributes = attributes;
    }
    
    public MetanormaElement(String text) {
        this.text = text;
    }
    
    public Map<String, String> getAttributes() {
        return attributes;
    }

    /*public void setAttribute(String name, String value) {
        this.attributes.put(name, value);
    }*/
    
    public void setAttributes(Map<String, String> attributes) {
        this.attributes = attributes;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
    
    public void addChild(MetanormaElement child) {
        childElements.add(child);
    }
    
    
    @Override
    public String toString() {
        
        StringBuilder sb = new StringBuilder();
        
        if (!name.isEmpty()) {
            sb.append("Element '").append(name).append("':\n");
        }
        
        for (Map.Entry entry : attributes.entrySet()) {
            System.out.println("@" + entry.getKey() + "=" + entry.getValue());
        }
        
        if (!text.isEmpty()) {
            sb.append("text: ").append(text).append("\n");
        }
        
        sb.append("\n");

        childElements.stream().forEach(c -> sb.append(c.toString()));
        
        return sb.toString();
    }
    
    
    public String toXML() {
        StringBuilder sb = new StringBuilder();
        
        if (!name.isEmpty()) {
            sb.append("<").append(name);
        }
        
        for (Map.Entry entry : attributes.entrySet()) {
            sb.append(" ").append(entry.getKey()).append("=\"").append(entry.getValue()).append("\"");
        }
        
        if (!name.isEmpty()) {
            if (childElements.isEmpty()) {
                sb.append("/");
            }
            sb.append(">");
        }
        
        if (!text.isEmpty()) {
            sb.append(text);
        }
        
        childElements.stream().forEach(c -> sb.append(c.toXML()));
        
        if (!name.isEmpty() && !childElements.isEmpty()) {
            sb.append("</").append(name).append(">");
        }
        
        return sb.toString();
    }
}
