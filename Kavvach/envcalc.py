from math import ceil

def calculate_environmental_score(impact, exploitability, scope, modified_vector):
    impact_mapping = {'L': 0.1, 'N': 0.0, 'M': 0.5, 'H': 1.0}

    impact_values = {
        'confidentiality': impact_mapping[impact['confidentiality']],
        'integrity': impact_mapping[impact['integrity']],
        'availability': impact_mapping[impact['availability']],
        'modified_confidentiality': impact_mapping[impact['modified_confidentiality']],
        'modified_integrity': impact_mapping[impact['modified_integrity']],
        'modified_availability': impact_mapping[impact['modified_availability']]
    }

    adjusted_impact = min(10, 10.41 * (1 - (1 - impact_values['confidentiality']) * (1 - impact_values['integrity']) * (1 - impact_values['availability'])))
    temporal_score = exploitability * adjusted_impact

    modified_impact = min(10, 10.41 * (1 - (1 - impact_values['modified_confidentiality']) * (1 - impact_values['modified_integrity']) * (1 - impact_values['modified_availability'])))
    adjusted_temporal = modified_impact * modified_vector if scope == 'U' else (temporal_score + 1.08 * (temporal_score - 0.028))

    environmental_score = ceil((adjusted_temporal + exploitability) * 10) / 10
    return environmental_score

def classify_environmental_severity(score):
    if score >= 9.0:
        return "Critical"
    elif score >= 7.0:
        return "High"
    elif score >= 5.0:
        return "Medium"
    else:
        return "Low"

def main():
    impact = {
        'confidentiality': input("Enter Confidentiality Impact (L/N/M/H): ").upper(),
        'integrity': input("Enter Integrity Impact (L/N/M/H): ").upper(),
        'availability': input("Enter Availability Impact (L/N/M/H): ").upper(),
        'modified_confidentiality': input("Enter Modified Confidentiality (L/N/M/H): ").upper(),
        'modified_integrity': input("Enter Modified Integrity (L/N/M/H): ").upper(),
        'modified_availability': input("Enter Modified Availability (L/N/M/H): ").upper()
    }

    exploitability = float(input("Enter Exploitability (0.0 - 1.0): "))
    scope = input("Enter Scope (U/C): ").upper()
    modified_vector = float(input("Enter Modified Attack Vector (0.0 - 1.0): "))

    environmental_score = calculate_environmental_score(impact, exploitability, scope, modified_vector)
    environmental_severity = classify_environmental_severity(environmental_score)

    print(f"Environmental Score: {environmental_score}")
    print(f"Environmental Severity: {environmental_severity}")

if __name__ == "__main__":
    main()
