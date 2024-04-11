import json

# Load JSON data from input file
with open("MacPEASjson.json", "r") as input_file:
    data = json.load(input_file)

# Extract "Users Information" section
users_info = data.get("Users Information", {}).get("sections", {}).get("Users", {}).get("lines", [])

# Extract and store the clean_text from each line in the Users Information section
clean_text_list = []
for line in users_info:
    clean_text = line.get("clean_text")
    if clean_text:
        clean_text_list.append(clean_text)

# Print clean_text
for clean_text in clean_text_list:
    print(clean_text)

# Create a new JSON file and store the extracted clean_text data
output_filename = "UserInfoMac.json"
with open(output_filename, "w") as output_file:
    json.dump(clean_text_list, output_file, indent=4)

print(f"Clean text extracted and stored in '{output_filename}'")
