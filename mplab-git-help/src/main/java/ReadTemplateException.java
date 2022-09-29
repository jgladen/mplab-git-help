public class ReadTemplateException extends Exception {
    public ReadTemplateException(String source) {
        super(String.format("Cannot read source template file: %s", source));
    }
}
