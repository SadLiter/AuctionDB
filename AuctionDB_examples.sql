-- Пример создания аукциона
EXEC CreateAuction
    @AuctionName = 'Пример Аукциона',
    @StartDate = '2025-12-01 12:00',
    @EndDate = '2026-12-10 18:00',
    @StartPrice = 100.00;
GO

-- Изменение статуса аукциона на 'В процессе' (ручное)
UPDATE Auctions
SET AuctionStatus = 'В процессе'
WHERE AuctionID = 2; -- Замените 1 на ваш ID аукциона
GO

-- Пример добавления клиента
EXEC RegisterClient
    @FirstName = 'Иван', 
    @LastName = 'Иванов', 
    @Email = 'ivanov2@example.com', 
    @Phone = '1234567890';
GO

-- Пример подачи ставки
EXEC PlaceBid
    @AuctionID = 2,
    @ClientID = 1,
    @BidAmount = 151.00;
GO

SELECT *
FROM Auctions