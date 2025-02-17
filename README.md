# Система управления базой данных для аукционов

## Обзор проекта

Этот проект представляет собой **систему управления базой данных** для онлайн-платформы аукционов, разработанную с использованием **Microsoft SQL Server** (или совместимой СУБД). Проект включает создание базы данных с таблицами, хранимыми процедурами, триггерами и представлениями, предназначенными для управления аукционами, пользователями, ставками, транзакциями и рекламой.

## Функциональные возможности

- **Регистрация клиентов**: возможность регистрации новых клиентов на платформе аукционов.
- **Создание аукционов**: администраторы могут создавать новые аукционы, устанавливать стартовые цены и дату окончания.
- **Подача ставок**: пользователи могут делать ставки на аукционы, при этом ставка должна быть выше текущей максимальной.
- **Процесс оплаты**: после завершения аукциона, клиенты могут оплачивать свои транзакции через различные способы оплаты.
- **Отслеживание результатов**: система хранит историю ставок, транзакций и результатов аукционов.
- **Администрирование**: администраторы могут управлять аукционами, обновлять их статус и завершать аукционы.

## Архитектура базы данных

Проект включает следующие компоненты базы данных:

- **Таблицы**: хранят основную информацию о клиентах, аукционах, ставках, транзакциях и т.д.
- **Представления (Views)**: используются для создания отчетов и отображения текущих аукционов, ставок и транзакций.
- **Триггеры (Triggers)**: обеспечивают автоматическое обновление данных, например, обновление максимальной ставки на аукционе или запись истории аукциона.
- **Хранимые процедуры (Stored Procedures)**: выполняют бизнес-логику, например, создание новых аукционов, регистрацию клиентов, обработку ставок и оплату.

### Структура таблиц:

1. **Clients** — хранит информацию о клиентах (имя, фамилия, email, телефон).
2. **Auctions** — хранит информацию о аукционах (название, начальная цена, статус и т.д.).
3. **Bids** — хранит информацию о ставках, сделанных на аукционы.
4. **Transactions** — хранит информацию о транзакциях (платежах) за участие в аукционах.
5. **Employees** — хранит информацию о сотрудниках (например, администраторах).
6. **Watchlist** — хранит данные о том, какие аукционы находятся в списке наблюдения клиентов.
7. **Advertisements** — хранит информацию о рекламе аукционов.
8. **Reviews** — хранит отзывы клиентов о проведенных аукционах.

## Структура проекта

Проект состоит из нескольких частей:

1. **Создание базы данных**: создание всех необходимых таблиц и связей.
2. **Создание триггеров**: триггеры для обновления ставок и записи истории аукционов.
3. **Создание хранимых процедур**: процедуры для регистрации клиентов, подачи ставок, создания аукционов и т.д.
4. **Представления**: для получения отчетов о текущих аукционах, ставках и транзакциях.

## Установка

1. Убедитесь, что у вас установлен **Microsoft SQL Server** или совместимая СУБД.
2. Создайте новую базу данных, если она еще не создана:
   ```sql
   CREATE DATABASE AuctionDB;
   GO
   ```
3. Используйте эту базу данных:
   ```sql
   USE AuctionDB;
   GO
   ```
4. Запустите все SQL-скрипты, представленные в проекте, чтобы создать таблицы, процедуры, триггеры и представления. Все скрипты находятся в одном файле, который вы можете выполнить в SQL Server Management Studio (SSMS).

## Пример использования

### Регистрация нового клиента

```sql
EXEC RegisterClient 
    @FirstName = 'Иван', 
    @LastName = 'Иванов', 
    @Email = 'ivanov@example.com', 
    @Phone = '1234567890';
GO
```

### Создание нового аукциона

```sql
EXEC CreateAuction 
    @AuctionName = 'Аукцион антиквариата', 
    @StartDate = '2024-12-15', 
    @EndDate = '2024-12-20', 
    @StartPrice = 1000.00, 
    @AuctionStatus = 'Ожидается';
GO
```

### Подача ставки

```sql
EXEC PlaceBid 
    @AuctionID = 1, 
    @ClientID = 1, 
    @BidAmount = 1500.00;
GO
```

### Обработка оплаты

```sql
EXEC ProcessTransaction 
    @OrderID = 1, 
    @Amount = 1500.00, 
    @PaymentMethod = 'Кредитная карта';
GO
```

## Триггеры и функции

1. **trg_UpdateMaxBid**: триггер для обновления максимальной ставки на аукционе.
2. **trg_InsertAuctionHistory**: триггер для записи истории аукциона при его завершении.
3. **dbo.GetMaxBid**: функция для получения текущей максимальной ставки на аукционе.
4. **dbo.GetUserBidCount**: функция для подсчета количества ставок пользователя.

## Заключение

Этот проект является примером практического использования базы данных для управления аукционами. В нем реализованы основные бизнес-процессы, такие как регистрация пользователей, создание аукционов, подача ставок и обработка платежей, с использованием стандартных механизмов SQL, таких как таблицы, триггеры, функции и процедуры.