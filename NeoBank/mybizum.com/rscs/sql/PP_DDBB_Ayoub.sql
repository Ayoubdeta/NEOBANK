USE [master]
GO
/****** Object:  Database [PP_DDBB]    Script Date: 19/05/2025 18:45:22 ******/
CREATE DATABASE [PP_DDBB]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'PP_DDBB', FILENAME = N'/var/opt/mssql/data/PP_DDBB.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'PP_DDBB_log', FILENAME = N'/var/opt/mssql/data/PP_DDBB_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO
ALTER DATABASE [PP_DDBB] SET COMPATIBILITY_LEVEL = 160
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [PP_DDBB].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [PP_DDBB] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [PP_DDBB] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [PP_DDBB] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [PP_DDBB] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [PP_DDBB] SET ARITHABORT OFF 
GO
ALTER DATABASE [PP_DDBB] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [PP_DDBB] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [PP_DDBB] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [PP_DDBB] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [PP_DDBB] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [PP_DDBB] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [PP_DDBB] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [PP_DDBB] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [PP_DDBB] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [PP_DDBB] SET  DISABLE_BROKER 
GO
ALTER DATABASE [PP_DDBB] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [PP_DDBB] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [PP_DDBB] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [PP_DDBB] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [PP_DDBB] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [PP_DDBB] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [PP_DDBB] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [PP_DDBB] SET RECOVERY FULL 
GO
ALTER DATABASE [PP_DDBB] SET  MULTI_USER 
GO
ALTER DATABASE [PP_DDBB] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [PP_DDBB] SET DB_CHAINING OFF 
GO
ALTER DATABASE [PP_DDBB] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [PP_DDBB] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [PP_DDBB] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [PP_DDBB] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
EXEC sys.sp_db_vardecimal_storage_format N'PP_DDBB', N'ON'
GO
ALTER DATABASE [PP_DDBB] SET QUERY_STORE = ON
GO
ALTER DATABASE [PP_DDBB] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
USE [PP_DDBB]
GO
/****** Object:  UserDefinedFunction [dbo].[CalculateHash]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Función para calcular el hash de un bloque
CREATE   FUNCTION [dbo].[CalculateHash](@BlockID INT)
RETURNS NVARCHAR(32)
AS
BEGIN
    DECLARE @ConcatString NVARCHAR(MAX);
    DECLARE @Hash NVARCHAR(32);

    -- Concatenar los datos del bloque para calcular el hash
    SELECT @ConcatString = COALESCE(@ConcatString, '') + 
        CAST(BlockID AS NVARCHAR) + 
        CAST(Timestamp AS NVARCHAR) + 
        ISNULL(PreviousHash, '')
    FROM Blocks
    WHERE BlockID = @BlockID;

    -- Usar HASHBYTES (MD5) para calcular el hash
    SET @Hash = CONVERT(NVARCHAR(32), HASHBYTES('MD5', @ConcatString), 2);

    RETURN @Hash;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[fn_compare_passwords]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   FUNCTION [dbo].[fn_compare_passwords]
(
    @NEW_PASSWORD NVARCHAR(50),
    @USERNAME NVARCHAR(50)
)
RETURNS INT
AS
BEGIN
    DECLARE @pwd NVARCHAR(50);

    IF EXISTS (SELECT 1 FROM USERS WHERE USERNAME = @USERNAME)
    BEGIN
        SELECT @pwd = PASSWORD
        FROM USERS
        WHERE USERNAME = @USERNAME;

        -- Usando CASE para la comparaciÃ³n
        RETURN (
            SELECT CASE
                WHEN @NEW_PASSWORD IS NOT NULL AND @NEW_PASSWORD = @pwd THEN 1
                ELSE 0
            END
        );
    END
    ELSE
    BEGIN
        RETURN 0; -- El usuario no existe, asÃ­ que asumimos que la contraseÃ±a no es igual
    END

    -- Este return es redundante, pero se deja como salvaguarda
    RETURN -1;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[fn_compare_soundex]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   FUNCTION [dbo].[fn_compare_soundex] (
    @USERNAME NVARCHAR(25),
    @NEW_PASSWORD NVARCHAR(50)
)
RETURNS BIT
AS
BEGIN
    DECLARE @USER_ID INT;
    DECLARE @RESULT BIT = 1; -- 1 significa que no suena igual a las 3 Ãºltimas contraseÃ±as
    
    -- Obtener el ID del usuario
    SELECT @USER_ID = ID
    FROM USERS
    WHERE USERNAME = @USERNAME;

    -- Si el usuario no existe, retornar 1
    IF @USER_ID IS NULL
    BEGIN
        RETURN @RESULT;
    END

    -- Verificar las Ãºltimas 3 contraseÃ±as
    IF EXISTS (
        SELECT 1
        FROM (
            SELECT TOP 3 OLD_PASSWORD
            FROM PWD_HISTORY
            WHERE USER_ID = @USER_ID
            ORDER BY DATE_CHANGED DESC
        ) AS LastPasswords
        WHERE SOUNDEX(OLD_PASSWORD) = SOUNDEX(@NEW_PASSWORD)
    )
    BEGIN
        SET @RESULT = 0; -- 0 significa que suena igual a una de las 3 Ãºltimas contraseÃ±as
    END

    RETURN @RESULT;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[fn_generate_ssid]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   FUNCTION [dbo].[fn_generate_ssid]()
returns UNIQUEIDENTIFIER
AS
BEGIN
    declare @ssid UNIQUEIDENTIFIER;

    set @ssid = (select guid from v_guid)

    return @ssid
END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_mail_exists]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE   FUNCTION [dbo].[fn_mail_exists] (@EMAIL NVARCHAR(100))
RETURNS BIT
AS
BEGIN
    DECLARE @Exists BIT;
    SET @Exists = (
        SELECT CASE WHEN EXISTS (SELECT 1 FROM USERS WHERE EMAIL = @EMAIL) THEN 1 ELSE 0 END
    );
    RETURN @Exists;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[fn_mail_isvalid]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   FUNCTION [dbo].[fn_mail_isvalid] (@EMAIL NVARCHAR(100))
RETURNS BIT
AS
BEGIN
    DECLARE @ValidEmail BIT = 0;
    DECLARE @AtPosition INT, @DotPosition INT;

    -- Verificar si el correo electrÃ³nico contiene '@' y al menos un caracter antes y despuÃ©s
    SET @AtPosition = CHARINDEX('@', @EMAIL);
    IF (@AtPosition > 1 AND @AtPosition < LEN(@EMAIL))
    BEGIN
        -- Verificar si el correo electrÃ³nico contiene un punto despuÃ©s de '@' y al menos un caracter despuÃ©s del punto
        SET @DotPosition = CHARINDEX('.', @EMAIL, @AtPosition);
        IF (@DotPosition > (@AtPosition + 1) AND @DotPosition < LEN(@EMAIL))
        BEGIN
            SET @ValidEmail = 1;
        END;
    END;

    RETURN @ValidEmail;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[fn_pwd_checkpolicy]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- FunciÃ³n para verificar la polÃ­tica de contraseÃ±as
CREATE   FUNCTION [dbo].[fn_pwd_checkpolicy](@PASSWORD NVARCHAR(100))
RETURNS INT
AS
BEGIN
    DECLARE @errorPass BIT;
    SET @errorPass = 1;

    IF len(@PASSWORD) < 10
    BEGIN
        SET @errorPass = 0;
    END

    -- Verifica la existencia de un nÃºmero en la contraseÃ±a
    ELSE IF PATINDEX('%[0-9]%', @PASSWORD) = 0
    BEGIN
        SET @errorPass = 0;
    END

    -- Verifica la existencia de una letra en la contraseÃ±a
    ELSE IF PATINDEX('%[a-zA-Z]%', @PASSWORD) = 0
    BEGIN
        SET @errorPass = 0;
    END
    -- Verifica la existencia de un carÃ¡cter especial en la contraseÃ±a
    ELSE IF PATINDEX('%[^a-zA-Z0-9]%', @PASSWORD) = 0
    BEGIN
        SET @errorPass = 0;
    END

    RETURN @errorPass;
END
GO
/****** Object:  UserDefinedFunction [dbo].[fn_pwd_isvalid]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- FunciÃ³n para verificar la contraseÃ±a del usuario
CREATE   FUNCTION [dbo].[fn_pwd_isvalid]
(
    @PASSWORD NVARCHAR(50),
    @USERNAME NVARCHAR(25)
)
RETURNS BIT
AS
BEGIN
    DECLARE @IsValid BIT;

    -- Verificar si la contraseÃ±a proporcionada coincide con la almacenada en la base de datos
    SET @IsValid = (
        SELECT CASE WHEN EXISTS (SELECT 1 FROM USERS WHERE USERNAME = @USERNAME AND PASSWORD = @PASSWORD) THEN 1 ELSE 0 END
    );

    RETURN @IsValid;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[fn_user_exists]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE   FUNCTION [dbo].[fn_user_exists] (@USERNAME NVARCHAR(25))
RETURNS BIT
AS
BEGIN
    DECLARE @Exists BIT;
    SET @Exists = (
        SELECT CASE WHEN EXISTS (SELECT 1 FROM USERS WHERE USERNAME = @USERNAME) THEN 1 ELSE 0 END
    );
    RETURN @Exists;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[fn_user_state]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   FUNCTION [dbo].[fn_user_state] 
(
    @USERNAME NVARCHAR(25)
)
RETURNS INT
AS
BEGIN
    DECLARE @userState INT;

    SELECT @userState = CASE WHEN u.STATUS = 1 THEN 1 ELSE 0 END
    FROM USERS u
    WHERE u.USERNAME = @USERNAME;

    RETURN @userState;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[GetUsernameByConnectionId]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetUsernameByConnectionId]
(
    @ConnectionId UNIQUEIDENTIFIER
)
RETURNS NVARCHAR(25)
AS
BEGIN
    DECLARE @Username NVARCHAR(25)

    SELECT @Username = USERNAME
    FROM dbo.USER_CONNECTIONS
    WHERE CONNECTION_ID = @ConnectionId

    RETURN @Username
END
GO
/****** Object:  View [dbo].[v_guid]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create view [dbo].[v_guid] 
AS
    select newid() guid
GO
/****** Object:  Table [dbo].[Blocks]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Blocks](
	[BlockID] [int] IDENTITY(1,1) NOT NULL,
	[Timestamp] [datetime] NULL,
	[PreviousHash] [nvarchar](32) NULL,
	[Hash] [nvarchar](32) NULL,
PRIMARY KEY CLUSTERED 
(
	[BlockID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BlockTransactions]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BlockTransactions](
	[BlockID] [int] NOT NULL,
	[TransactionID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[BlockID] ASC,
	[TransactionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HistoricTransactions]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HistoricTransactions](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Sender] [nvarchar](100) NULL,
	[Destination] [nvarchar](100) NULL,
	[Amount] [decimal](10, 2) NULL,
	[Data] [nvarchar](255) NULL,
	[FechaOperacion] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PWD_HISTORY]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PWD_HISTORY](
	[HISTORY_ID] [int] IDENTITY(1,1) NOT NULL,
	[USER_ID] [int] NULL,
	[USERNAME] [nvarchar](25) NULL,
	[OLD_PASSWORD] [nvarchar](50) NULL,
	[DATE_CHANGED] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[HISTORY_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[STATUS]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[STATUS](
	[STATUS] [int] NOT NULL,
	[DESCRIPTION] [varchar](25) NULL,
PRIMARY KEY CLUSTERED 
(
	[STATUS] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Transactions]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Transactions](
	[TransactionID] [int] IDENTITY(1,1) NOT NULL,
	[Sender] [nvarchar](50) NULL,
	[Receiver] [nvarchar](50) NULL,
	[Amount] [decimal](18, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[TransactionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[USER_CONNECTIONS]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[USER_CONNECTIONS](
	[CONNECTION_ID] [uniqueidentifier] NOT NULL,
	[USER_ID] [int] NULL,
	[USERNAME] [nvarchar](25) NULL,
	[DATE_CONNECTED] [datetime] NULL,
	[DATE_DISCONNECTED] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[CONNECTION_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[USER_CONNECTIONS_HISTORY]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[USER_CONNECTIONS_HISTORY](
	[HISTORY_ID] [int] IDENTITY(1,1) NOT NULL,
	[USER_ID] [int] NULL,
	[USERNAME] [nvarchar](30) NULL,
	[DATE_CONNECTED] [datetime] NULL,
	[DATE_DISCONNECTED] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[HISTORY_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[USER_ERRORS]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[USER_ERRORS](
	[ERROR_ID] [int] IDENTITY(0,1) NOT NULL,
	[ERROR_CODE] [int] NOT NULL,
	[ERROR_MESSAGE] [nvarchar](max) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ERROR_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[USERS]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[USERS](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[USERNAME] [nvarchar](25) NULL,
	[NAME] [nvarchar](25) NULL,
	[LASTNAME] [nvarchar](50) NULL,
	[PASSWORD] [nvarchar](256) NULL,
	[EMAIL] [nvarchar](100) NULL,
	[STATUS] [int] NULL,
	[GENDER] [nvarchar](10) NULL,
	[DEF_LANG] [nvarchar](3) NULL,
	[TIMESTAMP] [datetime] NULL,
	[REGISTER_CODE] [int] NULL,
	[LOGIN_STATUS] [bit] NULL,
	[ROL_USER] [bit] NULL,
	[BALANCE] [decimal](10, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[USERNAME] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Blocks] ADD  DEFAULT (getdate()) FOR [Timestamp]
GO
ALTER TABLE [dbo].[HistoricTransactions] ADD  DEFAULT (getdate()) FOR [FechaOperacion]
GO
ALTER TABLE [dbo].[PWD_HISTORY] ADD  DEFAULT (CONVERT([datetime],switchoffset(sysdatetimeoffset(),'+01:00'))) FOR [DATE_CHANGED]
GO
ALTER TABLE [dbo].[USER_CONNECTIONS] ADD  DEFAULT (CONVERT([datetime],switchoffset(sysdatetimeoffset(),'+01:00'))) FOR [DATE_CONNECTED]
GO
ALTER TABLE [dbo].[USER_CONNECTIONS_HISTORY] ADD  DEFAULT (CONVERT([datetime],switchoffset(sysdatetimeoffset(),'+01:00'))) FOR [DATE_CONNECTED]
GO
ALTER TABLE [dbo].[USER_CONNECTIONS_HISTORY] ADD  DEFAULT (CONVERT([datetime],switchoffset(sysdatetimeoffset(),'+01:00'))) FOR [DATE_DISCONNECTED]
GO
ALTER TABLE [dbo].[USERS] ADD  DEFAULT (CONVERT([datetime],switchoffset(sysdatetimeoffset(),'+01:00'))) FOR [TIMESTAMP]
GO
ALTER TABLE [dbo].[BlockTransactions]  WITH CHECK ADD FOREIGN KEY([BlockID])
REFERENCES [dbo].[Blocks] ([BlockID])
GO
ALTER TABLE [dbo].[BlockTransactions]  WITH CHECK ADD FOREIGN KEY([TransactionID])
REFERENCES [dbo].[Transactions] ([TransactionID])
GO
ALTER TABLE [dbo].[PWD_HISTORY]  WITH CHECK ADD FOREIGN KEY([USER_ID])
REFERENCES [dbo].[USERS] ([ID])
GO
ALTER TABLE [dbo].[USER_CONNECTIONS]  WITH CHECK ADD FOREIGN KEY([USER_ID])
REFERENCES [dbo].[USERS] ([ID])
GO
ALTER TABLE [dbo].[USER_CONNECTIONS_HISTORY]  WITH CHECK ADD FOREIGN KEY([USER_ID])
REFERENCES [dbo].[USERS] ([ID])
GO
ALTER TABLE [dbo].[USERS]  WITH CHECK ADD FOREIGN KEY([STATUS])
REFERENCES [dbo].[STATUS] ([STATUS])
GO
/****** Object:  StoredProcedure [dbo].[AddBlock]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
ALTER PROCEDURE [dbo].[AddBlock]
    @Hash NVARCHAR(32) ,
	@PreviousHashG NVARCHAR(32)
AS
BEGIN
    DECLARE @PreviousHash NVARCHAR(32);

    -- Obtener el último hash existente
    SELECT TOP 1 @PreviousHash = Hash
    FROM Blocks
    WHERE Hash IS NOT NULL
    ORDER BY BlockID DESC;

	
	IF @PreviousHash IS NULL
    BEGIN
        SET @PreviousHash = @PreviousHashG;
    END

    -- Insertar nuevo bloque con el previous hash
    INSERT INTO Blocks (PreviousHash)
    VALUES (@PreviousHash);

    -- Obtener el BlockID recién insertado
    DECLARE @BlockID INT = SCOPE_IDENTITY();

    -- Actualizar el hash del bloque recién insertado
    UPDATE Blocks
    SET Hash = @Hash
    WHERE BlockID = @BlockID;
END;*/

