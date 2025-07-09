USE HospitalityDB;
GO

-- Drop tables in reverse dependency order
IF OBJECT_ID('Bills', 'U') IS NOT NULL DROP TABLE Bills;
IF OBJECT_ID('Reservations', 'U') IS NOT NULL DROP TABLE Reservations;
IF OBJECT_ID('Rooms', 'U') IS NOT NULL DROP TABLE Rooms;
IF OBJECT_ID('Hotels', 'U') IS NOT NULL DROP TABLE Hotels;
IF OBJECT_ID('Users', 'U') IS NOT NULL DROP TABLE Users;
GO

--USERS
CREATE TABLE Users (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    username NVARCHAR(100) UNIQUE NOT NULL,
    password NVARCHAR(100) NOT NULL
);
GO

--HOTELS
CREATE TABLE Hotels (
    hotel_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    location NVARCHAR(255) NOT NULL
);
GO

--ROOMS
CREATE TABLE Rooms (
    room_id INT IDENTITY(1,1) PRIMARY KEY,
    hotel_id INT NOT NULL,
    room_number NVARCHAR(50),
    room_type NVARCHAR(50),
    price_per_night DECIMAL(10,2),
    FOREIGN KEY (hotel_id) REFERENCES Hotels(hotel_id)
);
GO

--RESERVATIONS
CREATE TABLE Reservations (
    reservation_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT,
    room_id INT,
    check_in DATE,
    check_out DATE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (room_id) REFERENCES Rooms(room_id)
);
GO


--BILLS
CREATE TABLE Bills (
    bill_id INT IDENTITY(1,1) PRIMARY KEY,
    reservation_id INT,
    amount DECIMAL(10,2),
    generated_on DATE,
    FOREIGN KEY (reservation_id) REFERENCES Reservations(reservation_id)
);
GO


ALTER TABLE Users ADD email NVARCHAR(100);
GO

USE HospitalityDB;
GO

-- 🔁 Drop all procedures if they exist
IF OBJECT_ID('RegisterUser', 'P') IS NOT NULL DROP PROCEDURE RegisterUser;
IF OBJECT_ID('RegisterHotel', 'P') IS NOT NULL DROP PROCEDURE RegisterHotel;
IF OBJECT_ID('RegisterRoom', 'P') IS NOT NULL DROP PROCEDURE RegisterRoom;
IF OBJECT_ID('CheckRoomAvailability', 'P') IS NOT NULL DROP PROCEDURE CheckRoomAvailability;
IF OBJECT_ID('MakeReservation', 'P') IS NOT NULL DROP PROCEDURE MakeReservation;
IF OBJECT_ID('GenerateBill', 'P') IS NOT NULL DROP PROCEDURE GenerateBill;
GO

-- ✅ RegisterUser
CREATE PROCEDURE RegisterUser
    @Username NVARCHAR(100),
    @Password NVARCHAR(100)
AS
BEGIN
    INSERT INTO Users (username, password)
    VALUES (@Username, @Password);
END;
GO

-- ✅ RegisterHotel
CREATE PROCEDURE RegisterHotel
    @HotelName NVARCHAR(255),
    @Location NVARCHAR(255)
AS
BEGIN
    INSERT INTO Hotels (name, location)
    VALUES (@HotelName, @Location);
END;
GO

-- ✅ RegisterRoom
CREATE PROCEDURE RegisterRoom
    @HotelId INT,
    @RoomNumber NVARCHAR(50),
    @RoomType NVARCHAR(50),
    @PricePerNight DECIMAL(10,2)
AS
BEGIN
    INSERT INTO Rooms (hotel_id, room_number, room_type, price_per_night)
    VALUES (@HotelId, @RoomNumber, @RoomType, @PricePerNight);
END;
GO

-- ✅ CheckRoomAvailability
CREATE PROCEDURE CheckRoomAvailability
    @HotelId INT,
    @CheckIn DATE,
    @CheckOut DATE
AS
BEGIN
    SELECT * FROM Rooms
    WHERE hotel_id = @HotelId
    AND room_id NOT IN (
        SELECT room_id FROM Reservations
        WHERE (
            check_in < @CheckOut AND
            check_out > @CheckIn
        )
    );
END;
GO

