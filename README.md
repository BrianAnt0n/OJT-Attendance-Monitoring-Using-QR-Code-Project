# OJT Attendance Monitoring Using QR Code

A professional **OJT Project** developed to streamline **attendance monitoring** for a company using **QR code technology**.  
The system leverages **Flutter**, **PHP**, and **MySQL** to provide a cross-platform solution for trainees and administrators.  

---

## 🚀 Live Demo

Try the web demo here:  
👉 [OJT Attendance Monitoring Demo](https://brianant0n.github.io/OJT-Attendance-Monitoring-Using-QR-Code-Project/#/test)

---

## 📖 Overview

This project was created as part of an **On-the-Job Training (OJT)** program to help a company modernize attendance tracking.  

**Core Features:**
- 📱 **Cross-platform interface** (mobile, web) built with Flutter  
- 🔑 **QR code scanning** for quick and accurate attendance logging  
- 💾 **Backend with PHP & MySQL** for storing and validating attendance records  
- 🌐 **Web demo deployment** via GitHub Pages for easy access  
- 🖥️ **Admin & trainee views** for efficient monitoring and management  

---

## 🛠️ Technology Stack

| Layer        | Tools/Frameworks         |
|--------------|---------------------------|
| Frontend     | Flutter (Dart)           |
| Backend      | PHP, MySQL               |
| Deployment   | GitHub Pages (Flutter Web)|
| Optional     | Docker for local testing |

---

## ⚙️ Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)  
- PHP & MySQL (e.g., [XAMPP](https://www.apachefriends.org/) / Laragon)  
- Git  
- (Optional) Docker  

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/BrianAnt0n/OJT-Attendance-Monitoring-Using-QR-Code-Project.git
   cd OJT-Attendance-Monitoring-Using-QR-Code-Project


2. **Run Flutter Web locally**

   ```bash
   flutter pub get
   flutter run -d chrome
   ```

   Or build for web:

   ```bash
   flutter build web
   ```

3. **Setup Backend (PHP & MySQL)**

   * Import the SQL schema into MySQL (see provided `.sql` file).
   * Update DB credentials inside `connection.php` / `db_connect.php`.
   * Place the PHP files in your local server root (e.g., `htdocs/` in XAMPP).

4. **Optional: Dockerized Setup**

   ```bash
   docker build -t ojt-attendance .
   docker run -p 80:80 ojt-attendance
   ```

---

## 📂 Project Structure

```
/lib          -> Flutter codebase
/web          -> Web assets
/php_files    -> PHP backend scripts
/sql          -> Database schema
/android      -> Android support files
/ios          -> iOS support files
Dockerfile
README.md
```

---

## 🔄 Workflow & Deployment

* Updates pushed to the **main branch** automatically trigger a build and deployment via **GitHub Actions**.
* The **Flutter web app** is published to **GitHub Pages** and available through the [Live Demo link](https://brianant0n.github.io/OJT-Attendance-Monitoring-Using-QR-Code-Project/#/test).

---

## 🤝 Contributing

This repository is part of an OJT project. Contributions, ideas, or suggestions for improvements are always welcome.
Feel free to open an **issue** or submit a **pull request**.

---

## 📜 License

This project is open-source and released under the **MIT License**. See the [LICENSE](./LICENSE) file for details.

---

## 👨‍💻 Authors

Developed by:
**BrianAnt0n** – BSIT Student, Quezon City University
📍 Quezon City, Philippines
🔗 [GitHub Profile](https://github.com/BrianAnt0n)

```
