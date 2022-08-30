public class WriteOutputFileException extends Exception {
    public WriteOutputFileException(String outputFile) {
        super(String.format("Failed to open output file for writing: %s\n", outputFile));
    }
}
