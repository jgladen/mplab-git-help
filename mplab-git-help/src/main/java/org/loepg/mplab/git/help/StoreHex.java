package org.loepg.mplab.git.help;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.regex.Pattern;

import org.eclipse.jgit.api.errors.GitAPIException;

/**
 * StoreHex utility for post-build rule in MPLAB X project makefile
 * copies "Artifact" build to a path based on state of MPLAB X project git
 * repository
 */
public class StoreHex {

  static final String ARTIFACT_COMMIT_PATH = "hex/commit";
  static final String ARTIFACT_EXPERIMENT_PATH = "hex/experimental";

  /**
   * 
   */
  static void usage() {
    System.out.println("Usage: java -cp mplab-git-help-v1.jar org.loepg.mplab.git.help.StoreHex PATH_TO_HEX_FILE");
    System.out.println(" ----8<----- in Makefile try: --------");
    System.out.println(".build-post: .build-impl");
    System.out.println("     ${MP_JAVA_PATH}java -cp git-help.jar org.loepg.mplab.git.help.StoreHex \"${CND_ARTIFACT_PATH_${CONF}}\"");
    System.out.println(" ----8<----- in Makefile try: --------");
    System.exit(-2);
  }

  public static void main(String[] args) {

    if (args.length != 1) {
      usage();
    }

    String srcPath = args[0];

    String type_image = System.getenv("TYPE_IMAGE");
    System.out.printf("mplab-git-help StoreHex: TYPE_IMAGE: \"%s\"\n", type_image);

    if (type_image != null && type_image.equals("DEBUG_RUN")) {
      System.out.println("mplab-git-help StoreHex: skipping debug build");
      System.exit(0);
    }

    RepoReview repoReview = new RepoReview();

    try {
      repoReview.inspect();
    } catch (MissingRepoException e) {
      System.out.println(e.getMessage());
      System.exit(-1);
    } catch (NoRepoHistoryException e) {
      System.out.println(e.getMessage());
      System.exit(-2);
    } catch (GitAPIException e) {
      e.printStackTrace();
      System.exit(-9);
    }

    String destinationFolder;

    if (repoReview.clean) {
      destinationFolder = ARTIFACT_COMMIT_PATH;
    } else {
      destinationFolder = ARTIFACT_EXPERIMENT_PATH;
    }

    Pattern reBadPath = Pattern.compile("[<>:\",/\\|?*]");
    String tagVersion = reBadPath.matcher(repoReview.tagVersion).replaceAll("_").strip();
    String revision = reBadPath.matcher(repoReview.revision).replaceAll("_").strip();
    String safe_file_name = String.format("%s, %s.hex", tagVersion, revision);

    System.out.printf("source:%s\ndest:%s/%s\n", srcPath, destinationFolder, safe_file_name);

    File directory = new File(destinationFolder);
    if (!directory.exists()) {
      directory.mkdirs();
    }

    try {

      Path src = Paths.get(srcPath);
      Path dst = Paths.get(destinationFolder, safe_file_name);

      Files.copy(src, dst, StandardCopyOption.COPY_ATTRIBUTES, StandardCopyOption.REPLACE_EXISTING);

    } catch (IOException e) {
      e.printStackTrace();
      System.exit(-1);
    }

  }
}
