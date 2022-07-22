package org.metanorma.utils;

import static org.metanorma.Constants.*;
import org.metanorma.mnconvert;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Comparator;
import java.util.Enumeration;
import java.util.List;
import java.util.Optional;
import java.util.jar.Attributes;
import java.util.jar.Manifest;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.xml.sax.SAXException;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import org.w3c.dom.Element;

/**
 *
 * @author Alexander Dyuzhev
 */
public class Util {
   
    private static final Logger logger = Logger.getLogger(LoggerHelper.LOGGER_NAME);
    
    public static String getAppVersion() {
        String version = "";
        try {
            Enumeration<URL> resources = mnconvert.class.getClassLoader().getResources("META-INF/MANIFEST.MF");
            while (resources.hasMoreElements()) {
                Manifest manifest = new Manifest(resources.nextElement().openStream());
                // check that this is your manifest and do what you need or get the next one
                Attributes attr = manifest.getMainAttributes();
                String mainClass = attr.getValue("Main-Class");
                if(mainClass != null && mainClass.contains("org.metanorma.mnconvert")) {
                    version = manifest.getMainAttributes().getValue("Implementation-Version");
                }
            }
        } catch (IOException ex)  {
            version = "";
        }
        
        return version;
    }
 
    // get file from classpath, resources folder
    public static InputStream getStreamFromResources(ClassLoader classLoader, String fileName) throws IOException {        
        InputStream stream = classLoader.getResourceAsStream(fileName);
        if (stream == null) {
            throw new IOException("Cannot get resource \"" + fileName + "\" from Jar file.");
        }
        return stream;
    }
    
    public static void FlushTempFolder(Path tmpfilepath) {
        if (Files.exists(tmpfilepath)) {
            //Files.deleteIfExists(tmpfilepath);
            try {
                Files.walk(tmpfilepath)
                    .sorted(Comparator.reverseOrder())
                        .map(Path::toFile)
                            .forEach(File::delete);
            } catch (Exception ex) {
                ex.printStackTrace();
            }
        }
    }
    
    public static String getJavaTempDir() {
        return System.getProperty("java.io.tmpdir");
    }    
    
    
    public void callRuby() {
        StringBuilder sb = new StringBuilder();
        try {
            Process process = Runtime.getRuntime().exec("ruby script.rb");
            process.waitFor();

            BufferedReader processIn = new BufferedReader(
                    new InputStreamReader(process.getInputStream()));

            String line;
            while ((line = processIn.readLine()) != null) {
                //System.out.println(line);
                sb.append(line);
            } 
            
        } 
        catch (Exception e) {
            e.printStackTrace();
        }
        
    }
    
    public static boolean isUrlExists(String urlname){
        try {
            HttpURLConnection.setFollowRedirects(false);        
            HttpURLConnection con = (HttpURLConnection) new URL(urlname).openConnection();
            con.setRequestMethod("HEAD");
            return (con.getResponseCode() == HttpURLConnection.HTTP_OK ||
                    con.getResponseCode() == HttpURLConnection.HTTP_MOVED_TEMP);
        }
        catch (Exception e) {
           e.printStackTrace();
           return false;
        }
      }
    
    
    public static String getListStartValue(String type, String label) {
      if (type.isEmpty() || label.isEmpty()) {
          return "";
      }

      label = label.toUpperCase();

      if (type.equals("roman") || type.equals("roman_upper")) {
          //https://www.w3resource.com/java-exercises/math/java-math-exercise-7.php
          int len = label.length();
          label = label + " ";
          int result = 0;
          for (int i = 0; i < len; i++) {
              char ch   = label.charAt(i);
              char next_char = label.charAt(i+1);

              if (ch == 'M') {
                  result += 1000;
              } else if (ch == 'C') {
                  if (next_char == 'M') {
                      result += 900;
                      i++;
                  } else if (next_char == 'D') {
                      result += 400;
                      i++;
                  } else {
                      result += 100;
                  }
              } else if (ch == 'D') {
                  result += 500;
              } else if (ch == 'X') {
                  if (next_char == 'C') {
                      result += 90;
                      i++;
                  } else if (next_char == 'L') {
                      result += 40;
                      i++;
                  } else {
                      result += 10;
                  }
              } else if (ch == 'L') {
                  result += 50;
              } else if (ch == 'I') {
                  if (next_char == 'X') {
                      result += 9;
                      i++;
                  } else if (next_char == 'V') {
                      result += 4;
                      i++;
                  } else {
                      result++;
                  }
              } else { // if (ch == 'V')
                  result += 5;
              }
          }

          return String.valueOf(result);
      }
      else if (type.equals("alphabet") || type.equals("alphabet_upper")) {
          return String.valueOf((int)(label.charAt(0)) - 64);
      }

      return "";
    }
  
    public static void FileCopy (Path source, Path destination) {
        try {
          
            Files.createDirectories(destination.getParent());
            Files.copy(source, destination, StandardCopyOption.REPLACE_EXISTING);
          
        } catch (IOException ex) {
            logger.warning("Can't copy file: " + ex.toString());
        }
    }
  
    public static String getFileExtension(String filename) {
        return Optional.ofNullable(filename)
          .filter(f -> f.contains("."))
          .map(f -> f.substring(filename.lastIndexOf(".") + 1))
          .map(Object::toString)
          .orElse("");
    }
    