CREATE PROCEDURE [dbo].[AddBlock]
    @Hash NVARCHAR(32),
    @PreviousHashG NVARCHAR(32)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PreviousHash NVARCHAR(32);

    BEGIN TRY
        SELECT TOP 1 @PreviousHash = Hash FROM Blocks WHERE Hash IS NOT NULL ORDER BY BlockID DESC;

        IF @PreviousHash IS NULL
            SET @PreviousHash = @PreviousHashG;

        INSERT INTO Blocks (PreviousHash) VALUES (@PreviousHash);

        DECLARE @BlockID INT = SCOPE_IDENTITY();

        UPDATE Blocks SET Hash = @Hash WHERE BlockID = @BlockID;

        -- Devuelve XML limpio
        SELECT
            0 AS [head/status],
            'Bloque agregado' AS [head/message],
            NULL AS [body]
        FOR XML PATH('head'), ROOT('ws_response');

    END TRY
    BEGIN CATCH
        SELECT
            1 AS [head/status],
            ERROR_MESSAGE() AS [head/message],
            NULL AS [body]
        FOR XML PATH('head'), ROOT('ws_response');
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[AddTransaction]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
ALTER PROCEDURE [dbo].[AddTransaction]
    --@Sender NVARCHAR(50),
	@ConnectionId UNIQUEIDENTIFIER,
    @Receiver NVARCHAR(50),
    @Amount DECIMAL(18, 2),
    @BlockID INT
