package org.metanorma.parser;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Stack;

import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

/**
 *
 * @author Alexander Dyuzhev
 */
public class MetanormaHandler extends DefaultHandler{
    
    private StringBuilder data = new StringBuilder();;
    
    Stack metanormaElementsStack = new Stack();
    
    MetanormaElement rootElement;
    
    MetanormaElement getRoot() {
        return rootElement;
    }
    
    @Override
    public void startElement(String uri, String localName, String qName, Attributes attributes) throws SAXException {

        /*if (metanormaElementsStack.isEmpty()) {
            metanormaElementsStack.push(new MetanormaElement("root", null));
        }*/
        
        if (data.length() != 0) {
            ((MetanormaElement)metanormaElementsStack.peek()).addChild(new MetanormaElement(data.toString()));
            data = new StringBuilder();
        }
        
        Map<String, String> xmlAttributes = new LinkedHashMap<>();
        for(int i=0; i < attributes.getLength(); i++) {
            xmlAttributes.put(attributes.getQName(i), attributes.getValue(i));
        }
        
        MetanormaElement mnElement = new MetanormaElement(qName, xmlAttributes);
        
        metanormaElementsStack.push(mnElement);
        
        data = new StringBuilder();
        
    }
    
    @Override
    public void endElement(String uri, String localName, String qName) throws SAXException {
        MetanormaElement parsedElement = (MetanormaElement) metanormaElementsStack.pop();
        
        if (data.length() != 0) {
            parsedElement.addChild(new MetanormaElement(data.toString()));
            data = new StringBuilder();
        }
        
        if (!metanormaElementsStack.empty()) {
            ((MetanormaElement)metanormaElementsStack.peek()).addChild(parsedElement);
        }
        
        if (metanormaElementsStack.empty()) {
            rootElement = parsedElement;
        }
    }
    
    @Override
    public void characters(char ch[], int start, int length) throws SAXException {
            data.append(new String(ch, start, length));
    }
}
