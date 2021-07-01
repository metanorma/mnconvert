package org.metanorma.validator;

import java.io.File;
import java.util.LinkedList;
import java.util.List;
import org.xml.sax.ErrorHandler;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

abstract class Validator {

    final List<String> exceptions = new LinkedList<>();
    CheckAgainstEnum checkAgainst;
    File xml;
    
    ErrorHandler errorHandler = new ErrorHandler() {
        @Override
        public void warning(SAXParseException exception) throws SAXException
        {
          exceptions.add(exception.toString());
        }

        @Override
        public void fatalError(SAXParseException exception) throws SAXException
        {
          exceptions.add(exception.toString());
        }

        @Override
        public void error(SAXParseException exception) throws SAXException
        {
          exceptions.add(exception.toString());
        }
    };
    
    public Validator (File xml) {
        this.xml = xml;
    }
    
    abstract public List<String> validate(CheckAgainstEnum checkAgainst);
        
}
