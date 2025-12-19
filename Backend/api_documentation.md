# VST Maarketing CRM — API Documentation

This document lists all APIs implemented for the VST Maarketing CRM backend (Django + DRF). For each endpoint you get: purpose, URL, method, request payload (example), response (example), and permissions.

> **Auth**: All secured endpoints require a valid JWT Bearer `Authorization: Bearer <access_token>` unless otherwise noted.

---

## Table of contents
1. Authentication
2. Users (profile & admin)
3. Cards (service cards)
4. Services (booking flow)
5. OTP & Completion (staff flow)
6. Service Entries (work logs)
7. Feedback
8. Attendance
9. Reports & Admin utilities

---

## 1. Authentication

### POST `/api/auth/login/`
- **Purpose:** Obtain JWT tokens. Supports SimpleJWT `TokenObtainPairView` (username/password). If you implement phone+OTP login, create a custom view.
- **Method:** POST
- **Permission:** AllowAny
- **Request (example):**
```json
{ "phone": "+9198765xxxx", "password": "secret" }
```
- **Response (example):**
```json
{ "access": "<jwt.access.token>", "refresh": "<jwt.refresh.token>" }
```

### POST `/api/auth/token/register/`
- **Purpose:** Obtain JWT tokens. Supports SimpleJWT `TokenObtainPairView` (username/password). If you implement phone+OTP login, create a custom view.
- **Method:** POST
- **Permission:** AllowAny
- **Request (example):**
```json
{ "name": "name", "phone": "+9198765xxxx", "password": "secret" }
```
- **Response (example):**
```json
{ "access": "<jwt.access.token>", "refresh": "<jwt.refresh.token>" }
```

### POST `/api/auth/token/refresh/`
- **Purpose:** Refresh access token
- **Method:** POST
- **Permission:** AllowAny
- **Request:** `{ "refresh": "<refresh_token>" }`
- **Response:** `{ "access": "<new_access_token>" }`

---

## 2. Users (profile & admin)

### GET `/api/auth/me/`
- **Purpose:** Get current user's profile
- **Method:** GET
- **Permission:** Authenticated
- **Response (example):**
```json
{
  "id": 12,
  "name": "Ramesh",
  "phone": "+9198xxxx",
  "role": "customer",
  "region": "rajapalayam",
  "address": "12 MG Road"
}
```


### PATCH `/api/auth/me/`
- **Purpose:** Update current user's profile
- **Method:** PATCH
- **Permission:** Authenticated
- **Request (example):**
```json
{ "name": "Ramesh Kumar", "address": "Updated address" }
```

### GET /api/auth/admin/users/ [?phone=][?role=]

- **Purpose:** Get all users
- **Method:** GET
- **Permission:** Admin
- **Response (example):**

```json
[
  {
    "id": 1,
    "name": "Admin",
    "phone": "+911111111111",
    "role": "admin"
  },
  {
    "id": 12,
    "name": "Ramesh Kumar",
    "phone": "+9198xxxx",
    "role": "customer"
  }
]
```

### GET /api/auth/admin/users/{id}/

- **Purpose:** Get user by ID
- **Method:** GET
- **Permission:** Admin
- **Response (example):**

```json
{
  "id": 12,
  "name": "Ramesh Kumar",
  "phone": "+9198xxxx",
  "role": "customer",
  "region": "rajapalayam",
  "address": "Updated address"
}
```

### PATCH /api/auth/admin/users/{id}/update/

- **Purpose:** Update user details by admin
- **Method:** PATCH
- **Permission:** Admin
- **Request (example):**

```json
{
  "name": "Ramesh Admin Edited",
  "role": "worker",
  "region": "Madurai"
}
```
- **Response (example):**
```json
{
  "id": 12,
  "name": "Ramesh Admin Edited",
  "phone": "+9198xxxx",
  "role": "worker",
  "region": "Madurai",
  "address": "Updated address"
}
```

### POST /api/auth/admin/users/{id}/change-password/

- **Purpose:** Change user password (admin reset)
- **Method:** POST
- **Permission:** Admin
- **Request (example):**

```json
{
  "new_password": "NewStrongPassword@123"
}
```
- **Response (example):**
```json
{
  "detail": "Password changed successfully"
}
```

