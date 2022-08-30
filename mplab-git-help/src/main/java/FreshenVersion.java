
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.eclipse.jgit.api.errors.GitAPIException;

public class FreshenVersion {

    private static Pattern reIntepolation = Pattern
            .compile("%%|%\\{(\\s*[^\\[}]+)\\s*(?:\\[\\s*(\\d+)\\s*(:\\s*(\\d+)\\s*)?\\])?}");

    private static CommandLine parseArgs(String[] args) {
        final Options options = new Options();
        options.addOption("?", "help", false, "print this message");
        options.addOption("c", "center", false, "center version/revision with padding");
        options.addOption("f", "force", false, "force output file without checking if needed.");
        options.addOption("o", "out", true, "output file: defaults to version.c");
        options.addOption("p", "pad", true, "pad character or chacter escape: \" \" or \"\\0\"");
        options.addOption("R", "revision", true, "padded width of revision");
        options.addOption("r", "right", false, "right justify version/revision with padding");
        options.addOption("V", "version", true, "padded width of version");

        CommandLineParser parser = new DefaultParser();

        try {
            CommandLine line = parser.parse(options, args);
            if (!line.hasOption("help"))
                return line;
        } catch (ParseException e) {
            System.out.println("Could not parse options: " + e.getMessage());
        }

        HelpFormatter formatter = new HelpFormatter();
        formatter.printHelp("CLITester", options);

        System.exit(-1);
        return null;
    }

    /**
     * pads value to size applying justification from opt
     * 
     * @param sizeOption pad to size: opt[SizeOption]
     * @param value      string to pad
     * @param opt
     * @return padded/truncated String
     */
    private static String pad(String sizeOption, String value, CommandLine opt) {

        if (!opt.hasOption(sizeOption)) {
            return value;
        }

        int size = Integer.parseUnsignedInt(opt.getOptionValue(sizeOption));
        int nPad = size - value.length();
        if (nPad <= 0) {
            // field is full, force left justification
            return value.substring(0, size);
        }

        String pad = opt.getOptionValue("pad", " ");

        if (opt.hasOption("center")) {
            int nLeftPad = nPad >> 1;
            return pad.repeat(nLeftPad) + value + pad.repeat(nPad - nLeftPad);
        }

        if (opt.hasOption("right")) {
            return pad.repeat(nPad) + value;
        }

        return value + pad.repeat(nPad);

    }

    private static String applyReplacements(
            String source,
            String template,
            HashMap<String, String> replacements,
            String padCharSeq) throws InvalidTemplateVariable {

        Matcher intepolations = FreshenVersion.reIntepolation.matcher(template);
        StringBuilder contentBuilder = new StringBuilder();

        while (intepolations.find()) {
            String variableName = intepolations.group(1);
            String index1 = intepolations.group(2);
            String range = intepolations.group(3);
            String index2 = intepolations.group(4);
            String replaceWith = "%";
            int start;
            int stop;

            if (variableName != null) {
                if (!replacements.containsKey(variableName)) {
                    throw new InvalidTemplateVariable(source, variableName);
                }
                replaceWith = replacements.get(variableName);
            }

            start = 0;
            stop = replaceWith.length();

            if (range != null) {
                if (index1 != null) {
                    start = Integer.parseInt(index1);
                }
                if (index2 != null) {
                    stop = Integer.parseInt(index2);
                }

            } else if (index1 != null) {
                start = Integer.parseInt(index1);
                stop = start + 1;
            }

            int nPad = 0;

            if (stop < start) {
                stop = start;
            }

            if (stop > replaceWith.length()) {
                nPad = stop - replaceWith.length();
                stop = replaceWith.length();
            }

            if (start > replaceWith.length()) {
                nPad -= start - replaceWith.length();
                start = replaceWith.length();
            }

            replaceWith = replaceWith.substring(start, stop) + padCharSeq.repeat(nPad);

            intepolations.appendReplacement(contentBuilder, Matcher.quoteReplacement(replaceWith));

        }
        intepolations.appendTail(contentBuilder);

        return contentBuilder.toString();

    }

