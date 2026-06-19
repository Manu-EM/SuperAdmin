# Tally SuperAdmin App

## 📖 Project Overview
The **Tally SuperAdmin App** is a centralized administrative dashboard built with Flutter. It is designed for "Super Admins" to manage multiple, separate client environments. Instead of logging into each client's system individually, administrators can use this app to oversee multiple client databases (hosted on Supabase), manage Tally companies associated with those clients, and maintain strict audit logs of all administrative actions.

## 🚀 Key Features

### 1. Multi-Tenant Client Management
*   **Centralized Control:** Add and manage multiple client accounts from a single dashboard.
*   **Dynamic Database Switching:** Connects to a primary SuperAdmin database while dynamically establishing connections to individual client Supabase instances using their specific URLs and Anon Keys.
*   **Client Status:** Toggle client accounts as active or inactive.

### 2. Tally Company Management
*   **Company Overview:** View all Tally companies associated with a specific client account.
*   **Access Control:** Enable or disable access to specific Tally companies on the fly.
*   **Caching:** Caches client company data in the primary SuperAdmin database for rapid querying and access.

### 3. Comprehensive Audit Logging
*   **Action Tracking:** Every administrative action (like toggling a company's active status) is recorded.
*   **Detailed Logs:** Captures the Admin User's name, the affected Client Account, the specific Company, the action taken, and the old/new values.
*   **Accountability:** Provides a transparent history of who changed what and when.

### 4. Security & Authentication
*   **Admin Auth:** Secure login for administrators using Supabase Authentication.
*   **Persistent Sessions:** Keeps administrators securely logged in across app restarts using local storage.

### 5. UI/UX
*   **Theme Support:** Built-in Light and Dark mode toggling.
*   **Modern Interface:** Clean, Riverpod-driven reactive UI.

---

## 🛠️ Technology Stack

### **Frontend**
*   **Framework:** [Flutter](https://flutter.dev/) (Dart) - *Cross-platform support (Android, iOS, Windows, Web).*
*   **State Management:** [Riverpod](https://riverpod.dev/) (`flutter_riverpod`) - *For robust, scalable, and reactive state management.*
*   **Theming & UI:** Material Design with `cupertino_icons`.

### **Backend (BaaS)**
*   **Service:** [Supabase](https://supabase.com/)
*   **Database:** PostgreSQL (managed by Supabase)
*   **Authentication:** Supabase Auth

### **Key Packages**
*   `supabase_flutter`: For interacting with the Supabase API.
*   `shared_preferences`: For local session persistence and caching auth tokens.
*   `intl`: For formatting dates and timestamps in the Audit Logs.

---

## 📂 Project Structure (Key Components)

*   **`lib/models/`**: Data classes like `AdminUser`, `ClientAccount`, `TallyCompany`, and `AuditLogEntry`.
*   **`lib/screens/`**: UI Views including `HomeScreen`, `LoginScreen`, `AddClientScreen`, and `AuditLogScreen`.
*   **`lib/providers/`**: Riverpod state providers for Authentication, Companies, Audit Logs, and Theming.
*   **`lib/services/`**:
    *   `super_admin_service.dart`: Manages connection to the central SuperAdmin Supabase project.
    *   `multi_supabase_service.dart`: Handles dynamic connections to individual client Supabase projects.

---

## ⚙️ Setup & Installation

1.  **Clone the repository:**
    ```bash
    git clone <your-private-repo-url>
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Environment Configuration:**
    Ensure you configure your Supabase URL and Anon Key in `lib/config/super_admin_config.dart`.
4.  **Run the app:**
    ```bash
    flutter run
    ```
