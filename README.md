# Restaurant Explorer Nepal

A Flutter app to explore restaurants in Nepal, featuring deep linking and detailed restaurant views.

---

## Requirements

- [Flutter](https://flutter.dev/)
- [Mockoon](https://mockoon.com/) (for local API mocking)

---

## Setup

1. **Clone this repository.**
2. **The `json` folder in the project root contains mock JSON files**  
   These files are used to mock restaurant lists and details.

3. **Start Mockoon and import the provided JSON files:**

   - Open Mockoon.
   - Create a new environment.
   - Import the JSON files from the `json` folder in this repository.
   - Start the Mockoon server.

4. **Update your app's API base URL** (if needed) to point to your local Mockoon server (e.g., `http://localhost:3000`).

---

## Screenshots

### 🔐 Authentication Screens

| Login | Sign Up | Enable Biometric | Native Biometric |
|-------|---------|------------------|------------------|
| ![Login](assets/images/screenshots/auth_login.png) | ![Sign Up](assets/images/screenshots/auth_sign_up.png) | ![Biometric Enable](assets/images/screenshots/auth_biometric_enable_popup.png) | ![Native Biometric](assets/images/screenshots/auth_native_biometric_input.png) |

---

### 🍽️ Explore Screen

| Explore | Explore Search | Sort |
|---------|----------------|------|
| ![Explore](assets/images/screenshots/explore_screen.png) | ![Search](assets/images/screenshots/explore_search_functionality.png) | ![Sort](assets/images/screenshots/explore_sort.png) |

---

### ❤️ Favorites Screen

| Favorites | Sort By |
|-----------|---------|
| ![Favorites](assets/images/screenshots/fav_screen.png) | ![Sort By](assets/images/screenshots/fav_sort_by.png) |

---

### 👤 Account Screen

| Account Main | Change Password | Security |
|--------------|------------------|----------|
| ![Account](assets/images/screenshots/account_screen.png) | ![Change Password](assets/images/screenshots/account_change-password_popup.png) | ![Security](assets/images/screenshots/account_security.png) |

---

### 🗺️ Map View

| Nearby Restaurants Map |
|------------------------|
| ![Map](assets/images/screenshots/maps_for_nearby_restaurant_overview.png) |

---

### 📄 Detail Pages

| Detail Page Top | Detail Page Bottom |
|-----------------|--------------------|
| ![Detail Top](assets/images/screenshots/detail_page_1_top.png) | ![Detail Bottom](assets/images/screenshots/detail_page_2_bottom.png) |

---

## Features

- List restaurants (data from Mockoon JSON).
- View detailed restaurant info.
- Deep link support.

---

## Notes

- The app requires the Mockoon server running with the JSON data provided in the `json` folder to display restaurant lists and details.
- Deep links will navigate directly to restaurant details if the app is running.
