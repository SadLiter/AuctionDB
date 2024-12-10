-- Создание базы данных (если необходимо)
-- CREATE DATABASE AuctionDB;
-- GO
-- USE AuctionDB;
-- GO

-- 1. Создание таблиц

-- Таблица для участников аукциона (клиенты)
CREATE TABLE Clients (
    ClientID INT PRIMARY KEY IDENTITY(1,1),
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Email VARCHAR(150) UNIQUE NOT NULL,
    Phone VARCHAR(20)
);
GO

-- Таблица для способов оплаты
CREATE TABLE PaymentMethods (
    PaymentMethodID INT PRIMARY KEY IDENTITY(1,1),
    MethodName VARCHAR(100) UNIQUE NOT NULL
);
GO

-- Таблица для аукционов
CREATE TABLE Auctions (
    AuctionID INT PRIMARY KEY IDENTITY(1,1),
    AuctionName VARCHAR(200) NOT NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NOT NULL,
    StartPrice DECIMAL(18,2) NOT NULL,
    MaxBid DECIMAL(18,2) DEFAULT 0,
    AuctionStatus VARCHAR(50) CHECK (AuctionStatus IN ('Ожидается', 'В процессе', 'Завершено')) NOT NULL
);
GO

-- Таблица для транзакций (платежей)
CREATE TABLE Transactions (
    TransactionID INT PRIMARY KEY IDENTITY(1,1),
    AuctionID INT NOT NULL,
    ClientID INT NOT NULL,
    PaymentMethodID INT NOT NULL,
    TransactionDate DATETIME DEFAULT GETDATE(),
    Amount DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (AuctionID) REFERENCES Auctions(AuctionID),
    FOREIGN KEY (ClientID) REFERENCES Clients(ClientID),
    FOREIGN KEY (PaymentMethodID) REFERENCES PaymentMethods(PaymentMethodID)
);
GO

-- Таблица для ставок на аукционе
CREATE TABLE Bids (
    BidID INT PRIMARY KEY IDENTITY(1,1),
    AuctionID INT NOT NULL,
    ClientID INT NOT NULL,
    BidAmount DECIMAL(18,2) NOT NULL,
    BidTime DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (AuctionID) REFERENCES Auctions(AuctionID),
    FOREIGN KEY (ClientID) REFERENCES Clients(ClientID)
);
GO

-- Таблица для истории аукционов (для хранения результатов аукционов)
CREATE TABLE AuctionHistory (
    HistoryID INT PRIMARY KEY IDENTITY(1,1),
    AuctionID INT NOT NULL,
    FinalBid DECIMAL(18,2) NOT NULL,
    WinnerClientID INT NOT NULL,
    CloseDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (AuctionID) REFERENCES Auctions(AuctionID),
    FOREIGN KEY (WinnerClientID) REFERENCES Clients(ClientID)
);
GO

-- Таблица для сотрудников компании
CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY IDENTITY(1,1),
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Role VARCHAR(100) NOT NULL, -- Например: менеджер, администратор
    HireDate DATETIME DEFAULT GETDATE()
);
GO

-- Таблица для списка наблюдения за аукционами
CREATE TABLE Watchlist (
    WatchlistID INT PRIMARY KEY IDENTITY(1,1),
    ClientID INT NOT NULL,
    AuctionID INT NOT NULL,
    WatchDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (ClientID) REFERENCES Clients(ClientID),
    FOREIGN KEY (AuctionID) REFERENCES Auctions(AuctionID),
    UNIQUE (ClientID, AuctionID)
);
GO

-- Таблица для рекламы аукционов
CREATE TABLE Advertisements (
    AdvertisementID INT PRIMARY KEY IDENTITY(1,1),
    AuctionID INT NOT NULL,
    AdvertisementDate DATETIME DEFAULT GETDATE(),
    Platform VARCHAR(100) NOT NULL, -- Например: соцсети, телевидение
    FOREIGN KEY (AuctionID) REFERENCES Auctions(AuctionID)
);
GO

-- Таблица для клиентских отзывов о аукционах
CREATE TABLE Reviews (
    ReviewID INT PRIMARY KEY IDENTITY(1,1),
    ClientID INT NOT NULL,
    AuctionID INT NOT NULL,
    Rating INT CHECK (Rating BETWEEN 1 AND 5) NOT NULL,
    ReviewText TEXT,
    ReviewDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (ClientID) REFERENCES Clients(ClientID),
    FOREIGN KEY (AuctionID) REFERENCES Auctions(AuctionID)
);
GO

-- 2. Создание процедур