-- ✅ MakeReservation
CREATE PROCEDURE MakeReservation
    @UserId INT,
    @RoomId INT,
    @CheckIn DATE,
    @CheckOut DATE
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM Reservations
        WHERE room_id = @RoomId AND (
            check_in < @CheckOut AND
            check_out > @CheckIn
        )
    )
    BEGIN
        INSERT INTO Reservations (user_id, room_id, check_in, check_out)
        VALUES (@UserId, @RoomId, @CheckIn, @CheckOut);
    END
    ELSE
    BEGIN
        RAISERROR('Room not available for selected dates.', 16, 1);
    END
END;
GO

-- ✅ GenerateBill
CREATE PROCEDURE GenerateBill
    @ReservationId INT
AS
BEGIN
    DECLARE @RoomId INT, @CheckIn DATE, @CheckOut DATE, @Rate DECIMAL(10,2), @Days INT, @Amount DECIMAL(10,2);

    SELECT 
        @RoomId = room_id, 
        @CheckIn = check_in, 
        @CheckOut = check_out
    FROM Reservations
    WHERE reservation_id = @ReservationId;

    SELECT @Rate = price_per_night FROM Rooms WHERE room_id = @RoomId;

    SET @Days = DATEDIFF(DAY, @CheckIn, @CheckOut);
    SET @Amount = @Days * @Rate;

    INSERT INTO Bills (reservation_id, amount, generated_on)
    VALUES (@ReservationId, @Amount, GETDATE());
END;
GO




-- Insert 50 users
DECLARE @i INT = 1;
WHILE @i <= 50
BEGIN
    INSERT INTO Users (username, password)
    VALUES (
        CONCAT('user', @i),
        CONCAT('pass', @i)
    );
    SET @i = @i + 1;
END;

-- Insert 5 hotels
INSERT INTO Hotels (name, location) VALUES 
('Hotel Paradise', 'Hyderabad'),
('Ocean View Resort', 'Goa'),
('Mountain Retreat', 'Manali'),
('City Central Inn', 'Mumbai'),
('Lakeside Hotel', 'Udaipur');

-- Insert 10 rooms per hotel
DECLARE @hotelId INT = 1;
WHILE @hotelId <= 5
BEGIN
    DECLARE @roomNo INT = 1;
    WHILE @roomNo <= 10
    BEGIN
        DECLARE @roomType NVARCHAR(50);

        IF @roomNo % 3 = 0
            SET @roomType = 'Suite';
        ELSE IF @roomNo % 3 = 1
            SET @roomType = 'Deluxe';
        ELSE
            SET @roomType = 'Standard';

        INSERT INTO Rooms (hotel_id, room_number, room_type, price_per_night)
        VALUES (
            @hotelId,
            CONCAT('R', @hotelId, '-', @roomNo),
            @roomType,
            2000 + (@roomNo * 100)
        );

        SET @roomNo = @roomNo + 1;
    END
    SET @hotelId = @hotelId + 1;
END;

-- Let's make reservations for 5 users
INSERT INTO Reservations (user_id, room_id, check_in, check_out) VALUES
(1, 1, '2025-07-10', '2025-07-12'),
(2, 2, '2025-07-11', '2025-07-13'),
(3, 3, '2025-07-15', '2025-07-17'),
(4, 4, '2025-07-18', '2025-07-20'),
(5, 5, '2025-07-12', '2025-07-16');

-- Generate bills for existing reservations
EXEC GenerateBill @ReservationId = 1;
EXEC GenerateBill @ReservationId = 2;
EXEC GenerateBill @ReservationId = 3;
EXEC GenerateBill @ReservationId = 4;
EXEC GenerateBill @ReservationId = 5;


SELECT * FROM Reservations;


-- Query to display the availbility of rooms in required hotel

DECLARE @HotelName NVARCHAR(100) = 'Hotel Paradise';  -- Change to your desired hotel
DECLARE @CheckIn DATE = '2025-07-14';                  -- Desired check-in date
DECLARE @CheckOut DATE = '2025-07-17';                 -- Desired check-out date

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






--- To print the newly registered rooms
ALTER TABLE Rooms
ADD create_at DATETIME DEFAULT GETDATE();


SELECT 
    r.room_id,
    r.room_number,
    r.room_type,
    r.price_per_night,
    h.name AS hotel_name,
    r.create_at,
    CASE 
        WHEN r.create_at >= DATEADD(DAY, -7, GETDATE()) THEN '🆕 Newly Registered'
        ELSE 'Old Room'
    END AS room_status
FROM Rooms r
JOIN Hotels h ON r.hotel_id = h.hotel_id
ORDER BY r.create_at ASC;
