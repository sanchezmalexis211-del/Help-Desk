# Help Desk Flutter - System Context & Instructions

## Project Overview
This is a Flutter Help Desk system with a Firebase backend (Auth, Firestore) and Gemini AI integration. The application supports three primary roles: `usuario`, `tecnico`, and `sysadmin`, routing each to their respective dashboard upon login.

## Tech Stack
- **Framework:** Flutter
- **Backend & Database:** Firebase (Auth, Cloud Firestore)
- **AI Integration:** Google Generative AI (Gemini) via `google_generative_ai`
- **Other Packages:** `intl` (for dates in reports)

## Roles and Core Capabilities
- **Usuario:** 
  - View their own tickets (Asignado / Refacción / Resuelto).
  - Create new tickets (includes an "Otro" option with manual description using GeminiService).
  - View technician comments.
- **Técnico:** 
  - Dashboard with 3 tabs: Asignados (to work on), Refacción (waiting for parts), Resueltos (history).
  - Add diagnostics and estimated time.
  - Mark tickets as "Refacción" or "Resuelto".
  - Add and view comments.
- **Sysadmin (Admin):** 
  - Complete visibility of all tickets and totals.
  - Filter by state, technician, and date.
  - Assign and reassign tickets to technicians.
  - Register new users (usuario, tecnico, sysadmin).
  - Manage subcategories (CRUD operations).
  - Generate and export CSV reports.

## Firestore Architecture
1. **`usuarios`** collection (docs: `{uid}`)
   - Fields: `nombre` (string), `email` (string), `rol` ('usuario', 'tecnico', 'sysadmin'), `fechaCreacion` (timestamp), `activo` (boolean).
2. **`tickets`** collection (docs: `{ticketId}`)
   - Fields: `descripcion`, `categoria`, `prioridad` ('Crítica', 'Alta', 'Media', 'Baja'), `estado` ('Asignado', 'Refacción', 'Resuelto'), `usuarioId`, `agenteAsignado` (uid or null), `fechaCreacion`, `notaTecnica`, `tiempoEstimado`.
   - **Subcollection `comentarios`** (docs: `{comentarioId}`)
     - Fields: `texto`, `autorId`, `autorNombre`, `fecha`.
3. **`subcategorias`** collection (docs: `{categoria}`)
   - **Subcollection `items`** (docs: `{itemId}`)
     - Fields: `nombre`, `detalle`, `fechaCreacion`, `activo`.

## Project Directory Structure
- **Auth:**
  - `lib/screens/auth/login_screen.dart`: Authentication exclusively.
  - `lib/screens/auth_wrapper.dart`: Detects role and redirects.
  - `lib/services/auth_service.dart`: Fetches roles (`obtenerRolUsuario`).
- **Dashboards:**
  - `lib/screens/employee/home_screen.dart`: User ticket view.
  - `lib/screens/technician/tech_dashboard.dart`: Tech interface (3 tabs).
  - `lib/screens/admin/admin_dashboard.dart`: Admin master view.
- **Admin Management:**
  - `lib/screens/admin/register_user_screen.dart`: User registration.
  - `lib/screens/admin/subcategory_manager_screen.dart`: Manage categories.
  - `lib/screens/admin/ticket_report_screen.dart`: Interactive table & CSV export.

## UI/UX Standards
- **Ticket States & Colors:**
  - Sin asignar (Gris): No technician assigned.
  - Asignado (Azul): In progress.
  - Refacción (Naranja ⏳): Waiting for a part.
  - Resuelto (Verde ✅): Closed.
- **Priorities & Colors:**
  - Crítica (Rojo 🚨)
  - Alta (Naranja ⚠️)
  - Media (Amarillo 🟡)
  - Baja (Gris 🟢)

## Critical Development Rules
1. **Case Sensitivity:** User roles must be exactly `'usuario'`, `'tecnico'`, or `'sysadmin'`. Do not capitalize them.
2. **Authentication Flow:** `login_screen.dart` strictly authenticates. `AuthWrapper` handles role-based redirection automatically. Always ensure `home: const AuthWrapper()` is set in `main.dart`.
3. **Comments Display:** Comments belong to the `comentarios` subcollection inside a ticket and must be displayed chronologically (oldest first). Ensure `autorNombre` is saved for UI display.
4. **Reassignment Logic:** Admins can reassign a ticket; the ticket changes its `agenteAsignado` but its current status remains intact.
5. **Debugging Guidance:** If dashboards fail to load, always verify the user `uid` exists in the `usuarios` Firestore collection and that the role string matches perfectly.