AS
BEGIN
    SET NOCOUNT ON;

	-- para que funcione con ssid
	DECLARE @Sender NVARCHAR(25)
	 SET @Sender = dbo.GetUsernameByConnectionId(@ConnectionId)
	 -- si no existe da error
	IF @Sender IS NULL
    BEGIN
        RAISERROR('No se encontró un usuario con ese Connection ID.', 16, 1)
        RETURN
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validación: monto positivo
        IF @Amount <= 0
        BEGIN
            RAISERROR('El monto debe ser mayor a cero.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Obtener IDs y balances de los usuarios
        DECLARE @SenderID INT, @ReceiverID INT, @SenderBalance DECIMAL(18,2);

        SELECT @SenderID = ID, @SenderBalance = BALANCE
        FROM [dbo].[USERS]
        WHERE USERNAME = @Sender;

        IF @SenderID IS NULL
        BEGIN
            RAISERROR('El usuario emisor no existe.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @SenderBalance < @Amount
        BEGIN
            RAISERROR('Saldo insuficiente para realizar la transacción.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        SELECT @ReceiverID = ID
        FROM [dbo].[USERS]
        WHERE USERNAME = @Receiver;

        IF @ReceiverID IS NULL
        BEGIN
            RAISERROR('El usuario receptor no existe.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insertar transacción
        INSERT INTO Transactions (Sender, Receiver, Amount)
        VALUES (@Sender, @Receiver, @Amount);

        DECLARE @TransactionID INT = SCOPE_IDENTITY();

        -- Relacionar con bloque
        INSERT INTO BlockTransactions (BlockID, TransactionID)
        VALUES (@BlockID, @TransactionID);

		 -- Insertar en HistoricTransactions
        INSERT INTO HistoricTransactions (Sender, Destination, Amount, Data, FechaOperacion)
		VALUES (
			@Sender,
			@Receiver,
			@Amount,
			FORMAT(SYSDATETIMEOFFSET() AT TIME ZONE 'Central European Standard Time', 'HH:mm:ss'), -- Hora en la zona horaria de España
			CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'Central European Standard Time' AS DATE) -- Fecha en la zona horaria de España
		);

        -- Actualizar balances
        UPDATE [dbo].[USERS]
        SET BALANCE = BALANCE - @Amount
        WHERE ID = @SenderID;

        UPDATE [dbo].[USERS]
        SET BALANCE = BALANCE + @Amount
        WHERE ID = @ReceiverID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;*/

CREATE PROCEDURE [dbo].[AddTransaction]
    @ConnectionId UNIQUEIDENTIFIER,
    @Receiver NVARCHAR(25),
    @Amount DECIMAL(18, 2),
    @BlockID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Sender NVARCHAR(25) = dbo.GetUsernameByConnectionId(@ConnectionId);

    IF @Sender IS NULL
    BEGIN
        SELECT
            1 AS [head/status],
            'No se encontró un usuario con ese Connection ID.' AS [head/message],
            NULL AS [body]
        FOR XML PATH('head'), ROOT('ws_response');
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Amount <= 0
        BEGIN
            THROW 50000, 'El monto debe ser mayor a cero.', 1;
        END

        DECLARE @SenderID INT, @ReceiverID INT, @SenderBalance DECIMAL(18,2);

        SELECT @SenderID = ID, @SenderBalance = BALANCE FROM [dbo].[USERS] WHERE USERNAME = @Sender;

        IF @SenderBalance < @Amount
        BEGIN
            THROW 50001, 'Saldo insuficiente para realizar la transacción.', 1;
        END
		
        SELECT @ReceiverID = ID FROM [dbo].[USERS] WHERE USERNAME = @Receiver;

        IF @ReceiverID IS NULL
        BEGIN
            THROW 50002, 'El usuario receptor no existe.', 1;
        END
		
		IF dbo.fn_user_exists(@Receiver) = 0
			BEGIN
				SELECT
					1 AS [head/status],
					'El usuario receptor no existe.' AS [head/message],
					NULL AS [body]
				FOR XML PATH('head'), ROOT('ws_response');
				RETURN;
			END






        INSERT INTO Transactions (Sender, Receiver, Amount) VALUES (@Sender, @Receiver, @Amount);

        DECLARE @TransactionID INT = SCOPE_IDENTITY();

        INSERT INTO BlockTransactions (BlockID, TransactionID) VALUES (@BlockID, @TransactionID);

        INSERT INTO HistoricTransactions (Sender, Destination, Amount, Data, FechaOperacion)
        VALUES (
            @Sender,
            @Receiver,
            @Amount,
            FORMAT(SYSDATETIMEOFFSET() AT TIME ZONE 'Central European Standard Time', 'HH:mm:ss'),
            CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'Central European Standard Time' AS DATE)
        );

        UPDATE [dbo].[USERS] SET BALANCE = BALANCE - @Amount WHERE ID = @SenderID;
        UPDATE [dbo].[USERS] SET BALANCE = BALANCE + @Amount WHERE ID = @ReceiverID;

        COMMIT TRANSACTION;

        SELECT
            0 AS [head/status],
            'Bizum enviado' AS [head/message],
            NULL AS [body]
        FOR XML PATH('head'), ROOT('ws_response');

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT
            1 AS [head/status],
            ERROR_MESSAGE() AS [head/message],
            NULL AS [body]
        FOR XML PATH('head'), ROOT('ws_response');
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[check_balance]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
ALTER PROCEDURE [dbo].[check_balance]
    --@USERNAME NVARCHAR(25)
	@ConnectionId UNIQUEIDENTIFIER  
AS
BEGIN
	 SET NOCOUNT ON;
	 DECLARE @USERNAME NVARCHAR(25);

    -- Obtener el username a partir del ConnectionId
    SET @USERNAME = dbo.GetUsernameByConnectionId(@ConnectionId);

    -- Validar si se encontró el usuario
    IF @USERNAME IS NULL
    BEGIN
        RAISERROR('No se encontró un usuario con ese Connection ID.', 16, 1);
        RETURN;
    END



    SELECT BALANCE 
    FROM USERS 
    WHERE USERNAME = @USERNAME;

END;

*/
/*
ALTER PROCEDURE [dbo].[check_balance]
    @ConnectionId UNIQUEIDENTIFIER  
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @USERNAME NVARCHAR(25);
    DECLARE @BALANCE DECIMAL(18,2);
    DECLARE @ret INT = 0; -- Código de error, 0 = OK
    DECLARE @ResponseXML XML;

    -- Obtener el username a partir del ConnectionId
    SET @USERNAME = dbo.GetUsernameByConnectionId(@ConnectionId);

    -- Validar si se encontró el usuario
    IF @USERNAME IS NULL
    BEGIN
        SET @ret = 1; -- Código de error para "usuario no encontrado"
        GOTO ExitProc;
    END

    -- Obtener balance
    SELECT @BALANCE = BALANCE FROM USERS WHERE USERNAME = @USERNAME;

    -- Crear XML respuesta exitosa
    SET @ResponseXML = (
        SELECT 
            0 AS 'head/status',
            'Balance obtenido correctamente' AS 'head/message',
            @BALANCE AS 'body/balance'
        FOR XML PATH('head'), ROOT('ws_response')
    );

    GOTO ReturnResponse;

ExitProc:
    EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;

ReturnResponse:
    SELECT @ResponseXML AS XmlResult;
END;
*/
CREATE PROCEDURE [dbo].[check_balance]
    @ConnectionId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Username NVARCHAR(25);
    DECLARE @Balance DECIMAL(18,2);
    DECLARE @ret INT = -1;
    DECLARE @ResponseXML XML;

    -- Obtener el username a partir del ConnectionId
    SET @Username = dbo.GetUsernameByConnectionId(@ConnectionId);

    -- Validar si se encontró el usuario
    IF @Username IS NULL
    BEGIN
        SET @ret = 404; -- Código de error personalizado
        GOTO ExitProc;
    END

    -- Obtener el balance
    SELECT @Balance = BALANCE FROM USERS WHERE USERNAME = @Username;

    -- Verificar si se obtuvo el balance
    IF @Balance IS NULL
    BEGIN
        SET @ret = 500; -- Error interno o usuario inválido
        GOTO ExitProc;
    END

    -- Armar respuesta con balance en <body>
    SET @ResponseXML = (
        SELECT
            0 AS [head/status],
            'Balance obtenido correctamente' AS [head/message],
            (
                SELECT @Balance AS [balance]
                FOR XML PATH(''), TYPE
            ) AS [body]
        FOR XML PATH('head'), ROOT('ws_response')
    );

    SELECT @ResponseXML AS XmlResult;
    RETURN;

ExitProc:
    EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;
    SELECT @ResponseXML AS XmlResult;
END;
GO
/****** Object:  StoredProcedure [dbo].[CheckReceiverExists]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CheckReceiverExists]
    @Username NVARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;

    SET @Username = LTRIM(RTRIM(@Username));

    IF EXISTS (
        SELECT 1 FROM USERS
        WHERE LOWER(USERNAME) = LOWER(@Username)
    )
        SELECT 1 AS ReceiverExists;
    ELSE
        SELECT 0 AS ReceiverExists;
END
GO
/****** Object:  StoredProcedure [dbo].[CheckUserExists]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CheckUserExists]
    @ConnectionId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Username NVARCHAR(25)
    SET @Username = dbo.GetUsernameByConnectionId(@ConnectionId)

    IF @Username IS NOT NULL
        SELECT 1 AS UserExists
    ELSE
        SELECT 0 AS UserExists
END
GO
/****** Object:  StoredProcedure [dbo].[GetActiveUserNames]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetActiveUserNames]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [NAME]
    FROM [PP_DDBB].[dbo].[USERS]
    WHERE [STATUS] = 1;
END;
GO
/****** Object:  StoredProcedure [dbo].[GetActiveUserUsernames]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetActiveUserUsernames]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [USERNAME]
    FROM [PP_DDBB].[dbo].[USERS]
    WHERE [STATUS] = 1
    FOR XML PATH('User'), ROOT('Users');
END;
GO
/****** Object:  StoredProcedure [dbo].[GetActiveUserUsernamesXML]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetActiveUserUsernamesXML]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [USERNAME]
    FROM [PP_DDBB].[dbo].[USERS]
    WHERE [STATUS] = 1
    FOR XML PATH('User'), ROOT('Users');
END;
GO
/****** Object:  StoredProcedure [dbo].[GetLastBlockId]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetLastBlockId]
AS
BEGIN
    -- Obtener el último BlockID insertado
    SELECT BlockID
    FROM Blocks
    ORDER BY BlockID DESC
    OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;  -- Asegurarse de que solo se devuelva una fila
END;
GO
/****** Object:  StoredProcedure [dbo].[GetLastTransactionId]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetLastTransactionId]
    @LastTransactionID INT OUTPUT
AS
BEGIN
    -- Seleccionamos el último TransactionID
    SELECT TOP 1 @LastTransactionID = TransactionID
    FROM Transactions
    ORDER BY TransactionID DESC;
END;
GO
/****** Object:  StoredProcedure [dbo].[GetUserLastTransaction]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Modificar el procedimiento existente
CREATE PROCEDURE [dbo].[GetUserLastTransaction]
    --@Username NVARCHAR(100)
	 @ConnectionId UNIQUEIDENTIFIER 
AS
BEGIN

    SET NOCOUNT ON;
	-- para que funcione con ssid
	DECLARE @Username NVARCHAR(25)
	 SET @Username = dbo.GetUsernameByConnectionId(@ConnectionId)
	 -- si no existe da error
	IF @Username IS NULL
    BEGIN
        RAISERROR('No se encontró un usuario con ese Connection ID.', 16, 1)
        RETURN
    END
    -- Seleccionar solo la última transacción relacionada con el usuario
    SELECT TOP 1
        [Id],
        [Sender],
        [Destination],
        [Amount],
        [Data],
        [FechaOperacion]
    FROM [dbo].[HistoricTransactions]
    WHERE [Sender] = @Username OR [Destination] = @Username
    ORDER BY 
        TRY_CAST(CONVERT(VARCHAR, [FechaOperacion], 23) + ' ' + CONVERT(VARCHAR, [Data], 8) AS DATETIME) DESC
    FOR XML PATH('Transaction'), ROOT('Transactions'), ELEMENTS;
END
GO
/****** Object:  StoredProcedure [dbo].[GetUserTransactionsHistory]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetUserTransactionsHistory]
    --@Username NVARCHAR(100)
	@ConnectionId UNIQUEIDENTIFIER 
AS
BEGIN
    SET NOCOUNT ON;

	-- para que funcione con ssid
	DECLARE @Username NVARCHAR(25)
	 SET @Username = dbo.GetUsernameByConnectionId(@ConnectionId)
	 -- si no existe da error
	IF @Username IS NULL
    BEGIN
        RAISERROR('No se encontró un usuario con ese Connection ID.', 16, 1)
        RETURN
    END


    SELECT
        [Id],
        [Sender],
        [Destination],
        [Amount],
        [Data],
        [FechaOperacion]
    FROM [dbo].[HistoricTransactions]
    WHERE [Sender] = @Username OR [Destination] = @Username
    ORDER BY 
        TRY_CAST(CONVERT(VARCHAR, [FechaOperacion], 23) + ' ' + CONVERT(VARCHAR, [Data], 8) AS DATETIME) DESC
    FOR XML PATH('Transaction'), ROOT('Transactions'), ELEMENTS;
END
GO
/****** Object:  StoredProcedure [dbo].[SaveBlockchain]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SaveBlockchain]
AS
BEGIN
    DECLARE @BlockID INT, @PreviousHash NVARCHAR(32), @Hash NVARCHAR(32), @Timestamp DATETIME;

    DECLARE blockchain_cursor CURSOR FOR
    SELECT BlockID, Timestamp, PreviousHash, Hash FROM Blocks;

    OPEN blockchain_cursor;
    FETCH NEXT FROM blockchain_cursor INTO @BlockID, @Timestamp, @PreviousHash, @Hash;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Insertamos cada bloque en la base de datos
        INSERT INTO Blocks (BlockID, Timestamp, PreviousHash, Hash)
        VALUES (@BlockID, @Timestamp, @PreviousHash, @Hash);

        FETCH NEXT FROM blockchain_cursor INTO @BlockID, @Timestamp, @PreviousHash, @Hash;
    END;

    CLOSE blockchain_cursor;
    DEALLOCATE blockchain_cursor;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_check_password_strength]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_check_password_strength]
    @PASSWORD NVARCHAR(255)
AS
BEGIN
    DECLARE @Result XML;

    -- Verificar si la longitud de la contraseña es menor a 8 caracteres
    IF LEN(@PASSWORD) < 8
    BEGIN
        SET @Result = '<PasswordStrength><Message>La contraseña es corta. Minimo 8 caracteres.</Message></PasswordStrength>';
    END
    -- Verificar si contiene al menos un número, una letra (mayúscula o minúscula), una letra mayúscula y un símbolo especial
    ELSE IF @PASSWORD LIKE '%[0-9]%' 
         AND @PASSWORD LIKE '%[A-Za-z]%' 
         AND @PASSWORD COLLATE Latin1_General_BIN LIKE '%[A-Z]%'  -- Verificar que tiene al menos una letra mayúscula
         AND @PASSWORD LIKE '%[!@#$%^&*(),.?":{}|<>]%'  -- Verificar que tiene al menos un símbolo especial
    BEGIN
        SET @Result = '<PasswordStrength><Message>Contraseña fuerte</Message></PasswordStrength>';
    END
    -- Si no cumple con los requisitos anteriores
    ELSE
    BEGIN
        SET @Result = '<PasswordStrength><Message>La contraseña minimo una letra, número, letra mayúscula y símbolo especial.</Message></PasswordStrength>';
    END

    -- Devolver el resultado en formato XML
    SELECT @Result AS PasswordStrength;
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_get_user_balance]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_get_user_balance]
    @ConnectionId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @USERNAME NVARCHAR(255);
    DECLARE @Balance DECIMAL(10, 2);
    DECLARE @Result XML;

    -- Obtener el username usando la función
    SET @USERNAME = dbo.GetUsernameByConnectionId(@ConnectionId);

    -- Validar si se obtuvo un username
    IF @USERNAME IS NULL
    BEGIN
        SET @Result = 
            '<UserBalance>' +
                '<Error>Usuario no encontrado (ConnectionId inválido).</Error>' +
            '</UserBalance>';

        SELECT @Result AS UserBalance;
        RETURN;
    END

    -- Obtener el balance del usuario
    SELECT @Balance = [BALANCE]
    FROM [dbo].[USERS]
    WHERE [USERNAME] = @USERNAME;

    -- Si se encuentra balance, devolverlo como XML
    IF @Balance IS NOT NULL
    BEGIN
        SET @Result = 
            '<UserBalance>' +
                '<BALANCE>' + CAST(@Balance AS NVARCHAR(50)) + '</BALANCE>' +
            '</UserBalance>';
    END
    ELSE
    BEGIN
        SET @Result = 
            '<UserBalance>' +
                '<Error>Usuario no encontrado o no tiene balance.</Error>' +
            '</UserBalance>';
    END

    -- Devolver el resultado
    SELECT @Result AS UserBalance;
END
/*
ALTER PROCEDURE [dbo].[sp_get_user_balance]
    @ConnectionId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @USERNAME NVARCHAR(255);
    DECLARE @BALANCE DECIMAL(10, 2);
    DECLARE @ret INT = -1;
    DECLARE @XmlResponse XML;

    -- Obtener el username usando la función
    SET @USERNAME = dbo.GetUsernameByConnectionId(@ConnectionId);

    -- Validar si se obtuvo un username
    IF @USERNAME IS NULL
    BEGIN
        SET @ret = 404; -- Código de error: usuario no encontrado
        GOTO ExitProc;
    END

    -- Obtener el balance
    SELECT @BALANCE = [BALANCE]
    FROM [dbo].[USERS]
    WHERE [USERNAME] = @USERNAME;

    -- Validar si se encontró balance
    IF @BALANCE IS NULL
    BEGIN
        SET @ret = 405; -- Usuario sin balance
        GOTO ExitProc;
    END

    -- Armar respuesta XML si todo está OK
    SET @XmlResponse = (
        SELECT
            0 AS [status],
            'Balance obtenido correctamente' AS [message],
            (
                SELECT @BALANCE AS [balance]
                FOR XML PATH(''), TYPE
            ) AS [body]
        FOR XML PATH(''), ROOT('ws_response'), TYPE
    );

    SELECT @XmlResponse AS XmlResult;
    RETURN;

ExitProc:
    EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @XmlResponse OUTPUT;
    SELECT @XmlResponse AS XmlResult;
END*/
GO
/****** Object:  StoredProcedure [dbo].[sp_get_user_password]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_get_user_password]
@username VARCHAR(255)
AS
BEGIN
    SELECT password FROM users WHERE username = @username;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_list_connections]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_list_connections]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ret INT;
    SET @ret = -1;

    DECLARE @XMLFlag XML;

    IF EXISTS (
        SELECT 1 FROM USER_CONNECTIONS -- Verifica la tabla correcta
    )
    BEGIN
        SET @XMLFlag = (
            SELECT * FROM USER_CONNECTIONS
            FOR XML PATH('Connection'), ROOT('Connections'), TYPE
        );
        SET @ret = 0;
    END
    ELSE
    BEGIN
        UPDATE USERS SET LOGIN_STATUS = 0;
        SET @ret = 504;
    END

    IF @ret <> 0
    BEGIN
        ExitProc:
        DECLARE @ResponseXML XML;
        EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;
        SELECT @ResponseXML;
    END
    ELSE
        SELECT @XMLFlag;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_list_errors]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_list_errors]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ret INT;
    SET @ret = -1;

    DECLARE @XMLFlag XML;

    -- Verificar si hay errores
    IF EXISTS (SELECT 1 FROM USER_ERRORS)
    BEGIN
        -- Si hay errores, convertir el conjunto de resultados a XML
        SET @XMLFlag = (
            SELECT * FROM USER_ERRORS
            FOR XML PATH('Errors'), ROOT('Errors'), TYPE
        );
        SET @ret = 0; -- Indicar que hubo resultados
    END
    ELSE
    BEGIN
        SET @ret = 508;
    END

    IF @ret <> 0
    BEGIN
        ExitProc:
        DECLARE @ResponseXML XML;
        EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;
        SELECT @ResponseXML;
    END
    ELSE
        SELECT @XMLFlag;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_list_historic_connections]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_list_historic_connections]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ret INT;
    SET @ret = -1;

    DECLARE @XMLFlag XML;

    -- Verificar si hay datos en el historial de conexiones
    IF EXISTS (SELECT 1 FROM USER_CONNECTIONS_HISTORY)
    BEGIN
        -- Si hay datos, convertir el conjunto de resultados a XML
        SET @XMLFlag = (
            SELECT HISTORY_ID,USERNAME,DATE_CONNECTED,DATE_DISCONNECTED FROM USER_CONNECTIONS_HISTORY
            FOR XML PATH('HistoricConnections'), ROOT('HistoricConnections'), TYPE
        );
        SET @ret = 0; -- Indicar que hubo resultados
    END
    ELSE
    BEGIN
        SET @ret = 505; -- Indicar que hubo resultados
    END
    
    IF @ret <> 0
    BEGIN
        ExitProc:
        DECLARE @ResponseXML XML;
        EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;
        SELECT @ResponseXML;
    END
    ELSE
        SELECT @XMLFlag;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_list_system_status]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_list_system_status]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ret INT;
    SET @ret = -1;

    DECLARE @XMLFlag XML;

    -- Verificar si hay usuarios con estado definido
    IF EXISTS (
        SELECT 1 FROM USERS u
        INNER JOIN STATUS s ON u.STATUS = s.STATUS
    )
    BEGIN
        -- Si hay usuarios con estado, convertir el conjunto de resultados a XML
        SET @XMLFlag = (
            SELECT u.ID AS UserID, u.USERNAME, s.STATUS
            FROM USERS u
            INNER JOIN STATUS s ON u.STATUS = s.STATUS
            FOR XML PATH(''), ROOT('SystemStatus'), TYPE
        );
        SET @ret = 0; -- Indicar que hubo resultados
    END
    ELSE
    BEGIN
        SET @ret = 506;
    END

    IF @ret <> 0
    BEGIN
        ExitProc:
        DECLARE @ResponseXML XML;
        EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;
        SELECT @ResponseXML;
    END
    ELSE
        SELECT @XMLFlag;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_list_users]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- Procedimiento almacenado para listar usuarios
CREATE   PROCEDURE [dbo].[sp_list_users]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ret INT;
    SET @ret = -1;

    DECLARE @XMLFlag XML;

    -- Verificar si hay datos en el historial de conexiones
    IF EXISTS (SELECT 1 FROM USERS)
    BEGIN
        -- Si hay datos, convertir el conjunto de resultados a XML
        SET @XMLFlag = (
            SELECT USERNAME FROM USERS
            FOR XML PATH('Usuarios'), ROOT('Usuarios'), TYPE
        );
    END
    ELSE
    BEGIN
        SET @ret = 505; -- Indicar que hubo resultados
    END
    
    IF @ret <> -1
    BEGIN
        ExitProc:
        DECLARE @ResponseXML XML;
        EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;
        SELECT @ResponseXML;
    END
    ELSE
        SELECT @XMLFlag;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_list_users2]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- Procedimiento almacenado para listar usuarios
CREATE   PROCEDURE [dbo].[sp_list_users2]
    @ssid NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ret INT;
    SET @ret = -1;

    DECLARE @XMLFlag XML;

    DECLARE @USERNAME NVARCHAR(250);

    DECLARE @ROL_USER BIT;
    
    SELECT @USERNAME=USERNAME
    FROM USER_CONNECTIONS
    WHERE CAST(CONNECTION_ID AS nvarchar(255))=@ssid ;

    SELECT @ROL_USER = ROL_USER
    FROM USERS
    WHERE USERNAME = @USERNAME;

    IF @ROL_USER = 1
    BEGIN
        -- Verificar si hay datos en el historial de conexiones
        IF EXISTS (SELECT 1 FROM USERS)
        BEGIN
            -- Si hay datos, convertir el conjunto de resultados a XML
            SET @XMLFlag = (
                SELECT USERNAME FROM USERS
                FOR XML PATH('Usuarios'), ROOT('Usuarios'), TYPE
            );
        END
        ELSE
        BEGIN
            SET @ret = 505; -- Indicar que hubo resultados
        END
    END
    ELSE
    BEGIN
        SET @ret = 800;
    END
    
    IF @ret <> -1
    BEGIN
        ExitProc:
        DECLARE @ResponseXML XML;
        EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;
        SELECT @ResponseXML;
    END
    ELSE
        SELECT @XMLFlag;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_user_accountvalidate]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_user_accountvalidate]
    @USERNAME NVARCHAR(25),
    @REGISTER_CODE INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ret INT = -1;
    DECLARE @UserID INT;
    DECLARE @UserStatus INT;
    DECLARE @UserRegisterCode INT;

    -- Verificar si el usuario existe
    IF dbo.fn_user_exists(@USERNAME) = 0
    BEGIN
        SET @ret = 501;
        GOTO ExitProc;
    END;

    -- Obtener el ID, estado y register code del usuario
    SELECT @UserID = ID, @UserStatus = STATUS, @UserRegisterCode = REGISTER_CODE
    FROM USERS
    WHERE USERNAME = @USERNAME;

    -- Verificar si el usuario ya estÃ¡ activo
    IF @UserStatus = 1
    BEGIN
        SET @ret = 701;
        GOTO ExitProc;
    END;

    -- Verificar si el cÃ³digo de registro coincide
    IF @REGISTER_CODE <> @UserRegisterCode
    BEGIN
        SET @ret = 702;
        GOTO ExitProc;
    END;

    -- Actualizar el estado del usuario a activo (1)
    UPDATE USERS SET STATUS = 1 WHERE ID = @UserID;

    -- Verificar si se actualizÃ³ correctamente
    IF @@ROWCOUNT = 0
    BEGIN
        SET @ret = 703;
        GOTO ExitProc;
    END
    ELSE
    BEGIN
        SET @ret = 0;
        GOTO ExitProc;
    END;

ExitProc:
    DECLARE @ResponseXML XML;
    EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;
    SELECT @ResponseXML;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_user_change_password]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- sp_user_change_password
CREATE   PROCEDURE [dbo].[sp_user_change_password]
    @USERNAME NVARCHAR(50), 
    @CURRENT_PASSWORD NVARCHAR(50), 
    @NEW_PASSWORD NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ret INT;
    SET @ret = -1;

    DECLARE @XMLFlag XML;

    -- Verifica que la contraseÃ±a actual sea vÃ¡lida
    IF (dbo.fn_pwd_isvalid(@CURRENT_PASSWORD, @USERNAME) = 0)
    BEGIN
        SET @ret = 502;
        GOTO ExitProc;
    END

    -- Verifica que la nueva contraseÃ±a cumpla con la polÃ­tica
    IF dbo.fn_pwd_checkpolicy(@NEW_PASSWORD) = 0
    BEGIN
        SET @ret = 503;
        GOTO ExitProc;
    END

    -- Verificar si la nueva contraseÃ±a es igual a alguna de las tres Ãºltimas contraseÃ±as
    IF dbo.fn_compare_soundex(@USERNAME, @NEW_PASSWORD) = 0
    BEGIN
        SET @ret = 402;
        GOTO ExitProc;
    END

    -- Verificar si la nueva contraseÃ±a es igual a la Ãºltima contraseÃ±a
    IF dbo.fn_compare_passwords(@NEW_PASSWORD, @USERNAME) = 1
    BEGIN
        SET @ret = 402;
        GOTO ExitProc;
    END

    -- Llamar a la procedure para actualizar la informaciÃ³n de contraseÃ±a del usuario
    EXEC sp_wdev_user_update_password_info @USERNAME, @CURRENT_PASSWORD, @NEW_PASSWORD, @ret OUTPUT;

    ExitProc:
    DECLARE @ResponseXML XML;
    EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;
    SELECT @ResponseXML;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_user_get_accountdata]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE   PROCEDURE [dbo].[sp_user_get_accountdata]
    @USERNAME NVARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ret INT;
    DECLARE @XMLFlag XML;

    SET @ret = -1;

    -- Llamar al procedimiento para verificar la existencia de datos
    EXEC sp_wdev_user_check_existence @USERNAME, @ret OUTPUT, @XMLFlag OUTPUT;

    IF @ret <> -1
    BEGIN
        DECLARE @ResponseXML XML;
        EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;
        SELECT @ResponseXML;
    END
    ELSE
        SELECT @XMLFlag;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_user_login]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[sp_user_login]
    @USERNAME NVARCHAR(25),
    @PASSWORD NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
	DECLARE @ResponseXML XML;
    DECLARE @XML_RESPONSE XML;
    DECLARE @LOGIN_STATUS BIT;
    DECLARE @ret INT;
    SET @ret = -1;

    -- Verificar si el usuario está actualmente conectado
    EXEC sp_wdev_user_get_login_status @USERNAME, @LOGIN_STATUS OUTPUT, @ret OUTPUT;
		if @LOGIN_STATUS = 1
		BEGIN
			SET @ret = 500;
			GOTO ExitProc;
		END

    -- Verificar si el usuario existe
    IF (dbo.fn_user_exists(@USERNAME) = 0)
    BEGIN
        SET @ret = 501;
        GOTO ExitProc;
    END
    ELSE
    BEGIN
        -- Verificar el estado del usuario
        IF (dbo.fn_user_state(@USERNAME) = 0)
        BEGIN
            SET @ret = 423;
            GOTO ExitProc;
        END
        ELSE
        BEGIN
            -- Verificar la validez de la contraseña
            IF (dbo.fn_pwd_isvalid(@PASSWORD, @USERNAME) = 0)
            BEGIN
                SET @ret = 502;
                GOTO ExitProc;
            END
            ELSE
            BEGIN
                DECLARE @CONNECTION_ID UNIQUEIDENTIFIER;
                SET @CONNECTION_ID = dbo.fn_generate_ssid();

				SET @ResponseXML = (
				SELECT @CONNECTION_ID AS 'SSID' FOR XML PATH(''), TYPE );


                -- Crear una nueva conexión para el usuario
                EXEC sp_wdev_user_create_user_connection @USERNAME, @CONNECTION_ID, @ret OUTPUT;
            END
        END
    END

    ExitProc:
    --DECLARE @ResponseXML XML;
    EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;

    SELECT @ResponseXML;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_user_logout]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_user_logout]
    --@USERNAME NVARCHAR(25) 
	@ConnectionId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;


	-- para que funcione con ssid
	DECLARE @USERNAME NVARCHAR(25)
	 SET @USERNAME = dbo.GetUsernameByConnectionId(@ConnectionId)
	 -- si no existe da error
	IF @Username IS NULL
    BEGIN
        RAISERROR('No se encontró un usuario con ese Connection ID.', 16, 1)
        RETURN
    END
    
    DECLARE @ret INT;
    DECLARE @USER_ID INT;
    DECLARE @DATE_CONNECTED DATETIME;
    DECLARE @DATE_DISCONNECTED DATETIME;

    --SET @DATE_DISCONNECTED = GETDATE(); -- LINEA CON FALLO
    SET @DATE_DISCONNECTED = CONVERT(DATETIME, SWITCHOFFSET(SYSDATETIMEOFFSET(), '+01:00')); -- Hora espaÃ±ola estÃ¡ndar


    -- Comprueba si el usuario estÃ¡ conectado
    EXEC sp_wdev_check_user_connection @USERNAME, @USER_ID OUTPUT, @DATE_CONNECTED OUTPUT, @ret OUTPUT;

    IF @ret = 100
    BEGIN
        -- Insertar en USER_CONNECTIONS_HISTORY antes de eliminar
        EXEC sp_wdev_insert_user_connection_history 
            @USER_ID, 
            @USERNAME, 
            @DATE_CONNECTED, 
            @DATE_DISCONNECTED -- fecha de desconexiÃ³n


        -- Eliminar de USER_CONNECTIONS
        DELETE FROM USER_CONNECTIONS WHERE USERNAME = @USERNAME;

        IF @@ROWCOUNT = 1
        BEGIN
            -- Actualizar estado de conexiÃ³n en USERS
            EXEC sp_wdev_update_user_login_status_0 @USERNAME;

            SET @ret = 0; -- Ã‰xito
        END
    END

    DECLARE @ResponseXML XML;
    EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;
    SELECT @ResponseXML;
END
--EXEC [sp_user_logout] ayoub
GO
/****** Object:  StoredProcedure [dbo].[sp_user_register]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
ALTER   PROCEDURE [dbo].[sp_user_register]
    @USERNAME NVARCHAR(25),
    @NAME NVARCHAR(25),
    @LASTNAME NVARCHAR(50),
    @PASSWORD NVARCHAR(50),
    @EMAIL NVARCHAR(30),
    @GENDER NVARCHAR(10), -- Hombre o Mujer
    @DEF_LANG NVARCHAR(10) -- Idioma predeterminado
AS 
BEGIN
    SET NOCOUNT ON;

    DECLARE @ret INT;
    SET @ret = -1;

    -- Verificar si el usuario ya existe
    IF dbo.fn_user_exists(@USERNAME) = 1
    BEGIN
        SET @ret = 409;
        GOTO ExitProc;
    END
    ELSE
    BEGIN
        -- Verificar si el correo electrÃ³nico ya estÃ¡ registrado
        IF dbo.fn_mail_exists(@EMAIL) = 1
        BEGIN
            SET @ret = 408;
            GOTO ExitProc;
        END
        ELSE
        BEGIN
            -- Verificar si el correo electrÃ³nico es vÃ¡lido
            IF dbo.fn_mail_isvalid(@EMAIL) = 0
            BEGIN
                SET @ret = 450;
                GOTO ExitProc;
            END
            ELSE
            BEGIN
                -- Verificar la polÃ­tica de contraseÃ±a
                IF dbo.fn_pwd_checkpolicy(@PASSWORD) = 0
                BEGIN
                    SET @ret = 451;
                    GOTO ExitProc;
                END
                ELSE
                BEGIN
                    -- Validar que el gÃ©nero sea "Hombre" o "Mujer"
                    IF @GENDER NOT IN (N'Hombre', N'Mujer')
                    BEGIN
                        SET @ret = 452; -- CÃ³digo de error para gÃ©nero invÃ¡lido
                        GOTO ExitProc;
                    END

                    -- Validar que el idioma no estÃ© vacÃ­o
                    IF @DEF_LANG IS NULL OR LTRIM(RTRIM(@DEF_LANG)) = ''
                    BEGIN
                        SET @ret = 453; -- CÃ³digo de error para idioma invÃ¡lido
                        GOTO ExitProc;
                    END

                    -- Insertar el nuevo usuario si todas las validaciones son exitosas
                    EXEC @ret = sp_wdev_user_insert 
                                @USERNAME, 
                                @NAME, 
                                @LASTNAME, 
                                @PASSWORD, 
                                @EMAIL, 
                                @GENDER, 
                                @DEF_LANG;

                    IF @@ROWCOUNT > 0
                    BEGIN
                        SET @ret = 0;  
                        GOTO ExitProc;
                    END
                    ELSE
                    BEGIN
                        SET @ret = -1;  
                        GOTO ExitProc;
                    END  
                END
            END
        END
    END

    ExitProc:
    DECLARE @ResponseXML XML;
    EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;
    SELECT @ResponseXML;
END;
*/
CREATE PROCEDURE [dbo].[sp_user_register]
    @USERNAME NVARCHAR(25),
    @NAME NVARCHAR(25),
    @LASTNAME NVARCHAR(50),
    @PASSWORD NVARCHAR(50),
    @EMAIL NVARCHAR(30),
    @GENDER NVARCHAR(10), -- Hombre o Mujer
    @DEF_LANG NVARCHAR(10) -- Idioma predeterminado
AS 
BEGIN
    SET NOCOUNT ON;

    DECLARE @ret INT;
    SET @ret = -1;

    -- Verificar si el usuario ya existe
    IF dbo.fn_user_exists(@USERNAME) = 1
    BEGIN
        SET @ret = 409;
        GOTO ExitProc;
    END
    ELSE
    BEGIN
        -- Verificar si el correo electrónico ya está registrado
        IF dbo.fn_mail_exists(@EMAIL) = 1
        BEGIN
            SET @ret = 408;
            GOTO ExitProc;
        END
        ELSE
        BEGIN
            -- Verificar si el correo electrónico es válido
            IF dbo.fn_mail_isvalid(@EMAIL) = 0
            BEGIN
                SET @ret = 450;
                GOTO ExitProc;
            END
            ELSE
            BEGIN
                -- Verificar la política de contraseña
                IF dbo.fn_pwd_checkpolicy(@PASSWORD) = 0
                BEGIN
                    SET @ret = 451;
                    GOTO ExitProc;
                END
                ELSE
                BEGIN
                    -- Validar que el género sea "Hombre" o "Mujer"
                    IF @GENDER NOT IN (N'Hombre', N'Mujer')
                    BEGIN
                        SET @ret = 452; -- Código de error para género inválido
                        GOTO ExitProc;
                    END

                    -- Validar que el idioma no esté vacío
                    IF @DEF_LANG IS NULL OR LTRIM(RTRIM(@DEF_LANG)) = ''
                    BEGIN
                        SET @ret = 453; -- Código de error para idioma inválido
                        GOTO ExitProc;
                    END

                    -- Insertar el nuevo usuario si todas las validaciones son exitosas
                    EXEC @ret = sp_wdev_user_insert 
                                @USERNAME, 
                                @NAME, 
                                @LASTNAME, 
                                @PASSWORD, 
                                @EMAIL, 
                                @GENDER, 
                                @DEF_LANG;

                    IF @@ROWCOUNT > 0
                    BEGIN
                        SET @ret = 0;  
                        GOTO ExitProc;
                    END
                    ELSE
                    BEGIN
                        SET @ret = -1;  
                        GOTO ExitProc;
                    END  
                END
            END
        END
    END

    ExitProc:
    -- Declarar la variable XML para almacenar la respuesta
    DECLARE @ResponseXML XML;

    -- Asegurarse de que el XML sea válido y esté bien formado
    EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;

    -- Devolver el XML de error bien formado
    SELECT @ResponseXML AS ResponseXML;
END;



GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_check_user_connection]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE   PROCEDURE [dbo].[sp_wdev_check_user_connection]
    @USERNAME NVARCHAR(25),
    @USER_ID INT OUTPUT,
    @DATE_CONNECTED DATETIME OUTPUT,
    @ret INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @ret = -1;

    -- Comprueba si el usuario estÃ¡ conectado
    IF EXISTS (
        SELECT 1 FROM USER_CONNECTIONS WHERE USERNAME = @USERNAME
    )
    BEGIN
        -- ObtÃ©n la informaciÃ³n de la conexiÃ³n
        SELECT 
            @USER_ID = USER_ID, 
            @DATE_CONNECTED = DATE_CONNECTED 
        FROM USER_CONNECTIONS 
        WHERE USERNAME = @USERNAME;

        SET @ret = 100; -- Ã‰xito
    END
    ELSE
    BEGIN
        SET @ret = 405; -- ConexiÃ³n no encontrada
    END
END
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_deletealldata]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- sp_wdev_deletealldata
CREATE   PROCEDURE [dbo].[sp_wdev_deletealldata]
    @USERNAME NVARCHAR(25),
    @PASSWORD NVARCHAR(50)


