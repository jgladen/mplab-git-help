public class InvalidTemplateVariable extends Exception {
    public InvalidTemplateVariable(String source, int nLine, String variableName) {
        super(String.format(
                "%s:%d Invalid template varible name \"%s\"", source, nLine, variableName
        ));
    }
}
