import java.io.BufferedReader;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

class Peasy2JsonParser {

    // Pattern to identify main section titles
    private static final String TITLE1_PATTERN = "══════════════╣";
    private static final String TITLE2_PATTERN = "╔══════════╣";
    private static final String TITLE3_PATTERN = "══╣";
    private static final String INFO_PATTERN = "╚ ";

    // Final JSON structure
    private static final Map<String, Object> FINAL_JSON = new HashMap<>();
    private static Map<String, Object> C_SECTION = FINAL_JSON;
    private static Map<String, Object> C_MAIN_SECTION = FINAL_JSON;
    private static Map<String, Object> C_2_SECTION = FINAL_JSON;
    private static Map<String, Object> C_3_SECTION = FINAL_JSON;

    private static boolean isSection(String line, String pattern) {
        return line.contains(pattern);
    }

    private static String parseTitle(String line) {
        String[] titleChars = { "═", "╔", "╣", "╚" };
        for (String c : titleChars) {
            line = line.replace(c, "");
        }
        line = line.trim();
        return line;
    }

    private static Map<String, Object> parseColors(String line) {
        Map<String, Object> colorsMap = new HashMap<>();
        List<String> colorCodes = new ArrayList<>();

        // Define the pattern to match color codes
        Pattern colorPattern = Pattern.compile("\u001B\\[3([0-7])m");
        Matcher matcher = colorPattern.matcher(line);

        // Find all color codes in the line and add them to the list
        while (matcher.find()) {
            String colorCode = matcher.group(1);
            colorCodes.add(colorCode);
        }

        // Remove color codes from the line to get clean text
        line = line.replaceAll("\u001B\\[3[0-7]m", "");

        // If color codes are found, add them to the colors map
        if (!colorCodes.isEmpty()) {
            colorsMap.put("color_codes", colorCodes);
        }

        // Add the clean text to the colors map
        colorsMap.put("clean_text", line.trim());

        return colorsMap;
    }

    private static void parseLine(String line) {
        if (line.contains("Cron jobs")) {
            int a = 1;
        }

        if (isSection(line, TITLE1_PATTERN)) {
            String title = parseTitle(line);
            Map<String, Object> section = new HashMap<>();
            section.put("sections", new HashMap<>());
            section.put("lines", new ArrayList<>()); // Use ArrayList to store lines
            section.put("infos", new ArrayList<>()); // Use ArrayList to store infos
            FINAL_JSON.put(title, section);
            C_MAIN_SECTION = section;
            C_SECTION = C_MAIN_SECTION;
        } else if (isSection(line, TITLE2_PATTERN)) {
            String title = parseTitle(line);
            Map<String, Object> section = new HashMap<>();
            section.put("sections", new HashMap<>());
            section.put("lines", new ArrayList<>()); // Use ArrayList to store lines
            section.put("infos", new ArrayList<>()); // Use ArrayList to store infos
            C_MAIN_SECTION.put(title, section);
            C_2_SECTION = section;
            C_SECTION = C_2_SECTION;
        } else if (isSection(line, TITLE3_PATTERN)) {
            String title = parseTitle(line);
            Map<String, Object> section = new HashMap<>();
            section.put("sections", new HashMap<>());
            section.put("lines", new ArrayList<>()); // Use ArrayList to store lines
            section.put("infos", new ArrayList<>()); // Use ArrayList to store infos
            C_2_SECTION.put(title, section);
            C_3_SECTION = section;
            C_SECTION = C_3_SECTION;
        } else if (isSection(line, INFO_PATTERN)) {
            String title = parseTitle(line);
            ((List<String>) C_SECTION.get("infos")).add(title); // Cast the "infos" list
        } else {
            if (C_SECTION == null) {
                return;
            }

            Map<String, Object> lineData = new HashMap<>();
            lineData.put("raw_text", line);
            lineData.put("colors", parseColors(line));
            lineData.put("clean_text", parseTitle(line));
            ((List<Map<String, Object>>) C_SECTION.get("lines")).add(lineData); // Cast the "lines" list
        }
    }

    public static void main(String[] args) {
        if (args.length < 2) {
            System.out.println("Error: Please pass the peas.out file and the path to save the json");
            System.out.println("java Peasy2JsonParser <output_file> <json_file.json>");
            System.exit(1);
        }

        String outputFilePath = args[0];
        String jsonFilePath = args[1];

        try (BufferedReader br = new BufferedReader(new FileReader(outputFilePath))) {
            String line;
            while ((line = br.readLine()) != null) {
                line = line.trim();
                if (!line.isEmpty() && !line.matches(".*\\x1b\\[[^a-zA-Z]+\\dm")) {
                    parseLine(line);
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }

        try (FileWriter writer = new FileWriter(jsonFilePath)) {
            writer.write(new JSONObject(FINAL_JSON).toString());
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
