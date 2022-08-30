
public class MissingRepoException extends Exception {
    public MissingRepoException() {
        super("Can't find Git Repository. Did you forget to initilize one?");
    }
}
