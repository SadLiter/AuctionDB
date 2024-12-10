-- �������� ���� ������ (���� ����������)
-- CREATE DATABASE AuctionDB;
-- GO
-- USE AuctionDB;
-- GO

-- 1. �������� ������

-- ������� ��� ���������� �������� (�������)
CREATE TABLE Clients (
    ClientID INT PRIMARY KEY IDENTITY(1,1),
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Email VARCHAR(150) UNIQUE NOT NULL,
    Phone VARCHAR(20)
);
GO

-- ������� ��� �������� ������
CREATE TABLE PaymentMethods (
    PaymentMethodID INT PRIMARY KEY IDENTITY(1,1),
    MethodName VARCHAR(100) UNIQUE NOT NULL
);
GO

-- ������� ��� ���������
CREATE TABLE Auctions (
    AuctionID INT PRIMARY KEY IDENTITY(1,1),
    AuctionName VARCHAR(200) NOT NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NOT NULL,
    StartPrice DECIMAL(18,2) NOT NULL,
    MaxBid DECIMAL(18,2) DEFAULT 0,
    AuctionStatus VARCHAR(50) CHECK (AuctionStatus IN ('���������', '� ��������', '���������')) NOT NULL
);
GO

-- ������� ��� ���������� (��������)
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

-- ������� ��� ������ �� ��������
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

-- ������� ��� ������� ��������� (��� �������� ����������� ���������)
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

-- ������� ��� ����������� ��������
CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY IDENTITY(1,1),
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Role VARCHAR(100) NOT NULL, -- ��������: ��������, �������������
    HireDate DATETIME DEFAULT GETDATE()
);
GO

-- ������� ��� ������ ���������� �� ����������
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

-- ������� ��� ������� ���������
CREATE TABLE Advertisements (
    AdvertisementID INT PRIMARY KEY IDENTITY(1,1),
    AuctionID INT NOT NULL,
    AdvertisementDate DATETIME DEFAULT GETDATE(),
    Platform VARCHAR(100) NOT NULL, -- ��������: �������, �����������
    FOREIGN KEY (AuctionID) REFERENCES Auctions(AuctionID)
);
GO

-- ������� ��� ���������� ������� � ���������
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

-- 2. �������� ��������

-- ��������� ��� ����������� �������
CREATE PROCEDURE RegisterClient
    @FirstName VARCHAR(100),
    @LastName VARCHAR(100),
    @Email VARCHAR(150),
    @Phone VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    -- ��������, ���������� �� ������ � ����� Email
    IF EXISTS (SELECT 1 FROM Clients WHERE Email = @Email)
    BEGIN
        RAISERROR('������ � ����� email ��� ����������.', 16, 1);
        RETURN;
    END

    -- ������� ������ �������
    INSERT INTO Clients (FirstName, LastName, Email, Phone)
    VALUES (@FirstName, @LastName, @Email, @Phone);
END;
GO

-- ��������� ��� �������� ������ ��������
CREATE PROCEDURE CreateAuction
    @AuctionName VARCHAR(200),
    @StartDate DATETIME,
    @EndDate DATETIME,
    @StartPrice DECIMAL(18,2),
    @AuctionStatus VARCHAR(50) = '���������' -- ������������� ������ �� ��������� ��� '���������'
AS
BEGIN
    SET NOCOUNT ON;

    -- ������� ������ ��������
    INSERT INTO Auctions (AuctionName, StartDate, EndDate, StartPrice, AuctionStatus)
    VALUES (@AuctionName, @StartDate, @EndDate, @StartPrice, @AuctionStatus);

    -- ������������� ��������� ������� � ������ '� ��������', ���� ������� ���� ������ ��� ����� ���� ������
    IF @StartDate <= GETDATE()
    BEGIN
        UPDATE Auctions
        SET AuctionStatus = '� ��������'
        WHERE AuctionName = @AuctionName AND AuctionStatus = '���������';
    END
END;
GO

-- ��������� ��� ������ ������
CREATE PROCEDURE PlaceBid
    @AuctionID INT,
    @ClientID INT,
    @BidAmount DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;

    -- ��������, ��� ������� ���������� � �������
    IF NOT EXISTS (
        SELECT 1 FROM Auctions
        WHERE AuctionID = @AuctionID AND AuctionStatus = '� ��������'
    )
    BEGIN
        RAISERROR('������� �� ���������� ��� �� ������� ��� ������.', 16, 1);
        RETURN;
    END

    -- ��������, ��� ������ ���� ������� ������������
    DECLARE @CurrentMax DECIMAL(18,2);
    SELECT @CurrentMax = MaxBid FROM Auctions WHERE AuctionID = @AuctionID;

    IF @BidAmount > @CurrentMax
    BEGIN
        INSERT INTO Bids (AuctionID, ClientID, BidAmount)
        VALUES (@AuctionID, @ClientID, @BidAmount);
    END
    ELSE
    BEGIN
        RAISERROR('������ ������ ���� ���� ������� ������������.', 16, 1);
    END
END;
GO

-- ��������� ��� ���������� ��������
CREATE PROCEDURE CloseAuction
    @AuctionID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- ��������� ������ �������� �� '���������'
    UPDATE Auctions
    SET AuctionStatus = '���������'
    WHERE AuctionID = @AuctionID;
END;
GO

-- 3. �������� �������

-- ������� ��� ��������� ������� ������������ ������ �� ��������
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

-- 4. �������� ���������

-- ������� ��� ���������� ������������ ������ �� ��������
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

    -- ��������� MaxBid, ���� ����� ������ ���� �������
    UPDATE Auctions
    SET MaxBid = @NewBidAmount
    WHERE AuctionID = @AuctionID AND @NewBidAmount > MaxBid;
END;
GO

-- ������� ��� ������ ������� �������� ��� ��� ����������
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

    IF @AuctionStatus = '���������'
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
