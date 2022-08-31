

import java.io.IOException;
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
import org.eclipse.jgit.api.errors.GitAPIException;
import org.eclipse.jgit.api.errors.RefNotFoundException;
import org.eclipse.jgit.lib.Repository;
import org.eclipse.jgit.storage.file.FileRepositoryBuilder;

public class RepoReview {

    public boolean clean = false;
    public String tagVersion = "ERR";
    public String revision = "ERR";
    public Instant latest_mtime = null;
    public String latest_file = "";

    public void inspect() throws MissingRepoException, NoRepoHistoryException, GitAPIException {

        this.clean = false;
        this.tagVersion = "ERR";
        this.revision = "ERR";
        this.latest_mtime = null;
        this.latest_file = "";

        FileRepositoryBuilder repositoryBuilder = new FileRepositoryBuilder();
        Repository repository = null;
        try {
            repository = repositoryBuilder
                    .readEnvironment() // scan environment GIT_* variables
                    .findGitDir() // scan up the file system tree
                    .setMustExist(true)
                    .build();
        } catch (IllegalArgumentException e) {
            throw new MissingRepoException();
        } catch (IOException e) {
            // System.err.println("File access problems on folder");
            throw new MissingRepoException();
        }

        if (repository.getDirectory() == null) {
            throw new MissingRepoException();
        }

        Git git = new Git(repository);

        Status status = git.status().call();

        String describe = null;

        try {
            describe = git.describe()
                    .setTags(true)
                    .setLong(true)
                    .setAbbrev(7)
                    .setAlways(true)
                    .call();
        } catch (RefNotFoundException e) {
            git.close();
            throw new NoRepoHistoryException();
        }

        // take tag if you got it
        // include in tag -count unless it's -0 (on tag)
        // drop the -g or -
        // revision hash is 7 hexidecimal digits
        Pattern reDesribe = Pattern.compile("^(.*?)(?:-0)?(?:-g?)?([0-9a-f]{7})");

        Matcher matchDescribe = reDesribe.matcher(describe);

        this.clean = false;

        if (matchDescribe.matches()) {
            tagVersion = matchDescribe.group(1).length() == 0 ? "No version" : matchDescribe.group(1);
            revision = matchDescribe.group(2);
            System.out.printf("describe: %s\n", describe);
        }

        if (status.isClean()) {
            revision = String.format("rev:%s", revision);
            this.clean = true;
        } else {

            HashSet<String> status_paths = new HashSet<String>();
            status_paths.addAll(status.getUntracked());
            status_paths.addAll(status.getUncommittedChanges());
            status_paths.addAll(status.getModified());

            Iterator<String> ciFilepath = status_paths.iterator();
            while (ciFilepath.hasNext()) {
                String filename = ciFilepath.next();
                Path filepath = Paths.get(filename);

                if (Files.exists(filepath, LinkOption.NOFOLLOW_LINKS)) {
                    try {
                        FileTime fileTime = Files.getLastModifiedTime(filepath);
                        Instant mtime = fileTime.toInstant();

                        if (latest_mtime == null || latest_mtime.compareTo(mtime) < 0) {
                            latest_mtime = mtime;
                            latest_file = filename;
                        }
                        // System.out.printf("file: %s %s \n", fileTime, filename);

                    } catch (IOException e) {

                        // TODO: Throw exception?        
                        System.err.printf("File access problems on file: %s", filename);
                    }
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

                // System.out.printf("Last File Modified: %s\n", latest_file);
                // System.out.printf(
                // "Modified Time:%02d:%02d:%02d, minute of day:0x%03X (%d), 1/16 minute: 0x%01X
                // (%d) => 0x%s\n",
                // hour, minute, second, dayMinute, dayMinute, hexSecond, hexSecond,
                // latest_hex);

                revision = String.format("X:%s_%s", revision, latest_hex);
            } else {
                revision = String.format("X:%s_XXXX", revision);
            }

        }

        git.close();

    }

}
