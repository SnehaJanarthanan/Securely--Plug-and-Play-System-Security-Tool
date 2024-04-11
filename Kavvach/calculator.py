from math import ceil

def calculate_cvss_base_score(av, ac, pr, ui, s, c, i, a):
    # Define weights and impact scores
    weights = {
        'av': {'N': 0.85, 'A': 0.62, 'L': 0.55, 'P': 0.2},
        'ac': {'L': 0.77, 'H': 0.44},
        'pr': {'N': 0.85, 'L': 0.62, 'H': 0.27},
        'ui': {'N': 0.85, 'R': 0.62},
        's': {'U': 6.42, 'C': 7.52},
        'c': {'N': 0, 'L': 0.22, 'H': 0.56},
        'i': {'N': 0, 'L': 0.22, 'H': 0.56},
        'a': {'N': 0, 'L': 0.22, 'H': 0.56}
    }

    # Calculate the base score
    exploitability = 8.22 * weights['av'][av] * weights['ac'][ac] * weights['pr'][pr] * weights['ui'][ui]
    impact = 1 - ((1 - weights['c'][c]) * (1 - weights['i'][i]) * (1 - weights['a'][a]))
    
    if s == 'U':
        impact_score = 6.42 * impact
    else:
        impact_score = 7.52 * (impact - 0.029) - 3.25 * (impact - 0.02)**15
    
    base_score = min(ceil(impact_score + exploitability), 10)
    return base_score

def classify_severity(score):
    if score >= 9.0:
        return "Severe"
    elif score >= 7.0:
        return "High"
    elif score >= 4.0:
        return "Medium"
    else:
        return "Low"

# User inputs
av = input("Attack Vector (N/A/L/P): ")
ac = input("Attack Complexity (L/H): ")
pr = input("Privileges Required (N/L/H): ")
ui = input("User Interaction (N/R): ")
s = input("Scope (U/C): ")
c = input("Confidentiality (N/L/H): ")
i = input("Integrity (N/L/H): ")
a = input("Availability (N/L/H): ")

# Calculate and display the CVSS base score
base_score = calculate_cvss_base_score(av, ac, pr, ui, s, c, i, a)
severity = classify_severity(base_score)

# Generate the vector string
vector_string = f"CVSS:3.1/AV:{av}/AC:{ac}/PR:{pr}/UI:{ui}/S:{s}/C:{c}/I:{i}/A:{a}"

print(f"CVSS Base Score: {base_score}")
print(f"Severity: {severity}")
print(f"Vector String: {vector_string}")

