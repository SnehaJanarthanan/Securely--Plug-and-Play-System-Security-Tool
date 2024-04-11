import subprocess

def run_power_shell_script():
    power_shell_code = r'C:\Users\snehj\Downloads\winPEASx64.exe -s > peasoutput1234.txt'

    try:
        # Prepare the PowerShell command
        command = ['powershell.exe', '-command', power_shell_code]

        # Start the process and wait for it to finish
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        stdout, stderr = process.communicate()
        process.wait()

        # Read the output of the PowerShell process
        print(stdout.decode('utf-8'))

        # Read the error output of the PowerShell process
        print(stderr.decode('utf-8'))

    except Exception as e:
        print(str(e))

if __name__ == "__main__":
    run_power_shell_script()
