public class InvalidTemplateVariable extends Exception {
    public InvalidTemplateVariable(String source, String variableName) {
        super(String.format(
                "%s Invalid template varible name \"%s\"", source, variableName));
    }
}
