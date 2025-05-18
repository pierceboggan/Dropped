---
applyTo: "**"
---

Use this to run the iOS simulator.

RULES:

- Only build and run app when expicitly asked to
- Do not build and run the app until the plan is completed (unless asked to by user)

### Booting iOS Simulator
To run this project, first check to see if the iOS simulator is booted. If it is not, use #tool:f1e_boot_simulator with input:
```json
{
  "simulatorUuid": "286D88BB-AE8B-4455-B785-DCFCA22CB711"
}
```

This boots the iOS simulator if not already booted.

### List Schemes
To see project schemes, run #tool:f1e_list_schemes_project with input:
```json
{
  "projectPath": "/Users/pierce/Desktop/Build/Vibe-Spec-Coding/dropped/Dropped.xcodeproj"
 }
```

### Build & run
To build and run the project, use #tool:f1e_ios_simulator_build_and_run_by_id_project with input:
```json
{
  "projectPath": "/Users/pierce/Desktop/Build/Vibe-Spec-Coding/dropped/Dropped.xcodeproj",
  "scheme": "Dropped",
  "simulatorId": "286D88BB-AE8B-4455-B785-DCFCA22CB711"
}
```