## 3. Cards (service cards)

### GET `/api/crm/cards/`
- **Purpose:** List cards
- **Method:** GET
- **Permission:** Authenticated (role-aware)
- **Query params:** `?customer=123`, `?region=rajapalayam`, `?card_type=normal`, `?search=`


### POST `/api/crm/cards/`
- **Purpose:** Create a card (Admin; optionally allow customer self-create)
- **Method:** POST
- **Permission:** Admin (or customer if `CRM_ALLOW_CUSTOMER_CARD_CREATE=True` and customer==owner)
- **Request (example):**
```json
{
  "model": "AquaPure X1",
  "customer": 123,
  "customer_name": "Ramesh",
  "card_type": "normal",
  "region": "rajapalayam",
  "address": "12 MG Road",
  "city": "Rajapalayam",
  "postal_code": "626117",
  "date_of_installation": "2025-09-15",
  "warranty_start_date": "2025-09-15",
  "warranty_end_date": "2026-09-14"
}
```
- **Response (201):** created card JSON


### GET `/api/crm/cards/{id}/`
- **Purpose:** Card detail (includes or links to service history)
- **Method:** GET
- **Permission:** Owner customer, staff/admin


### PUT/PATCH `/api/crm/cards/{id}/`
- **Purpose:** Update card
- **Method:** PUT/PATCH
- **Permission:** Admin (or owner customer if allowed)


### DELETE `/api/crm/cards/{id}/`
- **Purpose:** Delete card (soft-delete recommended)
- **Method:** DELETE
- **Permission:** Admin

---

## 4. Services (booking flow)

### POST `/api/crm/services/`
- **Purpose:** Customer books a service
- **Method:** POST
- **Permission:** Authenticated (customer)
- **Request (example):**
```json
{
  "card": 101,
  "description": "Not dispensing water",
  "service_type": "auto",   // 'auto' or absent -> server decides free/normal
  "preferred_date": "2025-12-18",
  "preferred_time": "10:00",
  "visit_type": "onsite"
}
```
- **Server behavior:**
  - Validate card ownership
  - Validate preferred datetime (not past, within `CRM_BOOKING_WINDOW_DAYS`)
  - Decide `service_type` = `free` or `normal` using 3-month rule during warranty
  - Create Service with status `pending` (or `scheduled` if auto-assigned)
- **Response (201 example):**
```json
{ "id": 501, "status": "pending", "service_type": "free", "scheduled_at": null, "next_steps":"admin will assign" }
```


### GET `/api/crm/services/`
- **Purpose:** List services (role-aware)
- **Method:** GET
- **Permission:** role-aware (customer/staff/admin)
- **Default ordering:** scheduled_at ASC (NULLs last), created_at ASC
- **Query params:** `?status=assigned&?assigned_to=`, `?card=`, `?from=YYYY-MM-DD&to=`, `?order=created|scheduled`


### GET `/api/crm/services/{id}/`
- **Purpose:** Service detail (includes entries, assigned staff, otp fields)
- **Method:** GET
- **Permission:** Owner customer, assigned staff, admin


### PATCH `/api/crm/services/{id}/`
- **Purpose:** Update service (admin/staff); customers can cancel or reschedule per rules
- **Method:** PATCH
- **Permission:** role-aware


### POST `/api/crm/services/{id}/assign/`
- **Purpose:** Admin assigns staff and optionally sets scheduled_at
- **Method:** POST
- **Permission:** Admin
- **Request (example):** `{ "assigned_to": 55, "scheduled_at": "2025-12-18 }`


### POST `/api/crm/services/{id}/reschedule/`
- **Purpose:** Reschedule (customer owner or admin)
- **Method:** POST
- **Permission:** owner customer or admin
- **Request (example):** `{ "scheduled_at": "2025-12-20 }`


### POST `/api/crm/services/{id}/cancel/`
- **Purpose:** Cancel booking
- **Method:** POST
- **Permission:** owner customer or admin

---

## 5. OTP & Completion (staff flow)