AS
BEGIN
    DECLARE @ret INT;

    SET @ret= -1;

    
END
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_get_registercode]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_wdev_get_registercode]
    @USERNAME NVARCHAR(25),
    @REGISTER_CODE INT OUTPUT -- ParÃ¡metro de salida para el cÃ³digo de registro
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ret INT;
    SET @ret = -1;

    -- Buscar el cÃ³digo de registro para el usuario dado
    SELECT @REGISTER_CODE = REGISTER_CODE
    FROM USERS
    WHERE USERNAME = @USERNAME;

    -- Verificar si se encontrÃ³ el cÃ³digo de registro
    IF @REGISTER_CODE IS NOT NULL
    BEGIN
        -- Si se encontrÃ³, establecer el cÃ³digo de retorno en 0 (Ã©xito)
        SET @ret = 0;
    END
    ELSE
    BEGIN
        -- Si no se encontrÃ³, establecer el cÃ³digo de retorno en 404 (no encontrado)
        SET @ret = 404;
    END

    -- Obtener el objeto XML de respuesta para el cÃ³digo de error
    DECLARE @ResponseXML XML;
    EXEC sp_xml_error_message @RETURN = @ret, @XmlResponse = @ResponseXML OUTPUT;

    -- Verificar si se encontrÃ³ el cÃ³digo de registro
    IF @ret = 0
    BEGIN
        -- Si todo estÃ¡ bien, incluir el cÃ³digo de registro en el XML de respuesta
        SELECT @REGISTER_CODE;
    END

    -- Devolver el objeto XML de respuesta
    -- SELECT @ResponseXML;
