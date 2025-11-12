package org.metanorma;

import java.io.InputStream;
import javax.xml.transform.Source;
import javax.xml.transform.TransformerException;
import javax.xml.transform.URIResolver;
import javax.xml.transform.stream.StreamSource;

import org.metanorma.utils.ResourcesUtils;

/**
 *
 * @author Alexander Dyuzhev
 */
public class XSLT_ResourceResolver implements URIResolver {
    /* 
     * @see javax.xml.transform.URIResolver#resolve(java.lang.String, java.lang.String)
     */
    public Source resolve(String href, String base) throws TransformerException {
        try {
            //InputStream is = ClassLoader.getSystemResourceAsStream(href);
            //return new StreamSource(is, href);
            return new StreamSource(ResourcesUtils.getStreamFromResources(getClass().getClassLoader(), href));
        }
        catch (Exception ex) {
            throw new TransformerException(ex);
        }
    }
    
    /**
     * @param href
     * @return
     * @throws TransformerException
     */
    public InputStream resolve(String href) throws TransformerException {
        try {
            InputStream is = ClassLoader.getSystemResourceAsStream(href);
            return is;
        }
        catch (Exception ex) {
            throw new TransformerException(ex);
        }
    }
}
