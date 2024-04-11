import json
import streamlit as st
import matplotlib.pyplot as plt

def count_word_occurrences(json_file_path, target_word):
    try:
        with open(json_file_path, 'r') as file:
            data = json.load(file)

        # Flatten the JSON data into a string
        json_string = json.dumps(data)

        # Count occurrences of the target word
        word_count = json_string.lower().count(target_word.lower())

        return word_count
    except FileNotFoundError:
        print(f"Error: File '{json_file_path}' not found.")
        return 0
    except json.JSONDecodeError:
        print(f"Error: Invalid JSON format in file '{json_file_path}'.")
        return 0

# Example usage
if __name__ == "__main__":
    json_file_path = "./peas.json"
    words_to_count = ["RED", "GREEN", "MAGENTA", "YELLOW"]

    word_counts = {word: count_word_occurrences(json_file_path, word) for word in words_to_count}

    # Streamlit app
    st.title("Word Occurrences in JSON File")
    st.write(f"File: {json_file_path}")

    # Display the word counts
    st.write("Word Counts:")
    for word, count in word_counts.items():
        st.write(f"{word}: {count}")

    # Create a bar chart
    st.write("Bar Chart:")
    fig, ax = plt.subplots(figsize=(6, 4))  # Adjust the figure size here (width, height)
    ax.bar(word_counts.keys(), word_counts.values(), color=['red', 'green', 'magenta', 'yellow'])
    plt.xlabel("Colors")
    plt.ylabel("Occurrences")
    plt.title("Occurrences of Words in JSON File")

    # Position the graph in one corner
    st.write('Graph:')
    st.pyplot(fig, bbox_inches='tight', pad_inches=0)

    # Optional: Display additional content next to the graph
    st.write("Additional content can be placed here...")
