import tkinter as tk
from tkinter import ttk, filedialog
import subprocess
import shutil
import platform
import psutil
import socket

def get_platform_info():
    system_details = {
        "Operating System": platform.system(),
        "Version": platform.release(),
        "Architecture": platform.machine(),
        "Processor": platform.processor(),
    }
    return system_details

def get_memory_info():
    memory = psutil.virtual_memory()
    system_details = {
        "Total Memory": f"{memory.total / (1024 ** 3):.2f} GB",
        "Available Memory": f"{memory.available / (1024 ** 3):.2f} GB",
        "Used Memory": f"{memory.used / (1024 ** 3):.2f} GB",
    }
    return system_details

def get_cpu_info():
    cpu_count = psutil.cpu_count()
    cpu_usage = psutil.cpu_percent(interval=1)
    system_details = {
        "CPU Count": cpu_count,
        "CPU Usage": f"{cpu_usage}%",
    }
    return system_details

def get_network_info():
    interfaces = psutil.net_if_addrs()
    network_details = {}
    for interface, details in interfaces.items():
        for addr in details:
            if addr.family == socket.AF_INET:  # Check for IPv4 family
                network_details[f"{interface} Address"] = addr.address
                network_details[f"{interface} Netmask"] = addr.netmask
    return network_details

def update_card_details(canvas, details):
    canvas.delete("all")  # Clear existing content on the canvas
    for idx, (key, value) in enumerate(details.items()):
        text = f"{key}: {value}"
        canvas.create_text(10, 30 + (idx * 20), anchor=tk.W, text=text, font=("Arial", 10))

def button1_clicked():
    print("Button 1 clicked")
    # Disable Button 1 after being clicked
    button1.config(state=tk.DISABLED)
    # Enable Button 2 after two minutes
    root.after(120000, enable_button2)
    run_scan()

def run_scan():
    python_command = "python"
    script_file = "runexefile.py"
    try:
        subprocess.run([python_command, script_file], shell=True)
        print(f"File running successfully")
    except subprocess.CalledProcessError as e:
        print(f"Error running")

def download_file():
    source_path = r"C:\Users\snehj\Hackathons\Kavach\WinPEAS\outputpdf.pdf"
    
    # Open file dialog to choose destination directory
    destination_path = filedialog.askdirectory()

    if destination_path:
        try:
            shutil.copy(source_path, destination_path)
            print(f"File downloaded successfully to: {destination_path}")
        except Exception as e:
            print(f"Error occurred while downloading: {e}")

def enable_button2():
    button2.config(state=tk.NORMAL)
    button2.configure(style="TButton")

def button2_clicked():
    print("Button 2 clicked")
    download_file()
    # Grey out Button 2 after being clicked
    grey_out_button2()

def grey_out_button2():
    # Disable Button 2 and change its style to "Disabled.TButton"
    button2.config(state=tk.DISABLED)
    button2.configure(style="Disabled.TButton")

    # Enable Button 2 and revert its style after two minutes
    root.after(120000, enable_button2)
    root.after(120000, revert_button2_style)

def revert_button2_style():
    button2.config(state=tk.NORMAL)
    button2.configure(style="TButton")
    # Enable Button 2 and revert its style after two minutes
    root.after(120000, enable_button2)
    root.after(120000, revert_button2_style)

# Create the main tkinter window
root = tk.Tk()
root.title("Modern GUI with Cards and Buttons")
# root.configure(bg="red")  # Set the background color of root window

# Custom Style
style = ttk.Style()

# Create a custom theme for the buttons
style.theme_create("modern", parent="alt", settings={
    "TButton": {
        "configure": {"padding": 10, "relief": "flat", "foreground": "white", "background": "#4CAF50"},
        "map": {"background": [("active", "#45a049")]}
    },
    "Disabled.TButton": {
        "configure": {"background": "gray"}
    }
})

style.theme_use("modern")

# Create a frame for the header bar
header_frame = ttk.Frame(root, height=60, padding=(5, 5, 5, 0))
header_frame.pack(fill=tk.X)

# Create a frame to hold the rectangular cards and buttons
frame = ttk.Frame(root)
frame.pack(pady=20, padx=20, fill=tk.BOTH, expand=True)  # Fill the available space

# Create four canvas widgets for the cards
canvas1 = tk.Canvas(frame, bg="#FAF9F6", width=150, height=100)
canvas1.grid(row=0, column=0, padx=10, pady=10, sticky=tk.NSEW)

canvas2 = tk.Canvas(frame, bg="#FAF9F6", width=150, height=100)
canvas2.grid(row=0, column=1, padx=10, pady=10, sticky=tk.NSEW)

canvas3 = tk.Canvas(frame, bg="#FAF9F6", width=150, height=100)
canvas3.grid(row=1, column=0, padx=10, pady=10, sticky=tk.NSEW)

canvas4 = tk.Canvas(frame, bg="#FAF9F6", width=150, height=100)
canvas4.grid(row=1, column=1, padx=10, pady=10, sticky=tk.NSEW)

# Create two buttons and add them to the frame
button1 = ttk.Button(frame, text="Button 1", command=lambda: [button1_clicked(), grey_out_button2()])
button1.grid(row=2, column=0, padx=10, pady=10, sticky=tk.NSEW)

button2 = ttk.Button(frame, text="Button 2", command=button2_clicked, state=tk.DISABLED)
button2.grid(row=2, column=1, padx=10, pady=10, sticky=tk.NSEW)

# Update card details with platform information
platform_info = get_platform_info()
update_card_details(canvas1, platform_info)

# Update card details with system memory information
memory_info = get_memory_info()
update_card_details(canvas2, memory_info)

# Update card details with CPU information
cpu_info = get_cpu_info()
update_card_details(canvas3, cpu_info)

# Update card details with network information
network_info = get_network_info()
update_card_details(canvas4, network_info)

# Make the buttons wider by setting column weights
frame.grid_columnconfigure(0, weight=1)
frame.grid_columnconfigure(1, weight=1)

# Make the GUI responsive
root.grid_rowconfigure(0, weight=0)  # Header row should not expand
root.grid_rowconfigure(1, weight=1)  # Content row should expand
root.grid_rowconfigure(2, weight=1)  # Extra row for buttons

frame.grid_rowconfigure(0, weight=1)
frame.grid_rowconfigure(1, weight=1)
frame.grid_columnconfigure(0, weight=1)
frame.grid_columnconfigure(1, weight=1)

# Start the tkinter main loop
root.mainloop()