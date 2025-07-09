# CSI_Project ( HOSPITALITY MANEGEMENT SYSTEM )

# 🏨 Hospitality Management System - SQL Server

This project implements a basic **Hospitality Management System** using **SQL Server**, showcasing a relational database schema along with stored procedures for hotel room reservations, billing, and availability checking.

---

## 📁 Project Structure

This SQL script contains:
- Table creation for **Users**, **Hotels**, **Rooms**, **Reservations**, and **Bills**
- Stored Procedures for:
  - User Registration
  - Hotel Registration
  - Room Registration
  - Room Availability Check
  - Making a Reservation
  - Bill Generation
- Sample data for:
  - 50 users
  - 5 hotels
  - 10 rooms per hotel (50 total)
  - 5 sample reservations
- Queries to:
  - Check room availability
  - View newly registered rooms

---

## 🧱 Database Schema

### 1. Users
| Column       | Type           | Description          |
|--------------|----------------|----------------------|
| user_id      | INT (PK)       | Auto-increment ID    |
| username     | NVARCHAR(100)  | Unique login         |
| password     | NVARCHAR(100)  | User password        |
| email        | NVARCHAR(100)  | Optional user email  |

---

### 2. Hotels
| Column    | Type           | Description          |
|-----------|----------------|----------------------|
| hotel_id  | INT (PK)       | Auto-increment ID    |
| name      | NVARCHAR(255)  | Hotel name           |
| location  | NVARCHAR(255)  | Hotel location       |

---

### 3. Rooms
| Column          | Type             | Description                  |
|-----------------|------------------|------------------------------|
| room_id         | INT (PK)         | Auto-increment ID            |
| hotel_id        | INT (FK)         | Reference to Hotels table    |
| room_number     | NVARCHAR(50)     | Room identifier              |
| room_type       | NVARCHAR(50)     | Deluxe, Standard, Suite, etc |
| price_per_night | DECIMAL(10,2)    | Rate for one night stay      |
| created_at      | DATETIME         | Timestamp for registration   |

---

### 4. Reservations
| Column       | Type        | Description                |
|--------------|-------------|----------------------------|
| reservation_id | INT (PK)  | Auto-increment ID          |
| user_id      | INT (FK)    | Refers to a user           |
| room_id      | INT (FK)    | Refers to a room           |
| check_in     | DATE        | Start date of stay         |
| check_out    | DATE        | End date of stay           |

---

### 5. Bills
| Column        | Type           | Description               |
|---------------|----------------|---------------------------|
| bill_id       | INT (PK)       | Auto-increment ID         |
| reservation_id| INT (FK)       | Reservation reference     |
| amount        | DECIMAL(10,2)  | Total charge              |
| generated_on  | DATE           | Bill generation date      |

---

## ⚙️ Stored Procedures

### 1. `RegisterUser`
Registers a new user with username and password.

### 2. `RegisterHotel`
Adds a new hotel to the system.

### 3. `RegisterRoom`
Registers a room under a specific hotel.

### 4. `CheckRoomAvailability`
Checks if a room in a hotel is available for a given date range.

### 5. `MakeReservation`
Books a room if it is not already reserved for overlapping dates.

### 6. `GenerateBill`
Calculates the bill based on duration and room rate.

---

## 📊 Sample Data Inserted

- **50 Users**: `user1` to `user50`
- **5 Hotels**: Hyderabad, Goa, Manali, Mumbai, Udaipur
- **10 Rooms per Hotel**: Assigned types based on modulo logic
- **5 Sample Reservations**: For test dates in July 2025

---

## 🔎 Useful Queries

### ✅ Check Room Availability
Check if rooms in a hotel are booked or available for a specific date range.

```sql
DECLARE @HotelName NVARCHAR(100) = 'Hotel Paradise';
DECLARE @CheckIn DATE = '2025-07-14';
DECLARE @CheckOut DATE = '2025-07-17';

-- Availability status per room
SELECT 
    r.room_id,
    r.room_number,
    r.room_type,
    r.price_per_night,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM Reservations res
            WHERE res.room_id = r.room_id
            AND res.check_in < @CheckOut
            AND res.check_out > @CheckIn
        )
        THEN 'Booked'
        ELSE 'Available'
    END AS availability_status
FROM Rooms r
JOIN Hotels h ON r.hotel_id = h.hotel_id
WHERE h.name = @HotelName
ORDER BY availability_status, r.room_number;


### 🆕 View Newly Registered Rooms

SELECT 
    r.room_id,
    r.room_number,
    r.room_type,
    r.price_per_night,
    h.name AS hotel_name,
    r.created_at,
    CASE 
        WHEN r.created_at >= DATEADD(DAY, -7, GETDATE()) THEN '🆕 Newly Registered'
        ELSE 'Old Room'
    END AS room_status
FROM Rooms r
JOIN Hotels h ON r.hotel_id = h.hotel_id
ORDER BY r.created_at ASC;
