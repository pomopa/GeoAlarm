# ⏰ GeoAlarm
## Mobile Devices Programming - La Salle BCN

## 👥 Authors
### Pol Monné
[![GitHub](https://img.shields.io/badge/GitHub-pomopa-181717?style=flat&logo=github)](https://github.com/pomopa)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Profile-0A66C2?style=flat&logo=linkedin)](https://www.linkedin.com/in/polmonneparera/)

### Pau Casé
[![GitHub](https://img.shields.io/badge/GitHub-paucase4-181717?style=flat&logo=github)](https://github.com/paucase4)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Profile-0A66C2?style=flat&logo=linkedin)](https://www.linkedin.com/in/pau-case-barrera/)
  
---

## 🧠 Project Description
This repository showcases the final project of the Mobile Devices Programming subject. It implements a geolocation based alarm system that allows the user to dynamically set alarms 
that will activate based on their geographical coordinates.

---

## 📑 Table of Contents

1. [Project Motivation](#-project-motivation)
2. [How to Start the Project](#how-to-start-the-project)
3. [Project Dependencies](#project-dependencies)
4. [Demo Screenshots](#-demo-screenshots)

---

## 🚀 Project Motivation

During the first years of our college experience, we both commuted to campus by bus, the fastest available option. Each trip took around an hour and a half, adding up to nearly three hours of commuting every day. Combined with classes starting as early as 8:00 AM, this schedule made our days extremely demanding.

Our only practical solution was to sleep during the bus ride, usually starting around 6:00 AM. While this worked in theory, it came with a major problem: we never knew the exact time the bus would arrive at our destination. Traffic conditions, delays, and route variability made setting a traditional time-based alarm unreliable and stressful.

This challenge led us to rethink the concept of alarms altogether. Instead of triggering an alarm at a specific **time**, why not trigger it at a specific **place**?

From this idea, **GeoAlarm** was born, an alarm system based on geographic location rather than time, ensuring you wake up exactly when you arrive, no matter how long the journey takes.

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
For the project you will need your own API key from [openweather](https://openweathermap.org/api), once obtained create an `APIs.plist` file and insert the key-value pair for the correct functioning of the project. The key must be "OPENWEATHER_API_KEY", and the value associated must be your obtained api key.

---

## Project Dependencies

### 🔗 Alamofire
A powerful and elegant HTTP networking library used to handle all network requests, API communication, and response validation in a clean and maintainable way.

- Simplifies REST API integration
- Provides built-in request validation and response handling
- Improves code readability and networking reliability

### 🔥 Firebase
Firebase is used as the backend infrastructure, providing real-time services and secure cloud-based features.

- User authentication and session management
- Cloud data storage and synchronization
- Database managment.

### ⌨️ IQKeyboardManagerSwift
IQKeyboardManagerSwift is used to automatically manage keyboard interactions across the app.

- Prevents the keyboard from covering input fields
- Handles keyboard dismissal gracefully
- Eliminates the need for manual keyboard handling logic
- Improves overall user experience and UI consistency

---

## 📸 Demo Screenshots
Below are some preview images showcasing the main pages of the application.
