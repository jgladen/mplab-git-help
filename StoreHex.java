
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.attribute.FileTime;
import java.time.format.DateTimeFormatter;
import java.util.Iterator;
import java.util.Set;
import java.util.TimeZone;
import java.util.Calendar;
import java.util.HashSet;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.regex.MatchResult;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.eclipse.jgit.api.Git;
import org.eclipse.jgit.api.Status;
import org.eclipse.jgit.api.StatusCommand;
import org.eclipse.jgit.api.DescribeCommand;

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
    System.err.println("     ${MP_JAVA_PATH}java -cp mplab-git-help.jar StoreHex \"${CND_ARTIFACT_PATH_${CONF}}\"");
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
      System.out.println("mplab-git-help: skipping bebug build");
      System.exit(0);
    }

    System.out.println("Standby");

    File repo = new File("./.git");

    Git git = Git.open(repo);

    Status status = git.status().call();

    String describe = git.describe()
        .setTags(true)
        .setLong(true)
        .setAbbrev(7)
        .setAlways(true)
        .call();

    // take tag if you got it
    // include in tag -count unless it's -0 (on tag)
    // drop the -g or -
    // revision hash is 7 hexidecimal digits
    Pattern reDesribe = Pattern.compile("^(.*?)(?:-0)?(?:-g?)?([0-9a-f]{7})");
    // Pattern reDesribe = Pattern.compile("(.{4})(.*)");

    Matcher matchDescribe = reDesribe.matcher(describe);

    String tagVersion = "ERR";
    String revision = "ERR";

    if (matchDescribe.matches()) {
      tagVersion = matchDescribe.group(0) == null ? "No version" : matchDescribe.group(0);
      revision = String.format("rev:%s", matchDescribe.group(1));
      System.out.printf("describe: %s\n", describe);
    }

    if (status.isClean()) {
      // System.out.printf("Clean: %s.hex", describe);
      revision = String.format("rev:%s", revision);

    } else {

      HashSet<String> status_paths = new HashSet<String>();
      status_paths.addAll(status.getUntracked());
      status_paths.addAll(status.getUncommittedChanges());

      Instant latest_mtime = null;
      String latest_file="";

      Iterator<String> ciFilepath = status_paths.iterator();
      while (ciFilepath.hasNext()) {
        final String filepath = ciFilepath.next();

        FileTime fileTime = Files.getLastModifiedTime(Paths.get(filepath));
        Instant mtime = fileTime.toInstant();

        if (latest_mtime == null || latest_mtime.compareTo(mtime) < 0) {
          latest_mtime = mtime;
          latest_file = filepath;
        }

        // System.out.printf("file: %s %s \n", fileTime, filepath);
      }

      LocalDateTime localDateTime = latest_mtime.atZone(ZoneId.systemDefault()).toLocalDateTime();


      int h,m,s;
      int hour =localDateTime.getHour();
      int minute  =localDateTime.getMinute();
      int second = localDateTime.getSecond();

      int dayMinute = hour*60+minute;
      int hexSecond = Math.floorDiv(second*16,60);
      
            
      String latest_hex = String.format( "%03X%01X", dayMinute,hexSecond);
      
      System.out.printf("Last File Modified: %s\n",latest_file);
      System.out.printf("Modified Time:%02d:%02d:%02d, minute of day:0x%03X (%d), 1/16 minute: 0x%01X (%d) => 0x%s\n",
       hour,minute,second,dayMinute,dayMinute,hexSecond,hexSecond,latest_hex);
      
      revision = String.format("X:%s_%s", revision, latest_hex);

    }

    Pattern reBadPath = Pattern.compile("[<>:\",/\\|?*]");
    tagVersion = reBadPath.matcher(tagVersion).replaceAll("_").strip();
    revision = reBadPath.matcher(revision).replaceAll("_").strip();

    String safe_file_name = String.format("%s, %s.hex", tagVersion, revision);

    System.out.printf("copy: %s to %s \n", args[0], safe_file_name);

    // String tagVersion = "v.001";
    // String revision = "x0x0x0";

  }
}
