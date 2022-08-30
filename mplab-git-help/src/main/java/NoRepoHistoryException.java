
public class NoRepoHistoryException extends Exception{
    public NoRepoHistoryException(){
        super("Git Repository does not have and history. Did you forget to Commit?");
    }    
}