END;




-- EXEC sp_get_registercode @USERNAME="pauallende04",@REGISTER_CODE=0
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_insert_user_connection_history]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE   PROCEDURE [dbo].[sp_wdev_insert_user_connection_history]
    @USER_ID INT,
    @USERNAME NVARCHAR(25),
    @DATE_CONNECTED DATETIME,
    @DATE_DISCONNECTED DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO USER_CONNECTIONS_HISTORY (USER_ID, USERNAME, DATE_CONNECTED, DATE_DISCONNECTED)
    VALUES (@USER_ID, @USERNAME, @DATE_CONNECTED, @DATE_DISCONNECTED);
END
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_update_user_login_status_0]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_wdev_update_user_login_status_0]
    @USERNAME NVARCHAR(25)
AS 
BEGIN
    UPDATE USERS SET LOGIN_STATUS = 0 WHERE USERNAME = @USERNAME;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_user_check_existence]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_wdev_user_check_existence]
    @USERNAME NVARCHAR(25),
    @ret INT OUTPUT,
    @XMLFlag XML OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar si hay datos en el historial de conexiones
    IF EXISTS (SELECT 1 FROM USERS WHERE USERNAME=@USERNAME)
    BEGIN
        -- Si hay datos, convertir el conjunto de resultados a XML
        SET @XMLFlag = (
            SELECT USERNAME, NAME, LASTNAME, EMAIL, GENDER FROM USERS WHERE USERNAME = @USERNAME
            FOR XML PATH('User'), ROOT('Users'), TYPE
        );

        SET @ret=0
    END
    ELSE
    BEGIN
        SET @ret = 505; -- Indicar que hubo resultados
    END
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_user_create_user_connection]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_wdev_user_create_user_connection]
    @USERNAME NVARCHAR(25),
    @CONNECTION_ID UNIQUEIDENTIFIER,
    @ret INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO USER_CONNECTIONS
        (CONNECTION_ID, USER_ID, USERNAME, DATE_CONNECTED)
    VALUES
        (@CONNECTION_ID, (SELECT ID FROM USERS WHERE USERNAME = @USERNAME), @USERNAME, CONVERT(DATETIME, SWITCHOFFSET(SYSDATETIMEOFFSET(), '+01:00')));

    UPDATE USERS SET LOGIN_STATUS = 1 WHERE USERNAME = @USERNAME;

    IF @@ROWCOUNT = 1
    BEGIN
        SET @ret = 0;
    END
    ELSE
    BEGIN
        SET @ret = -1; -- Algo saliÃ³ mal durante la creaciÃ³n de la conexiÃ³n
    END
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_user_get_login_status]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_wdev_user_get_login_status]
    @USERNAME NVARCHAR(25),
    @LOGIN_STATUS BIT OUTPUT,
    @ret INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @LOGIN_STATUS = LOGIN_STATUS
    FROM USERS
    WHERE USERNAME = @USERNAME;

    IF @LOGIN_STATUS = 1
    BEGIN
        SET @ret = 500;
    END
    ELSE
    BEGIN
        SET @ret = 0;
    END
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_user_insert]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[sp_wdev_user_insert]
@USERNAME NVARCHAR(25),
@NAME NVARCHAR(25),
@LASTNAME NVARCHAR(50),
@PASSWORD NVARCHAR(50),
@EMAIL NVARCHAR(30),
@GENDER NVARCHAR(10),    -- Nuevo parámetro para el género
@DEF_LANG NVARCHAR(10)    -- Nuevo parámetro para el idioma predeterminado
AS
BEGIN
    DECLARE @REGISTER_CODE INT;

    -- Generar código de 5 dígitos aleatorio
    SET @REGISTER_CODE = CAST((RAND() * 90000) + 10000 AS INT);

    -- Insertar datos en la tabla USERS, incluyendo los nuevos campos GENDER y DEF_LANG
    INSERT INTO USERS (USERNAME, NAME, LASTNAME, PASSWORD, EMAIL, STATUS, REGISTER_CODE, LOGIN_STATUS, GENDER, DEF_LANG,BALANCE)
    VALUES (@USERNAME, @NAME, @LASTNAME, @PASSWORD, @EMAIL, 1, @REGISTER_CODE, 0, @GENDER, @DEF_LANG,50);

    -- Devolver el código generado
    RETURN @REGISTER_CODE;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_wdev_user_update_password_info]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [dbo].[sp_wdev_user_update_password_info]
    @USERNAME NVARCHAR(50),
    @CURRENT_PASSWORD NVARCHAR(50),
    @NEW_PASSWORD NVARCHAR(50),
    @ret INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @USER_ID INT;

    -- Obtener la informaciÃ³n del usuario
    SELECT 
        @USER_ID = ID
    FROM USERS 
    WHERE USERNAME = @USERNAME;

    -- Guardar la contraseÃ±a anterior en PWD_HISTORY
    INSERT INTO PWD_HISTORY(
        USER_ID,
        USERNAME,
        OLD_PASSWORD, 
        DATE_CHANGED
    ) 
    VALUES (
        @USER_ID,
        @USERNAME, 
        @CURRENT_PASSWORD, 
        DATEADD(HOUR, 1, GETDATE()) -- fecha ajustada a hora espaÃ±ola estÃ¡ndar (UTC+1)
    );

    -- Actualizar la contraseÃ±a del usuario
    UPDATE USERS 
    SET PASSWORD = @NEW_PASSWORD 
    WHERE USERNAME = @USERNAME;
    
    SET @ret = 0;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_xml_error_message]    Script Date: 19/05/2025 18:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_xml_error_message]
    @RETURN INT,
    @XmlResponse XML OUTPUT
