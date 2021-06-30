package com.metanorma.utils;

// https://stackoverflow.com/questions/2342808/how-to-validate-an-xml-file-using-java-with-an-xsd-having-an-include

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.Scanner;

import org.w3c.dom.ls.LSInput;
import org.w3c.dom.ls.LSResourceResolver;

/**
 * The Class ResourceResolver.
 */
public class ResourceResolver implements LSResourceResolver {

    /** The schema base path. */
    private final String schemaBasePath;

    /** The path map. */
    private Map<String, String> pathMap = new HashMap<String, String>();

    /**
     * Instantiates a new resource resolver.
     *
     * @param schemaBasePath the schema base path
     */
    public ResourceResolver(String schemaBasePath) {
        this.schemaBasePath = schemaBasePath;        
    }

    /* (non-Javadoc)
     * @see org.w3c.dom.ls.LSResourceResolver#resolveResource(java.lang.String, java.lang.String, java.lang.String, java.lang.String, java.lang.String)
     */
    @Override
    public LSInput resolveResource(String type, String namespaceURI,
            String publicId, String systemId, String baseURI) {
        // The base resource that includes this current resource
        String baseResourceName = null;
        String baseResourcePath = null;
        // Extract the current resource name
        if (systemId == null) { // skip empty <xsd:import/>
            return null; //
        }
        String currentResourceName = systemId.substring(systemId.lastIndexOf("/") + 1);

        // If this resource hasn't been added yet
        if (!pathMap.containsKey(currentResourceName)) {
            if (baseURI != null) {
                baseResourceName = baseURI
                        .substring(baseURI.lastIndexOf("/") + 1);
            }

            // we dont need "./" since getResourceAsStream cannot understand it
            if (systemId.startsWith("./")) {
                systemId = systemId.substring(2, systemId.length());
            }

            // If the baseResourcePath has already been discovered, get that
            // from pathMap
            if (pathMap.containsKey(baseResourceName)) {
                baseResourcePath = pathMap.get(baseResourceName);
            } else {
                // The baseResourcePath should be the schemaBasePath
                baseResourcePath = schemaBasePath;
            }

            // Read the resource as input stream
            String normalizedPath = getNormalizedPath(baseResourcePath, systemId);
            InputStream resourceAsStream = this.getClass().getClassLoader()
                    .getResourceAsStream(normalizedPath);

            // if the current resource is not in the same path with base
            // resource, add current resource's path to pathMap
            if (systemId.contains("/")) {
                pathMap.put(currentResourceName, normalizedPath.substring(0,normalizedPath.lastIndexOf("/")+1));
            } else {
                // The current resource should be at the same path as the base
                // resource
                pathMap.put(systemId, baseResourcePath);
            }
            Scanner s = new Scanner(resourceAsStream).useDelimiter("\\A");
            String s1 = s.next().replaceAll("\\n", " ") // the parser cannot understand elements broken down multiple lines e.g. (<xs:element \n name="buxing">)
                    .replace("\\t", " ") // these two about whitespaces is only for decoration
                    .replaceAll("\\s+", " ").replaceAll("[^\\x20-\\x7e]", ""); // some files has a special character as a first character indicating utf-8 file
            InputStream is = new ByteArrayInputStream(s1.getBytes());

            return new LSInputImpl(publicId, systemId, is); // same as Input class
        }

        // If this resource has already been added, do not add the same resource again. It throws
        // "org.xml.sax.SAXParseException: sch-props-correct.2: A schema cannot contain two global components with the same name; this schema contains two occurrences of ..."
        // return null instead.
        return null;
    }

    /**
     * Gets the normalized path.
     *
     * @param basePath the base path
     * @param relativePath the relative path
     * @return the normalized path
     */
    private String getNormalizedPath(String basePath, String relativePath){
        if(!relativePath.startsWith("../")){
            return basePath + relativePath;
        }
        else{
            while(relativePath.startsWith("../")){
                basePath = basePath.substring(0,basePath.substring(0, basePath.length()-1).lastIndexOf("/")+1);
                relativePath = relativePath.substring(3);
            }
            return basePath+relativePath;
        }
    }
}

