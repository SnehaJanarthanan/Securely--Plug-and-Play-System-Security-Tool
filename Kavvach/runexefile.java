import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

public class runexefile {
    public static void main(String[] args) {
        String powerShellCode = "C:\\Users\\snehj\\Downloads\\winPEASx64.exe -s > peasoutput.txt";

        try {
            // Prepare the PowerShell command
            String[] command = { "powershell.exe", "-command", powerShellCode };
            ProcessBuilder processBuilder = new ProcessBuilder(command);

            // Start the process and wait for it to finish
            Process process = processBuilder.start();
            process.waitFor();

            // Read the output of the PowerShell process
            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            String line;
            while ((line = reader.readLine()) != null) {
                System.out.println(line);
            }

            // Read the error output of the PowerShell process
            BufferedReader errorReader = new BufferedReader(new InputStreamReader(process.getErrorStream()));
            while ((line = errorReader.readLine()) != null) {
                System.err.println(line);
            }
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
    }
}
