import java.io.*;
import java.util.*;
import java.util.regex.*;

public class WinPEASRunner {

    public static void main(String[] args) {
        runWinPEAS();
    }

    public static void runWinPEAS() {
        try {
            // Replace 'WinPEAS.ps1' with the full path to WinPEAS.ps1 if it's in a
            // different location
            String winpeasScript = "C:\\Users\\snehj\\Hackathons\\Kavach\\WinPEAS\\winPEAS.ps1";
            String powershellCmd = String.format("powershell -ExecutionPolicy Bypass -File %s", winpeasScript);

            // Run PowerShell script using ProcessBuilder
            ProcessBuilder processBuilder = new ProcessBuilder("cmd.exe", "/c", powershellCmd);
            processBuilder.redirectErrorStream(true);
            Process process = processBuilder.start();

            // Read the output from the PowerShell process and save it to a text file
            String outputFilePath = "peas.txt";
            try (InputStream inputStream = process.getInputStream();
                    BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));
                    BufferedWriter writer = new BufferedWriter(new FileWriter(outputFilePath))) {
                String line;
                System.out.println("WinPEAS output:");
                while ((line = reader.readLine()) != null) {
                    System.out.println(line);
                    writer.write(line);
                    writer.newLine();
                }
            }

            // Wait for the process to finish
            int exitCode = process.waitFor();
            if (exitCode == 0) {
                System.out.println("WinPEAS executed successfully.");
            } else {
                System.err.println("Error occurred while running WinPEAS.");
            }

            // Save the output to a text file
            saveOutputToFile(outputFilePath, "output.txt");

            // Parse the output file and convert it to JSON
            String jsonFilePath = "output.json";
            // parseOutputToJson(outputFilePath, jsonFilePath);

        } catch (IOException | InterruptedException e) {
            System.err.println("An error occurred: " + e.getMessage());
        }
    }

    public static void saveOutputToFile(String outputText, String outputFilePath) {
        try (BufferedWriter writer = new BufferedWriter(new FileWriter(outputFilePath))) {
            writer.write(outputText);
            System.out.println("Output saved to: " + outputFilePath);
        } catch (IOException e) {
            System.err.println("An error occurred while saving output to file: " + e.getMessage());
        }
    }

}
