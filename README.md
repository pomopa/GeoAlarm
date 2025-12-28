# ⏰ GeoAlarm
## Mobile Devices Programming - La Salle BCN

## 👥 Authors
- [Pol Monné](https://github.com/pomopa)
- [Pau Casé](https://github.com/paucase4)
  
---

## 🧠 Project Description
This repository showcases the final project of the Mobile Devices Programming subject. It implements a geolocation based alarm system that allows the user to dynamically set alarms 
that will activate based on their geographical coordinates.

---

## 📑 Table of Contents

1. [How to Start the Project](#how-to-start-the-project)
2. [Demo Screenshots](#-demo-screenshots)

---

## How to Start the Project

### Firebase Setup
1. Create a Firebase project
2. Add an iOS app with bundle ID `LS.GeoAlarm`
3. Download `GoogleService-Info.plist`
4. Add it to the Xcode project root

You should set up Firebase Auth and Storgae on the Firebase console and set add them through the XCode dependencies manager. The rules for Firebase Storage are:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
      match /{allPaths=**} {
        allow read, write: if request.auth != null;
      }
    }
}
```

---

## 📸 Demo Screenshots
Below are some preview images showcasing the main pages of the application.