AS
BEGIN
    DECLARE @ERROR_CODE INT = @RETURN;
    DECLARE @ERROR_MESSAGE NVARCHAR(200) = 'Unknown Error';
    DECLARE @SEVERITY NVARCHAR(10) = 'Zero';
    DECLARE @CURRENT_TIME DATETIME = GETDATE();
    DECLARE @SERVER_ID NVARCHAR(50) = @@SERVERNAME;
    DECLARE @EXECUTION_TIME NVARCHAR(50) = CAST(DATEDIFF(MILLISECOND, @CURRENT_TIME, GETDATE()) AS NVARCHAR(50)) + ' ms';
    DECLARE @URL NVARCHAR(100) = 'www.ws.mybizum.com';
    DECLARE @METHOD_NAME NVARCHAR(50) = 'sp_xml_error_message';

    -- Obtener mensaje de error de USER_ERRORS si existe
    SELECT @ERROR_MESSAGE = ISNULL(ERROR_MESSAGE, 'Error desconocido')
    FROM USER_ERRORS 
    WHERE ERROR_CODE = @ERROR_CODE;

    -- Determinar severidad
    IF @ERROR_CODE = 0
        SET @SEVERITY = 'Zero';
    ELSE IF @ERROR_CODE BETWEEN 1 AND 13
        SET @SEVERITY = 'Low';
    ELSE IF @ERROR_CODE BETWEEN 400 AND 499
        SET @SEVERITY = 'Medium';
    ELSE IF @ERROR_CODE BETWEEN 500 AND 699
        SET @SEVERITY = 'High';
    ELSE IF @ERROR_CODE >= 700
        SET @SEVERITY = 'Critical';

    -- Construcción del XML según el modelo proporcionado
    SET @XmlResponse = (
        SELECT
            (
                SELECT
                    @SERVER_ID AS 'server_id',
                    CONVERT(NVARCHAR(20), @CURRENT_TIME, 120) AS 'server_time',
                    @EXECUTION_TIME AS 'execution_time',
                    @URL AS 'url',
                    (
                        SELECT
                            @METHOD_NAME AS 'name',
                            (
                                SELECT
                                    'RETURN' AS 'name',
                                    @ERROR_CODE AS 'value'
                                FOR XML PATH('parameter'), TYPE
                            ) AS 'parameters'
                        FOR XML PATH('webmethod'), TYPE
                    ),
                    (
                        SELECT
                            @ERROR_CODE AS 'num_error',
                            @ERROR_MESSAGE AS 'message_error',
                            @SEVERITY AS 'severity',
                            @ERROR_MESSAGE AS 'user_message'
                        FOR XML PATH('error'), TYPE
                    ) AS 'errors'
                FOR XML PATH('head'), TYPE
            ),
            (
                SELECT
                    CASE
                        WHEN @ERROR_CODE = 0 THEN @XmlResponse --'Operation completed successfully'
                        ELSE 'Operation failed'
                    END AS 'response_data'
                FOR XML PATH('body'), TYPE
            )
        FOR XML PATH('ws_response'), TYPE
    );
END;
GO
USE [master]
GO
ALTER DATABASE [PP_DDBB] SET  READ_WRITE 
GO
