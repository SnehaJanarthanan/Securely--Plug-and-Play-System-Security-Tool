import subprocess

def run_winpeas():
    try:
        # Replace 'WinPEAS.ps1' with the full path to WinPEAS.ps1 if it's in a different location
        winpeas_script = 'WinPEAS.ps1'
        powershell_cmd = f"powershell -ExecutionPolicy Bypass -File {winpeas_script}"
        
        # Run PowerShell script using subprocess.Popen
        with subprocess.Popen(powershell_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True) as process:
            stdout, stderr = process.communicate()

            # Check if the process finished successfully
            if process.returncode == 0:
                print("WinPEAS executed successfully. Here is the output:")
                print(stdout)
            else:
                print("Error occurred while running WinPEAS:")
                print(stderr)
    except FileNotFoundError:
        print("WinPEAS script not found. Please make sure you have downloaded it.")
    except Exception as e:
        print("An error occurred:", str(e))

if __name__ == "__main__":
    run_winpeas()