-- Процедура для регистрации клиента
CREATE PROCEDURE RegisterClient
    @FirstName VARCHAR(100),
    @LastName VARCHAR(100),
    @Email VARCHAR(150),
    @Phone VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    -- Проверка, существует ли клиент с таким Email
    IF EXISTS (SELECT 1 FROM Clients WHERE Email = @Email)
    BEGIN
        RAISERROR('Клиент с таким email уже существует.', 16, 1);
        RETURN;
    END

    -- Вставка нового клиента
    INSERT INTO Clients (FirstName, LastName, Email, Phone)
    VALUES (@FirstName, @LastName, @Email, @Phone);
END;
GO

-- Процедура для создания нового аукциона
CREATE PROCEDURE CreateAuction
    @AuctionName VARCHAR(200),
    @StartDate DATETIME,
    @EndDate DATETIME,
    @StartPrice DECIMAL(18,2),
    @AuctionStatus VARCHAR(50) = 'Ожидается' -- Устанавливаем статус по умолчанию как 'Ожидается'
AS
BEGIN
    SET NOCOUNT ON;

    -- Вставка нового аукциона
    INSERT INTO Auctions (AuctionName, StartDate, EndDate, StartPrice, AuctionStatus)
    VALUES (@AuctionName, @StartDate, @EndDate, @StartPrice, @AuctionStatus);

    -- Автоматически переводим аукцион в статус 'В процессе', если текущая дата больше или равна дате старта
    IF @StartDate <= GETDATE()
    BEGIN
        UPDATE Auctions
        SET AuctionStatus = 'В процессе'
        WHERE AuctionName = @AuctionName AND AuctionStatus = 'Ожидается';
    END
END;
GO

-- Процедура для подачи ставки
CREATE PROCEDURE PlaceBid
    @AuctionID INT,
    @ClientID INT,
    @BidAmount DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;

    -- Проверка, что аукцион существует и активен
    IF NOT EXISTS (
        SELECT 1 FROM Auctions
        WHERE AuctionID = @AuctionID AND AuctionStatus = 'В процессе'
    )
    BEGIN
        RAISERROR('Аукцион не существует или не активен для ставок.', 16, 1);
        RETURN;
    END

    -- Проверка, что ставка выше текущей максимальной
    DECLARE @CurrentMax DECIMAL(18,2);
    SELECT @CurrentMax = MaxBid FROM Auctions WHERE AuctionID = @AuctionID;

    IF @BidAmount > @CurrentMax
    BEGIN
        INSERT INTO Bids (AuctionID, ClientID, BidAmount)
        VALUES (@AuctionID, @ClientID, @BidAmount);
    END
    ELSE
    BEGIN
        RAISERROR('Ставка должна быть выше текущей максимальной.', 16, 1);
    END
END;
GO

-- Процедура для завершения аукциона
CREATE PROCEDURE CloseAuction
    @AuctionID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Обновляем статус аукциона на 'Завершено'
    UPDATE Auctions
    SET AuctionStatus = 'Завершено'
    WHERE AuctionID = @AuctionID;
END;
GO

-- 3. Создание функций

-- Функция для получения текущей максимальной ставки на аукционе
CREATE FUNCTION dbo.GetMaxBid (@AuctionID INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @MaxBid DECIMAL(18,2);

    SELECT @MaxBid = MAX(BidAmount)
    FROM Bids
    WHERE AuctionID = @AuctionID;

    RETURN ISNULL(@MaxBid, 0);
END;
GO

-- 4. Создание триггеров

-- Триггер для обновления максимальной ставки на аукционе
CREATE TRIGGER trg_UpdateMaxBid
ON Bids
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AuctionID INT;
    DECLARE @NewBidAmount DECIMAL(18,2);

    SELECT TOP 1 @AuctionID = AuctionID, @NewBidAmount = BidAmount
    FROM inserted
    ORDER BY BidTime DESC;

    -- Обновляем MaxBid, если новая ставка выше текущей
    UPDATE Auctions
    SET MaxBid = @NewBidAmount
    WHERE AuctionID = @AuctionID AND @NewBidAmount > MaxBid;
END;
GO

-- Триггер для записи истории аукциона при его завершении
CREATE TRIGGER trg_InsertAuctionHistory
ON Auctions
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AuctionID INT;
    DECLARE @FinalBid DECIMAL(18,2);
    DECLARE @WinnerClientID INT;
    DECLARE @AuctionStatus VARCHAR(50);

    SELECT TOP 1 @AuctionID = AuctionID, @AuctionStatus = AuctionStatus
    FROM inserted;

    IF @AuctionStatus = 'Завершено'
    BEGIN
        SELECT TOP 1 @FinalBid = BidAmount, @WinnerClientID = ClientID
        FROM Bids
        WHERE AuctionID = @AuctionID
        ORDER BY BidAmount DESC, BidTime ASC;

        INSERT INTO AuctionHistory (AuctionID, FinalBid, WinnerClientID, CloseDate)
        VALUES (@AuctionID, @FinalBid, @WinnerClientID, GETDATE());
    END
END;
GO
