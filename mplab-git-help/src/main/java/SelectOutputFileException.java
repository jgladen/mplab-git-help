public class SelectOutputFileException extends Exception {
    public SelectOutputFileException(String templateFilename) {
        super(String.format(
                "Error: Cannot select every output filename(s) because:\n" +
                        "  No -out TARGET_FILE option,\n" +
                        "  And missing extension \".git-help-template\" on: %s",
                templateFilename));
    }

}