    private static void writeTemplatesToFiles(
            String[] sourceFiles,
            String outputFile,
            String version,
            String revision,
            boolean forceNewContent,
            String padCharSeq) throws InvalidTemplateVariable, ReadTemplateException, WriteOutputFileException {

        HashMap<String, String> replacements = new HashMap<>();

        replacements.put("warning", "*** DO NOT EDIT *** Generated by mplab.git.help.FreshenVersion");
        replacements.put("version", version);
        replacements.put("V", version);
        replacements.put("revision", revision);
        replacements.put("R", revision);

        String template = null;
        // String source;

        String originalContent = null;
        String newContent = null;

        Path outputPath = Path.of(outputFile);

        replacements.put("file", outputFile);

        if (!forceNewContent) {
            try {
                originalContent = Files.readString(outputPath);
            } catch (IOException e) {
                System.out.printf("Warning: can't read output file: \"%s\"\n", outputPath);
                forceNewContent = true;
            }
        }

        if (sourceFiles.length == 0) {

            String source = "FreshenVersion built-in template";
            replacements.put("source", source);

            template = String.join("\r\n",

                    "// %{warning}",
                    "// File: %{file}",
                    "// template: %{source}",
                    "// see: https://github.com/jgladen/mplab-git-help",
                    "",
                    "#include \"version.h\"",
                    "",
                    "const char __attribute__((section(\"version\"))) GIT_VERSION[32] = \"%{version}\";",
                    "const char __attribute__((section(\"version\"))) GIT_REVISION[32] = \"%{revision}\";",
                    "// %{warning}",
                    "");

            newContent = FreshenVersion.applyReplacements(source, template, replacements, padCharSeq);

        } else {
            newContent = "";
            for (String source : sourceFiles) {
                replacements.put("source", source);
                Path templatePath = Path.of(source);

                try {
                    template = Files.readString(templatePath);
                } catch (IOException e) {
                    throw new ReadTemplateException(source);
                }

                newContent += FreshenVersion.applyReplacements(source, template, replacements, padCharSeq);
            }

        }

        if (forceNewContent || !newContent.equals(originalContent)) {
            System.out.printf("writing new: %s\n", outputPath);
            try {
                Files.writeString(outputPath, newContent);
            } catch (IOException e) {
                throw new WriteOutputFileException(outputFile);
            }
        } else {
            System.out.printf("checked: %s\n", outputPath);
        }

    }

    public static void main(String[] args) {
        try {

            CommandLine opt = FreshenVersion.parseArgs(args);

            RepoReview repoReview = new RepoReview();

            repoReview.inspect();

            String[] templateFiles = opt.getArgs();

            String version = FreshenVersion.pad("version", repoReview.tagVersion, opt);
            String revision = FreshenVersion.pad("revision", repoReview.revision, opt);

            System.out.printf("version: \"%s\"\n", version);
            System.out.printf("rev: \"%s\"\n", revision);

            if (opt.hasOption("out")) {
                FreshenVersion.writeTemplatesToFiles(
                        templateFiles,
                        opt.getOptionValue("out"),
                        version,
                        revision,
                        opt.hasOption("force"),
                        opt.getOptionValue("pad", " "));
            } else {

                String[] outputFiles = new String[templateFiles.length];

                // Need matching output file name for each input template file
                Pattern reTemplateFilename = Pattern.compile("^(.+)\\.git-help-template$", Pattern.CASE_INSENSITIVE);
                for (int nFile = 0; nFile < outputFiles.length; nFile++) {
                    Matcher m = reTemplateFilename.matcher(templateFiles[nFile]);
                    if (!m.matches()) {
                        throw new SelectOutputFileException(templateFiles[nFile]);
                    }
                    outputFiles[nFile] = m.group(1);
                }

            }

        } catch (
                MissingRepoException
                | NoRepoHistoryException
                | SelectOutputFileException
                | ReadTemplateException
                | InvalidTemplateVariable
                | WriteOutputFileException
                | GitAPIException e) {
            System.err.println("FreshenVersion: " + e.getMessage());
            if (e instanceof MissingRepoException) {
                System.exit(-2);
            } else if (e instanceof NoRepoHistoryException) {
                System.exit(-3);
            } else if (e instanceof SelectOutputFileException) {
                System.exit(-4);
            } else if (e instanceof ReadTemplateException) {
                System.exit(-5);
            } else if (e instanceof InvalidTemplateVariable) {
                System.exit(-6);
            } else if (e instanceof WriteOutputFileException) {
                System.exit(-7);
            } else if (e instanceof GitAPIException) {
                e.printStackTrace();
                System.exit(-9);
            }
        }

    }
}
