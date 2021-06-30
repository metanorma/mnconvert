package com.metanorma.utils;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.JarURLConnection;
import java.net.URISyntaxException;
import java.net.URL;
import java.net.URLConnection;
import java.util.Enumeration;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;
import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;

public class ResourcesUtils {
    
    // https://github.com/nguyenq/tess4j/blob/master/src/main/java/net/sourceforge/tess4j/util/LoadLibs.java
    /**
     * Copies resources to target folder.
     *
     * @param resourceUrl
     * @param targetPath
     */
    public static void copyResources(URL resourceUrl, String basePath, File targetPath) throws IOException, URISyntaxException {
        
        if (resourceUrl == null) {
            return;
        }

        //System.out.println("resourceUrl=" + resourceUrl.toString());
        URLConnection urlConnection = resourceUrl.openConnection();

        /**
         * Copy resources either from inside jar or from project folder.
         */
        if (urlConnection instanceof JarURLConnection) {
            copyJarResourceToPath((JarURLConnection) urlConnection, targetPath);        
        } else {
            File file = new File(resourceUrl.getPath());
            if (file.isDirectory()) {
                for (File resourceFile : FileUtils.listFiles(file, null, true)) {
                    String resourceFilePath = resourceFile.getPath().replaceAll("\\\\", "/");
                    //int index = resourceFile.getPath().lastIndexOf(targetPath.getName()) + targetPath.getName().length();
                    int index = resourceFilePath.lastIndexOf(basePath);
                    File targetFile = new File(targetPath, resourceFile.getPath().substring(index));
                    if (!targetFile.exists() || targetFile.length() != resourceFile.length() || targetFile.lastModified() != resourceFile.lastModified()) {
                        if (resourceFile.isFile()) {
                            FileUtils.copyFile(resourceFile, targetFile, true);
                        }
                    }
                }
            } else {
                if (!targetPath.exists() || targetPath.length() != file.length() || targetPath.lastModified() != file.lastModified()) {
                    FileUtils.copyFile(file, targetPath, true);
                }
            }
        }
    }

    /**
     * Copies resources from the jar file of the current thread and extract it
     * to the destination path.
     *
     * @param jarConnection
     * @param destPath destination file or directory
     */
    static void copyJarResourceToPath(JarURLConnection jarConnection, File destPath) {
        try (JarFile jarFile = jarConnection.getJarFile()) {
            String jarConnectionEntryName = jarConnection.getEntryName();
            if (!jarConnectionEntryName.endsWith("/")) {
                jarConnectionEntryName += "/";
            }

            /**
             * Iterate all entries in the jar file.
             */
            for (Enumeration<JarEntry> e = jarFile.entries(); e.hasMoreElements();) {
                JarEntry jarEntry = e.nextElement();
                String jarEntryName = jarEntry.getName();

                /**
                 * Extract files only if they match the path.
                 */
                if (jarEntryName.startsWith(jarConnectionEntryName)) {
                    String filename = jarConnectionEntryName + jarEntryName.substring(jarConnectionEntryName.length());
                    File targetFile = new File(destPath, filename);

                    if (jarEntry.isDirectory()) {
                        targetFile.mkdirs();
                    } else {
                        if (!targetFile.exists() || targetFile.length() != jarEntry.getSize()) {
                            try (InputStream is = jarFile.getInputStream(jarEntry);
                                    OutputStream out = FileUtils.openOutputStream(targetFile)) {
                                IOUtils.copy(is, out);
                            }
                        }
                    }
                }
            }
        } catch (IOException e) {
            System.err.println(e.getMessage());            
        }
    }
}