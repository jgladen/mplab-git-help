package org.loepg.mplab.git.help;

import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.attribute.FileTime;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.HashSet;
import java.util.Iterator;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.eclipse.jgit.api.Git;
import org.eclipse.jgit.api.Status;
import org.eclipse.jgit.lib.Repository;
import org.eclipse.jgit.storage.file.FileRepositoryBuilder;

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
    System.err.println("Usage: java -cp mplab-git-help.jar StoreHex PATH_TO_HEX_FILE");
    System.err.println(" ----8<----- in Makefile try: --------");
    System.err.println(".build-post: .build-impl");
    System.err.println(
        "     ${MP_JAVA_PATH}java -cp git-help.jar org.loepg.mplab.git.help.StoreHex \"${CND_ARTIFACT_PATH_${CONF}}\"");
    System.err.println(" ----8<----- in Makefile try: --------");
    System.exit(-2);
  }

  public static void main(String[] args) throws Exception {

    if (args.length != 1) {
      usage();
    }

    String type_image = System.getenv("TYPE_IMAGE");
    System.out.printf("mplab-git-help: TYPE_IMAGE: \"%s\"\n", type_image);

    if (type_image != null && type_image.equals("DEBUG_RUN")) {
      System.out.println("mplab-git-help: skipping debug build");
      System.exit(0);
    }

    System.out.println("Standby");

    FileRepositoryBuilder repositoryBuilder = new FileRepositoryBuilder();
    Repository repository = null;
    try {
      repository = repositoryBuilder
          .readEnvironment() // scan environment GIT_* variables
          .findGitDir() // scan up the file system tree
          .setMustExist(true)
          .build();
    } catch (java.lang.IllegalArgumentException e) {
      System.out.println("mplab-git-help StoreHex: Can't find git repository!! Did you git INIT it yet?");
      System.exit(-1);
    }

    if (repository.getDirectory() == null) {
      System.out.println("mplab-git-help: Could Not Find git Repo");
      System.exit(-1);
    }

    Git git = new Git(repository);

    Status status = git.status().call();

    String describe =null ;
    
    try {
      describe= git.describe()
          .setTags(true)
          .setLong(true)
          .setAbbrev(7)
          .setAlways(true)
          .call();
    }catch(org.eclipse.jgit.api.errors.RefNotFoundException e){
      System.out.println("mplab-git-help StoreHex: Can't any git History!! Did you COMMIT yet?");
      System.exit(-1);      
    }
    
    // take tag if you got it
    // include in tag -count unless it's -0 (on tag)
    // drop the -g or -
    // revision hash is 7 hexidecimal digits
    Pattern reDesribe = Pattern.compile("^(.*?)(?:-0)?(?:-g?)?([0-9a-f]{7})");

    Matcher matchDescribe = reDesribe.matcher(describe);

    String tagVersion = "ERR";
    String revision = "ERR";
    String destinationFolder = ARTIFACT_EXPERIMENT_PATH;

    if (matchDescribe.matches()) {
      tagVersion = matchDescribe.group(1).length() == 0 ? "No version" : matchDescribe.group(1);
      revision = matchDescribe.group(2);
      System.out.printf("describe: %s\n", describe);
    }

    if (status.isClean()) {
      revision = String.format("rev:%s", revision);
      destinationFolder = ARTIFACT_COMMIT_PATH;
    } else {

      HashSet<String> status_paths = new HashSet<String>();
      status_paths.addAll(status.getUntracked());
      status_paths.addAll(status.getUncommittedChanges());
      status_paths.addAll(status.getModified());

      Instant latest_mtime = null;
      String latest_file = "";

      Iterator<String> ciFilepath = status_paths.iterator();
      while (ciFilepath.hasNext()) {
        String filename = ciFilepath.next();
        Path filepath = Paths.get(filename);

        if (Files.exists(filepath, LinkOption.NOFOLLOW_LINKS)) {
          FileTime fileTime = Files.getLastModifiedTime(filepath);
          Instant mtime = fileTime.toInstant();

          if (latest_mtime == null || latest_mtime.compareTo(mtime) < 0) {
            latest_mtime = mtime;
            latest_file = filename;
          }
          System.out.printf("file: %s %s \n", fileTime, filename);
        } else {
          System.out.printf("missing file: %s \n", filename);

        }

      }

      if (latest_mtime != null) {

        LocalDateTime localDateTime = latest_mtime.atZone(ZoneId.systemDefault()).toLocalDateTime();

        int hour = localDateTime.getHour();
        int minute = localDateTime.getMinute();
        int second = localDateTime.getSecond();

        int dayMinute = hour * 60 + minute;
        int hexSecond = Math.floorDiv(second * 16, 60);

        String latest_hex = String.format("%03X%01X", dayMinute, hexSecond);

        System.out.printf("Last File Modified: %s\n", latest_file);
        System.out.printf("Modified Time:%02d:%02d:%02d, minute of day:0x%03X (%d), 1/16 minute: 0x%01X (%d) => 0x%s\n",
            hour, minute, second, dayMinute, dayMinute, hexSecond, hexSecond, latest_hex);

        revision = String.format("X:%s_%s", revision, latest_hex);
      } else {
        revision = String.format("X:%s_XXXX", revision);
      }

    }

    Pattern reBadPath = Pattern.compile("[<>:\",/\\|?*]");
    tagVersion = reBadPath.matcher(tagVersion).replaceAll("_").strip();
    revision = reBadPath.matcher(revision).replaceAll("_").strip();

    String safe_file_name = String.format("%s, %s.hex", tagVersion, revision);

    System.out.printf("source:%s\ndest:%s/%s\n", args[0], destinationFolder, safe_file_name);

    git.close();
  }
}