### POST `/api/crm/services/{id}/request_otp/`
- **Purpose:** Staff requests OTP to verify completion — backend generates OTP, stores hash & expiry, sends SMS to customer
- **Method:** POST
- **Permission:** assigned staff (or admin)
- **Response:** `{"detail":"otp-sent"}` (do not return OTP in production)


### POST `/api/crm/services/{id}/verify_otp/`
- **Purpose:** Staff verifies OTP and finalizes the service; creates ServiceEntry
- **Method:** POST
- **Permission:** assigned staff
- **Request (example):**
```json
{
  "otp": "4827",
  "work_detail": "Replaced valve, cleaned filter",
  "parts_replaced": [{"code":"P01","qty":1,"price":120.0}],
  "amount_charged": 0.0,
  "next_service_date": "2026-03-15"
}
```
- **Server behavior:** verify OTP (hash+expiry), set status -> `completed`, create ServiceEntry, clear OTP

---

## 6. Service Entries (work logs)

### GET `/api/crm/service-entries/?service=<id>`
- **Purpose:** List entries for a service
- **Method:** GET
- **Permission:** owner customer, assigned staff, admin


### POST `/api/crm/service-entries/`
- **Purpose:** Staff creates a work entry (if OTP optional)
- **Method:** POST
- **Permission:** staff
- **Request (example):**
```json
{ "service":501, "work_detail":"Replaced valve", "parts_replaced":[{"code":"P01","qty":1,"price":120.0}], "amount_charged":50.0 }
```

---

## 7. Feedback

### POST `/api/crm/feedbacks/`
- **Purpose:** Customer submits rating for completed service
- **Method:** POST
- **Permission:** owner customer
- **Request (example):** `{ "service":501, "rating":5, "comments":"Great" }`


### GET `/api/crm/feedbacks/`
- **Purpose:** List feedback (admin/staff see relevant feedbacks; customer sees own)
- **Method:** GET
- **Permission:** role-aware

---

## 8. Attendance

### 1️⃣ GET Attendance List (Admin only)

List attendance for all staff, searchable by date or user.

Endpoint

GET /api/crm/attendance/


Query Params

user=<id>

date=YYYY-MM-DD

status=present|absent

Permission

Admin only

Response

[
  {
    "id": 14,
    "user": 3,
    "date": "2025-12-12",
    "status": "present",
    "marked_by": 1,
    "created_at": "2025-12-12T09:12:00Z"
  }
]

### 2️⃣ Mark Attendance (Admin updates staff availability)

Admin sets staff attendance for a particular date.

Mark Present
POST /api/crm/attendance/mark_present/


Body

{
  "user": 3,
  "date": "2025-12-12"
}


Response

{
  "detail": "Marked present",
  "attendance_id": 14
}

Mark Absent
POST /api/crm/attendance/mark_absent/


Body

{
  "user": 3,
  "date": "2025-12-12"
}


Response

{
  "detail": "Marked absent",
  "attendance_id": 14
}

### 3️⃣ Get Today’s Attendance for Logged-in Staff

Staff does not mark attendance — but can view what admin marked.

GET /api/crm/attendance/me/


Response

{
  "date": "2025-12-12",
  "status": "present"
}


Permission

Staff only

### 4️⃣ Admin Bulk Attendance Update

Mark multiple staff present/absent at once (useful for morning check-in).

POST /api/crm/attendance/bulk/


Body

{
  "date": "2025-12-12",
  "present": [2, 3, 5],
  "absent": [6, 7]
}


Response

{
  "detail": "Bulk update complete",
  "present_marked": 3,
  "absent_marked": 2
}

---

## 9. Reports & Admin utilities

### GET `/api/crm/reports/warranty/?month=YYYY-MM`
- **Purpose:** list cards eligible for free service in the month
- **Method:** GET
- **Permission:** admin


### GET `/api/crm/reports/upcoming-services/?from=&to=`
- **Purpose:** admin view scheduled services
- **Method:** GET
- **Permission:** admin


### POST `/api/crm/autoassign/run/`
- **Purpose:** Trigger auto-assign run (stub) — prefer background Celery task
- **Method:** POST
- **Permission:** admin


### GET `/api/crm/admin/export/services/?from=&to=`
- **Purpose:** Export services CSV
- **Method:** GET
- **Permission:** admin