-- ������ �������� ��������
EXEC CreateAuction
    @AuctionName = '������ ��������',
    @StartDate = '2025-12-01 12:00',
    @EndDate = '2026-12-10 18:00',
    @StartPrice = 100.00;
GO

-- ��������� ������� �������� �� '� ��������' (������)
UPDATE Auctions
SET AuctionStatus = '� ��������'
WHERE AuctionID = 2; -- �������� 1 �� ��� ID ��������
GO

-- ������ ���������� �������
EXEC RegisterClient
    @FirstName = '����', 
    @LastName = '������', 
    @Email = 'ivanov2@example.com', 
    @Phone = '1234567890';
GO

-- ������ ������ ������
EXEC PlaceBid
    @AuctionID = 2,
    @ClientID = 1,
    @BidAmount = 151.00;
GO

SELECT *
FROM Auctions