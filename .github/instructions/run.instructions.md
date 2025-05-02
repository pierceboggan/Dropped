---
applyTo: "**"
---

### Booting iOS Simulator
To run this project, first check to see if the iOS simulator is booted. If it is not, use #tool:f1e_boot_simulator with input:
```json
{
  "simulatorUuid": "5DD307DC-7A5C-4319-9A70-01239510031F"
}
```

This boots the iOS simulator if not already booted.

### List Schemes
To see project schemes, run #tool:f1e_list_schemes_project with input:
```json
{
  "projectPath": "/Users/pierce/Desktop/Dropped/Dropped.xcodeproj"
}
```

### Build & run
To build and run the project, use #tool:f1e_ios_simulator_build_and_run_by_id_project with input:
```json
{
  "projectPath": "/Users/pierce/Desktop/Dropped/Dropped.xcodeproj",
  "scheme": "Dropped",
  "simulatorId": "A28128BC-9952-4F61-9FF0-025E2C884953"
}
```