    //download remote file to temp folder
    public static String downloadFile(String filepath, Path destinationPath) {
        String outFilename = "";
        logger.log(Level.INFO, "Downloading {0}...", filepath);
        if (!isUrlExists(filepath)) {
            logger.severe(String.format(INPUT_NOT_FOUND, XML_INPUT, filepath));
            return "";
        }
        
        try {
            URL url = new URL(filepath);
        
            String urlFilename = new File(url.getFile()).getName();
            InputStream in = url.openStream();                    

            Path localPath = Paths.get(destinationPath.toString(), urlFilename);
            Files.createDirectories(destinationPath);
            Files.copy(in, localPath, StandardCopyOption.REPLACE_EXISTING);
            outFilename = localPath.toString();
            logger.info("Done!");
        } catch (IOException ex) {
            logger.severe(ex.toString());
        }
        return outFilename;
    }
    
    public static String getInputFormat(String inputXmlFile, boolean... isIgnoreDTD) {
        if (inputXmlFile.toLowerCase().endsWith(".docx")) {
            return "docx";
        } else {
            DocumentBuilderFactory fact = DocumentBuilderFactory.newInstance();
            try {
                if (isIgnoreDTD.length > 0 && isIgnoreDTD[0]) {
                    fact.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);
                }
                DocumentBuilder builder = fact.newDocumentBuilder();
                Document doc;
                
                if (inputXmlFile.toLowerCase().startsWith("http") || inputXmlFile.toLowerCase().startsWith("www.")) {
                    doc = builder.parse(inputXmlFile);
                } else {
                    doc = builder.parse(new FileInputStream(inputXmlFile));
                }
                
                Node node = doc.getDocumentElement();
                String root = node.getNodeName();
                if (root.endsWith("-standard") || root.equals("metanorma-collection")) {
                    return "metanorma";
                } else if (root.equals("rfc"))  {
                    return "rfc";
                } else {
                    return "sts";
                }
            } catch (FileNotFoundException ex) {
                if (ex.toString().toLowerCase().contains(".dtd") && isIgnoreDTD.length == 0) {
                    //logger.log(Level.WARNING, "Can''t load external DTD: {0}, internal DTD will be used.", ex.toString());
                    return getInputFormat(inputXmlFile, true);
                } else {
                    logger.warning(ex.toString());
                }
            }
            catch (ParserConfigurationException | SAXException | IOException ex) {
                logger.severe(ex.toString());
            }
        }
        return "";
    }
    
    public static void writeBuffer(StringBuilder sbBuffer, String outputFile) throws IOException {
        try (BufferedWriter writer = Files.newBufferedWriter(Paths.get(outputFile))) {
            writer.write(sbBuffer.toString());
        }
        sbBuffer.setLength(0);
    }
    

    public static void unzipFile(Path zipPath, String destPath, List<String> fileList) {
        try {
            File destDir = new File(destPath);
            byte[] buffer = new byte[1024];
            ZipInputStream zis = new ZipInputStream(new FileInputStream(zipPath.toString()));
            ZipEntry zipEntry = zis.getNextEntry();
            while (zipEntry != null) {
                if(!zipEntry.isDirectory()) {
                    String zipEntryName = new File(zipEntry.getName()).getName();
                    if (fileList.contains(zipEntryName)) {
                        File newFile = new File(destDir, zipEntryName);
                        logger.log(Level.INFO, "Extracting file {0}...", newFile.getAbsolutePath());
                        FileOutputStream fos = new FileOutputStream(newFile);
                        int len;
                        while ((len = zis.read(buffer)) > 0) {
                            fos.write(buffer, 0, len);
                        }
                        fos.close();
                    }
                }
                zipEntry = zis.getNextEntry();
            }
            zis.closeEntry();
            zis.close();
        } catch (Exception ex) {
            logger.log(Level.INFO, "Can''t unzip a file: {0}", ex.getMessage());
        }
    }

    // 
    public static String unzipFileToString(Path zipPath, String fileName) {
        String strResult = "";
        try {
            ZipInputStream zis = new ZipInputStream(new FileInputStream(zipPath.toString()));
            ZipEntry zipEntry = zis.getNextEntry();
            while (zipEntry != null) {
                if(!zipEntry.isDirectory()) {
                    String zipEntryName = new File(zipEntry.getName()).getName();
                    if (fileName.equals(zipEntryName)) {
                        
                        // read file into byte array
                        int total = (int) zipEntry.getSize();
                        byte[] bytes = new byte[total];
                        int pos = 0;
                        while (total > 0) {
                            int read = zis.read(bytes, pos, total);
                            if (read == -1) {
                                // end of stream
                                throw new IOException("Unexpected end of stream after " + pos + " bytes for entry " + fileName);
                            }
                            pos += read;
                            total -= read;
                        }
                        
                        strResult = new String(bytes, StandardCharsets.UTF_8);
                        break;
                    }
                }
                zipEntry = zis.getNextEntry();
            }
            zis.closeEntry();
            zis.close();
        } catch (Exception ex) {
            logger.log(Level.INFO, "Can''t unzip a file: {0}", ex.getMessage());
        }
        return strResult;
    }
    
}
