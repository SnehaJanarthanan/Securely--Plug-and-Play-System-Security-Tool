from math import ceil

def calculate_temporal_score(E, RL, RC):
    base_score = 8.22 * E * RL * RC
    temporal_score = ceil(base_score * 10) / 10
    return temporal_score

def classify_temporal_severity(score):
    if score >= 9.0:
        return "Critical"
    elif score >= 7.0:
        return "High"
    elif score >= 5.0:
        return "Medium"
    else:
        return "Low"

def get_option_input(prompt, options):
    while True:
        user_input = input(prompt).upper()
        if user_input in options:
            return user_input
        else:
            print("Invalid input. Please choose a valid option.")

def main():
    E_options = {'X', 'U', 'P', 'F', 'H'}
    RL_options = {'X', 'O', 'T', 'W', 'U'}
    RC_options = {'X', 'U', 'R', 'C'}

    E = get_option_input("Enter Exploit Code Maturity (X/U/P/F/H): ", E_options)
    RL = get_option_input("Enter Remediation Level (X/O/T/W/U): ", RL_options)
    RC = get_option_input("Enter Report Confidence (X/U/R/C): ", RC_options)

    E = {'X': 1.0, 'U': 0.91, 'P': 0.94, 'F': 0.97, 'H': 1.0}[E]
    RL = {'X': 1.0, 'O': 0.95, 'T': 0.96, 'W': 0.97, 'U': 1.0}[RL]
    RC = {'X': 1.0, 'U': 0.92, 'R': 0.96, 'C': 1.0}[RC]

    temporal_score = calculate_temporal_score(E, RL, RC)
    temporal_severity = classify_temporal_severity(temporal_score)

    print(f"Temporal Score: {temporal_score}")
    print(f"Temporal Severity: {temporal_severity}")

if __name__ == "__main__":
    main()
