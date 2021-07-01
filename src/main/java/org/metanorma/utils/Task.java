package org.metanorma.utils;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Stream;

/**
 *
 * @author Alexander Dyuzhev
 */
public class Task {
    
    private static final Logger logger = Logger.getLogger(LoggerHelper.LOGGER_NAME);
    
    public static void copyImages(String inputFolder, String imagesFolder, String outputFolder) {
        try {
            if( !inputFolder.equals(outputFolder)) {
                final String taskFilename = "task.copyImages.adoc";
                Path taskFilePath = Paths.get(outputFolder, taskFilename);
                File taskFile = taskFilePath.toFile();
                if (taskFile.exists()) {
                    try (Stream<String> stream = Files.lines(taskFilePath, StandardCharsets.UTF_8)) 
                    {
                        stream.forEach(s -> {
                                if (s.startsWith("copyimage::")) {
                                    try {
                                        String imageFilename = s.split("copyimage::")[1].split("\\[")[0];
                                        Path originalImagePath = Paths.get(inputFolder, imagesFolder, imageFilename);
                                        Path destitanionImagePath = Paths.get(outputFolder, imagesFolder, imageFilename);
                                        Util.FileCopy(originalImagePath, destitanionImagePath);
                                    } catch (Exception ex) {
                                        logger.log(Level.WARNING, "Can''t process image: {0}", ex.toString());
                                    }
                                }
                            }
                        );
                    }
                    catch (IOException e) 
                    {
                        e.printStackTrace();
                    }
                    Files.delete(taskFile.toPath());
                }
            }
        } catch (Exception ex) {
            logger.log(Level.WARNING, "Error on task ''Copy Images'':{0}", ex.toString());
        }
    }
}
