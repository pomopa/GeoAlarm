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

You should set up Firebase Auth, Firestore and Storgae on the Firebase console and add them through the XCode dependencies manager. 

The rules you must configure through the Firebase console for Firebase Storage are:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    match /profile_images/{fileName} {
      allow read, write: if request.auth != null
                         && fileName.matches(request.auth.uid + "\\..+");
    }
  }
}
```

The rules you must configure through the Firebase console for Firebase Firestore are:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Each user can access only their own data
    match /users/{userId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;

      match /alarms/{alarmId} {
        allow read, write: if request.auth != null
                           && request.auth.uid == userId;
      }
    }
  }
}
```

### API keys setup
For the project you will need your own API key from openweather, once obtained create a `APIs.plist` file and insert the key-value pair for the correct functioning of the project. The key must be "OPENWEATHER_API_KEY".

---

## 📸 Demo Screenshots
Below are some preview images showcasing the main pages of the application.
