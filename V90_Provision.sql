--   EXEC [V90_Core].[SVC].[FindX] 'AUT%', 'Proc';  
--   EXEC [V90_Core].[AUT].[GetIngestionList]; 
/*#*########## 📚 Create Core and Lake ##########*#*/
CREATE DATABASE [V90_Core] COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8
GO
ALTER DATABASE [V90_Core] SET RECOVERY SIMPLE;

USE [V90_Core]
GO
CREATE SCHEMA [AAC]
GO
CREATE SCHEMA [AAM]
GO
CREATE SCHEMA [AUT]
GO
CREATE SCHEMA [HUB]
GO
CREATE SCHEMA [MRT]
GO
CREATE SCHEMA [PAX]
GO
CREATE SCHEMA [SVC]
GO
CREATE SCHEMA [UTL]
GO
CREATE SCHEMA [VPL]
GO
CREATE DATABASE [V90_Lake]  COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8
GO 
ALTER DATABASE [V90_Lake] SET RECOVERY SIMPLE;
GO 
USE [V90_Lake]
GO 
CREATE SCHEMA [AAL]
GO
CREATE SCHEMA [MISC]
GO 
CREATE SCHEMA [APP]
GO
GO 
/*			
    /*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [V90_Core].[SVC].[FindX] '%Config%';

    /*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * 
	FROM [AAL].[Setting]

*/

CREATE VIEW [AAL].[Setting]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

    /*#*========== 🧩 PREPARE ==========*#*/
    WITH cteCfg AS (
		SELECT CONVERT(VARCHAR(50), 'Adelaide Time') AS [CUR_TimeZoneDisplayName]
		,CONVERT(VARCHAR(100), 'Cen. Australia Standard Time') AS [CUR_TimeZoneSystemName]
		,SYSDATETIMEOFFSET() AT TIME ZONE 'UTC' AS [UTC_Time]
        ,CONVERT(VARCHAR(50), 'yyyy-MM-dd') AS [DateStrFormat]
		,CONVERT(VARCHAR(50), 'yyyy-MM-dd HH:mm:ss') AS [TimeStrFormat]
		,CONVERT(VARCHAR(50), 'yyyyMMddTHHmmss') AS [TimeStampFormat]
	)
    ,cteTime AS (
		SELECT o.*
		,DATEADD(DAY, DATEDIFF(DAY, 0, o.[UTC_Time]), 0)  AS [UTC_Date]
		,o.[UTC_Time] AT TIME ZONE o.[CUR_TimeZoneSystemName] AS [CUR_Time]		
		,DATEADD(DAY, DATEDIFF(DAY, 0, o.[UTC_Time] AT TIME ZONE o.[CUR_TimeZoneSystemName]), 0)  AS [CUR_Date]
		FROM cteCfg AS o
	)
	,cteCUR_Date AS (
		SELECT o.*		
		,DATETRUNC(ISO_WEEK, o.[CUR_Date]) AS [CUR_WK]
		,DATETRUNC(MONTH, o.[CUR_Date]) AS [CUR_MTH]
		,DATETRUNC(QUARTER, o.[CUR_Date]) AS [CUR_QTR]
		,DATETRUNC(YEAR, o.[CUR_Date]) AS [CUR_Y]
		,CONVERT(DATETIME, DATEFROMPARTS(CASE WHEN MONTH(o.[CUR_Date]) >= 7 THEN YEAR(o.[CUR_Date]) ELSE YEAR(o.[CUR_Date]) - 1 END, 7, 1 )) AS [CUR_FY]
		FROM cteTime AS o
	)
    ,cteParam AS (
        SELECT o.[CUR_TimeZoneDisplayName] AS [TimeZoneName]           
          ,o.[CUR_Date] AS [CurrentDate]
          ,DATEADD(DAY, -30, [CUR_Date]) AS [CurrentDate-30]
          ,DATEADD(MONTH, DATEDIFF(MONTH, 0, o.[CUR_Date]), 0) AS [CurrentMonth]
		  ,DATEADD(MONTH, DATEDIFF(MONTH, 0, o.[CUR_Date])-3, 0) AS [CurrentMonth-3]
          ,o.[CUR_FY] AS [CurrentFinancialYear]
          ,o.[DateStrFormat]
          ,CONVERT(VARCHAR(50), FORMAT(o.[CUR_Time], 'yyyyMMddTHHmmss')) AS [TimeStampStr]
      FROM cteCUR_Date AS o
    )
    ,cteData AS (
        SELECT o.*
        ,DATEADD(DAY, -1, DATEADD(MONTH, 1, o.[CurrentMonth])) AS [CurrentMonth_End]
        ,DATEADD(DAY, -1, DATEADD(YEAR, 1, o.[CurrentFinancialYear])) AS [CurrentFinancialYear_End]
        FROM cteParam AS o
    )
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.[TimeZoneName]
        ,CONVERT(VARCHAR(50), [TimeStampStr]) AS [TimeStampStr]
        ,CONVERT(VARCHAR(50), [DateStrFormat]) AS [DateStrFormat]
        /*#*---------- 📌 DETAIL ----------*#*/
        ,CONVERT(VARCHAR(50), 'APP') AS [BK_SRC_APP]
        ,CONVERT(DATETIME2(0), o.[CurrentMonth-3]) AS [TranStartDate]
        ,CONVERT(DATETIME2(0), o.[CurrentMonth_End]) AS [TranEndDate]
        /*#*---------- 📌 DETAIL ----------*#*/        
        ,CONVERT(DATETIME2(0), o.[CurrentFinancialYear]) AS [TargetStartDate]
        ,CONVERT(DATETIME2(0), o.[CurrentFinancialYear_End]) AS [TargetEndDate]
        /*#*---------- 📌 DETAIL ----------*#*/
        ,CONVERT(VARCHAR(50), 'MISC') AS [BK_SRC_MISC]
   FROM cteData AS o

/*#*==================== 🔚 ====================*#*/
GO
GO 
/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [V90_Core].[UTL].[FindX] '%Ingestion%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 10 * 
	FROM [AAL].[IngestionParam]
*/
CREATE VIEW [AAL].[IngestionParam]
AS
	/*#*========== 🎯 PURPOSE: Configure the tables for the P101 to P105 extraction processes by source application. ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteData AS (
	SELECT * FROM(
		VALUES
		/*#*---------- 📌 DETAIL: MISC ----------*#*/
		('Upstream', 1,'MISC', '_TPL_REF', 'Template', '[V90_Core].[SVC].[Sample_Ref]', 'Full')
		,('Downstream', 1,'MISC', '_TPL_TRN', 'Template', '[V90_Core].[SVC].[Sample_TranDetail]', 'Full')

		/*#*---------- 📌 DETAIL: APP ----------*#*/
		,('Main', 1,'APP', 'Ref', 'Demo App', '[V90_Core].[SVC].[Sample_Ref]', 'Full')
		,('Main,Zoned', 1,'APP', 'Target', 'Demo App', '[V90_Core].[SVC].[Sample_Target]', 'Partial')
		,('Main', 5,'APP', 'TranHeader', 'Demo App', '[V90_Core].[SVC].[Sample_TranHeader]', 'Partial')
		,('Main', 5,'APP', 'TranDetail', 'Demo App', '[V90_Core].[SVC].[Sample_TranDetail]', 'Partial')
 
		) AS o([ScheduleList],[ProcessNo], [SchemaName], [TableName], [SourceApp], [QN_SourceTable], [Pattern]))
/*#*========== ✅ OUTPUT ==========*#*/
SELECT [ScheduleList] = CONVERT(VARCHAR(500), o.[ScheduleList]) 
	,[ProcessNo] = CONVERT(SMALLINT, o.[ProcessNo])
	,[LakeSchemaName] = CONVERT(VARCHAR(50), o.[SchemaName])
	,[LakeTableName] = CONVERT(VARCHAR(100), o.[TableName])
	,[SourceApp] = CONVERT(VARCHAR(50), o.[SourceApp])
	,[QN_SourceTable] = CONVERT(VARCHAR(100), o.[QN_SourceTable])		
	,[Pattern] = CONVERT(VARCHAR(50), o.[Pattern])
FROM cteData AS o

/*#*==================== 🔚 ====================*#*/
GO

/*#*########## 📚 Sample Data ##########*#*/
CREATE TABLE [MISC].[_TPL_REF](
[zID] VARCHAR(50) NOT NULL,
[zSTMPz] [varchar](50),
[RefCode] [varchar](50),
[RefName] [varchar](100),
[RefDesc] [varchar](200),
[RefCategory] [varchar](20),
[RefType] [varchar](20),
[RefSeq] [int],
[RefNo] [varchar](10),
[RefStatus] [varchar](20)
)
GO 
CREATE TABLE [MISC].[_TPL_TRN](
[zID] VARCHAR(50) NOT NULL,
[zSTMPz] [varchar](50),
[RefCode] [varchar](50),
[RefName] [varchar](100),
[TranNo] [nvarchar](20),
[TranLineNo] [varchar](10),
[TranDate] datetime2(0),
[TUOM] [varchar](10),
[DUOM] [varchar](10),
[CurrCode_TRN] [varchar](10),
[CurrCode_BASE] [varchar](10),
[CurrCode_CON] [varchar](10),
[UC_TUOM_TO_DUOM] [decimal](18, 6),
[Qty_TUOM] [decimal](18, 6),
[Qty_DUOM] [decimal](18, 6),
[UnitCost_TRN_TUOM] [decimal](18, 6),
[UnitPrice_TRN_TUOM] [decimal](18, 6),
[UnitCost_BASE_DUOM] [decimal](18, 6),
[UnitPrice_BASE_DUOM] [decimal](18, 6)
)
GO 

/*#*########## 📚 Core Data ##########*#*/
USE [V90_Core]
GO 

/*???????????????????????????????????????????????????????????????*/
/****** Object:  UserDefinedFunction [UTL].[GetTableListStr_FromScript]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
    DECLARE @SQL VARCHAR(MAX);
    SET @SQL = 'SELECT *
FROM [APP].[TranHeader_FULL] AS o
INNER JOIN [APP].[TranDetail_FULL] AS x ON x.[TranNo] = o.[TranNo] 
INNER JOIN [APP].[Ref] AS rRef ON rRef.[RefCode] = o.[RefCode]
';
    /*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * FROM [UTL].[ListTable_FromScript](@SQL );

    SELECT [UTL].[GetTableListStr_FromScript](@SQL) AS X


*/
CREATE FUNCTION [UTL].[GetTableListStr_FromScript]
(
    @sql NVARCHAR(MAX)    
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @list NVARCHAR(MAX), @delimiter NVARCHAR(10) = N', ';

    SELECT @list =
        COALESCE(
            (SELECT STRING_AGG(x.TableName, @delimiter) WITHIN GROUP (ORDER BY x.TableName)
             FROM [UTL].[ListTable_FromScript](@sql) AS x),
        N'');

    RETURN @list;
END
/*#*==================== 🔚 ====================*#*/

GO
/****** Object:  UserDefinedFunction [UTL].[ListTable_FromScript]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/*
    /*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT *
    FROM [UTL].[ListTable_FromScript]('SELECT *
FROM [APP].[TranHeader_FULL] AS o
INNER JOIN [APP].[TranDetail_FULL] AS x ON x.[TranNo] = o.[TranNo] 
INNER JOIN [APP].[Ref] AS rRef ON rRef.[RefCode] = o.[RefCode]
    ');


*/
CREATE FUNCTION [UTL].[ListTable_FromScript] (@sql NVARCHAR(MAX))
RETURNS @Tables TABLE (TableName NVARCHAR(200))
AS
BEGIN
    IF @sql IS NULL OR LEN(@sql) = 0
        RETURN;

    ---------------------------------------------------------------------
    -- 1) Work with original-case text in @s. We'll make @S=UPPER(@s) later
    ---------------------------------------------------------------------
    DECLARE @s NVARCHAR(MAX) = @sql;

    -- Remove block comments /* ... */
    WHILE 1 = 1
    BEGIN
        DECLARE @a INT = CHARINDEX('/*', @s);
        IF @a = 0 BREAK;

        DECLARE @b INT = CHARINDEX('*/', @s, @a + 2);
        IF @b = 0
        BEGIN
            -- Unclosed comment: drop everything to end
            SET @s = LEFT(@s, @a - 1);
            BREAK;
        END

        SET @s = STUFF(@s, @a, @b - @a + 2, N'');
    END

    -- Remove single-line comments -- ... (until CR or LF or end)
    WHILE 1 = 1
    BEGIN
        DECLARE @c INT = CHARINDEX('--', @s);
        IF @c = 0 BREAK;

        DECLARE @nl1 INT = CHARINDEX(CHAR(10), @s, @c + 2);
        DECLARE @nl2 INT = CHARINDEX(CHAR(13), @s, @c + 2);
        DECLARE @nl  INT =
            CASE
                WHEN @nl1 > 0 AND @nl2 > 0 THEN IIF(@nl1 < @nl2, @nl1, @nl2)
                WHEN @nl1 > 0 THEN @nl1
                WHEN @nl2 > 0 THEN @nl2
                ELSE 0
            END;

        IF @nl = 0
            SET @s = LEFT(@s, @c - 1);
        ELSE
            SET @s = STUFF(@s, @c, @nl - @c, N'');
    END

    -- Remove string literals to avoid false positives (replace with a single space)
    WHILE 1 = 1
    BEGIN
        DECLARE @q1 INT = CHARINDEX('''', @s);
        IF @q1 = 0 BREAK;

        DECLARE @q2 INT = @q1 + 1;
        WHILE @q2 <= LEN(@s)
        BEGIN
            IF SUBSTRING(@s, @q2, 1) = ''''
            BEGIN
                IF @q2 + 1 <= LEN(@s) AND SUBSTRING(@s, @q2 + 1, 1) = ''''
                    SET @q2 = @q2 + 2; -- escaped ''
                ELSE
                    BREAK;
            END
            ELSE
                SET @q2 = @q2 + 1;
        END

        IF @q2 > LEN(@s)
        BEGIN
            -- unclosed string: drop from first quote
            SET @s = LEFT(@s, @q1 - 1);
            BREAK;
        END

        SET @s = STUFF(@s, @q1, @q2 - @q1 + 1, N' ');
    END

    ---------------------------------------------------------------------
    -- 2) Normalize whitespace on @s, then create @S=UPPER(@s) for searching
    ---------------------------------------------------------------------
    SET @s = REPLACE(REPLACE(REPLACE(@s, CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ');
    WHILE CHARINDEX('  ', @s) > 0
        SET @s = REPLACE(@s, '  ', ' ');

    DECLARE @S2 NVARCHAR(MAX) = UPPER(@s);
    DECLARE @len INT = LEN(@S2);

    ---------------------------------------------------------------------
    -- 3) Scan for target clauses in @S; extract tokens from @s (original case)
    ---------------------------------------------------------------------
    DECLARE @i INT = 1;

    WHILE @i <= @len
    BEGIN
        DECLARE @pos INT = 0, @kw NVARCHAR(20) = N'', @klen INT = 0;

        ;WITH K AS
        (
            SELECT ' DELETE FROM ' AS kw, CHARINDEX(' DELETE FROM ', @S, @i) AS pos UNION ALL
            SELECT ' FROM '       , CHARINDEX(' FROM '       , @S, @i)       UNION ALL
            SELECT ' JOIN '       , CHARINDEX(' JOIN '       , @S, @i)       UNION ALL
            SELECT ' UPDATE '     , CHARINDEX(' UPDATE '     , @S, @i)       UNION ALL
            SELECT ' INTO '       , CHARINDEX(' INTO '       , @S, @i)       UNION ALL
            SELECT ' MERGE '      , CHARINDEX(' MERGE '      , @S, @i)       UNION ALL
            SELECT ' USING '      , CHARINDEX(' USING '      , @S, @i)
        )
        SELECT TOP(1)
            @kw = kw, @pos = pos, @klen = LEN(kw)
        FROM K
        WHERE pos > 0
        ORDER BY pos;

        IF @pos = 0 BREAK;

        DECLARE @p INT = @pos + @klen;  -- position right after the keyword

        -- skip spaces
        WHILE @p <= @len AND SUBSTRING(@S, @p, 1) = ' ' SET @p += 1;
        IF @p > @len
        BEGIN
            SET @i = @pos + 1;
            CONTINUE;
        END

        -- skip derived tables: FROM (SELECT ...)
        IF SUBSTRING(@S, @p, 1) <> '('
        BEGIN
            DECLARE @token NVARCHAR(512) = N'';
            DECLARE @segStart INT = @p, @segEnd INT;

            -- first segment (bracketed [..] or bare)
            IF SUBSTRING(@S, @segStart, 1) = '['
            BEGIN
                SET @segEnd = CHARINDEX(']', @S, @segStart + 1);
                IF @segEnd = 0 SET @segEnd = @len;
                SET @token = SUBSTRING(@s, @segStart, @segEnd - @segStart + 1); -- from @s
                SET @p = @segEnd + 1;
            END
            ELSE
            BEGIN
                SET @segEnd = @segStart;
                WHILE @segEnd <= @len
                      AND SUBSTRING(@S, @segEnd, 1) NOT IN (' ', ')', ';', ',', CHAR(9))
                BEGIN
                    SET @segEnd += 1;
                END
                SET @token = SUBSTRING(@s, @segStart, @segEnd - @segStart); -- from @s
                SET @p = @segEnd;
            END

            -- consume multi-part .segments (db.schema.table)
            WHILE @p <= @len AND SUBSTRING(@S, @p, 1) = '.'
            BEGIN
                SET @p += 1; -- skip '.'

                IF SUBSTRING(@S, @p, 1) = '['
                BEGIN
                    SET @segEnd = CHARINDEX(']', @S, @p + 1);
                    IF @segEnd = 0 SET @segEnd = @len;
                    SET @token = @token + N'.' + SUBSTRING(@s, @p, @segEnd - @p + 1); -- from @s
                    SET @p = @segEnd + 1;
                END
                ELSE
                BEGIN
                    DECLARE @wStart INT = @p, @wEnd INT = @p;
                    WHILE @wEnd <= @len
                          AND SUBSTRING(@S, @wEnd, 1) NOT IN (' ', ')', ';', ',', CHAR(9))
                    BEGIN
                        SET @wEnd += 1;
                    END
                    SET @token = @token + N'.' + SUBSTRING(@s, @wStart, @wEnd - @wStart); -- from @s
                    SET @p = @wEnd;
                END
            END

            -- Clean: remove square brackets and double quotes, preserve case
            DECLARE @clean NVARCHAR(512) =
                REPLACE(REPLACE(@token, '[', ''), ']', '');
            SET @clean = REPLACE(@clean, '"', '');

            -- Filter non-table tokens
            IF @clean <> N''
               AND LEFT(@clean, 1) <> '@'           -- not a variable
               AND LEFT(@clean, 1) <> '#'           -- not a temp table
               AND CHARINDEX('(', @clean) = 0       -- not a function call
               AND @clean NOT IN (N'SELECT', N'VALUES')
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM @Tables WHERE TableName = @clean)
                    INSERT INTO @Tables(TableName) VALUES (@clean); -- original case
            END
        END

        SET @i = @pos + 1; -- advance
    END

    RETURN;
END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [SVC].[Dev_RandomSample]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Dev%';
	
	SELECT  * 
	FROM [SVC].[Dev_RandomSample]
	ORDER BY 1,2,3

*/
CREATE VIEW [SVC].[Dev_RandomSample]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/	
    WITH cteParams AS (
        SELECT [StartDate] = DATEADD(DAY, -7, CAST(GETDATE() AS DATE)) 
            ,[EndDate] = CAST(GETDATE() AS DATE)
            ,[Rows] = 100
            ,[Length] = 3
    )    
    , cteWords AS  (
        SELECT a.Word, ABS(CHECKSUM(NEWID())) % 1000 AS WordOrder
        ,ROW_NUMBER() OVER ( ORDER BY ABS(CHECKSUM(NEWID()))) -1 AS Id
        FROM (VALUES
            ('Ant'), ('Bear'), ('Bee'), ('Bird'), ('Buffalo'),
            ('Camel'), ('Cat'), ('Cheetah'), ('Chicken'), ('Chimpanzee'),
            ('Cow'), ('Crocodile'), ('Deer'), ('Dog'), ('Dolphin'),
            ('Duck'), ('Eagle'), ('Elephant'), ('Falcon'), ('Fish'),
            ('Fox'), ('Frog'), ('Giraffe'), ('Goat'), ('Goose'),
            ('Hippopotamus'), ('Horse'), ('Hyena'), ('Jaguar'), ('Kangaroo'),
            ('Leopard'), ('Lion'), ('Lizard'), ('Monkey'), ('Moose'),
            ('Mouse'), ('Octopus'), ('Owl'), ('Panda'), ('Parrot'),
            ('Pig'), ('Rabbit'), ('Raccoon'), ('Rat'), ('Seal'),
            ('Shark'), ('Sheep'), ('Snake'), ('Tiger'), ('Wolf')
        ) AS a(Word)
    )
    ,cteData AS (
        SELECT x.[value] AS [Id]
        ,[RandomDate] = DATEADD(
                DAY,
                ABS(CHECKSUM(NEWID())) % (DATEDIFF(DAY, o.[StartDate], o.[EndDate]) + 1),
                o.[StartDate]
            )
        ,[RandomNo] = LEFT(CONVERT(VARCHAR(10), ABS(CHECKSUM(NEWID()))), o.[Length])        
        ,[RandomInt1] = CONVERT(INT, LEFT(CONVERT(VARCHAR(50), ABS(CHECKSUM(NEWID()))), o.[Length]))
        ,[RandomInt2] = CONVERT(INT, LEFT(CONVERT(VARCHAR(50), ABS(CHECKSUM(NEWID()))), o.[Length]))
        ,[RandomDec1] = CONVERT(DECIMAL(18,4), ABS(CHECKSUM(NEWID())) / 1.1  %  POWER(10, o.[Length]))
        ,[RandomDec2] = CONVERT(DECIMAL(18,4), ABS(CHECKSUM(NEWID())) / 1.1  %  POWER(10, o.[Length]))
        FROM cteParams AS o
        CROSS APPLY GENERATE_SERIES(1,o.[Rows]) AS x
    )
    /*#*========== ✅ OUTPUT ==========*#*/
    SELECT o.[Id]
        ,o.[RandomDate]
        ,FORMAT(o.[RandomDate], 'yyyy-MM-dd') AS [RandomDateStr]
        ,o.[RandomNo]
        ,[RandomText] = CONVERT(VARCHAR(50),  w.[Word])
        ,o.[RandomInt1]
        ,o.[RandomInt2]
        ,o.[RandomDec1]
        ,o.[RandomDec2]
        ,[RandomSeqByDay] = ROW_NUMBER() OVER (PARTITION BY o.[RandomDate] ORDER BY o.[RandomNo])
        ,[RandomSeqByDayAndText] = ROW_NUMBER() OVER (PARTITION BY o.[RandomDate], w.[Word] ORDER BY o.[RandomNo])
    FROM cteData AS o
    LEFT JOIN cteWords AS w ON w.[Id] = o.[Id] % 50

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [SVC].[Sample_TranDetail]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO














/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Sample%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT  * 
	FROM [SVC].[Sample_TranDetail] AS o
	ORDER BY 4,5

*/
CREATE VIEW [SVC].[Sample_TranDetail]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteData AS (		
		SELECT TOP 100 [Id]
			,[RandomText] AS [Code]
			,[RandomText] + ' Name' AS [Name]			
			,o.[RandomDate] AS [TranDate]
			,o.[RandomDateStr] AS [TranDateStr]
			,o.[RandomInt1] AS [Qty]
			,o.[RandomDec1] / 100 AS [Cost]
			,o.[RandomDec2] / 100 AS [Value]
			,ROUND(o.[RandomInt2], -2) AS [UC]
			,[TranNo] = 'T' + FORMAT(o.[RandomDate], 'yyMMdd') + '_' + CONVERT(VARCHAR(10),o.[RandomSeqByDay])
		FROM [SVC].[Dev_RandomSample] AS o
	)
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.[Code] AS [RefCode]
		,o.[Name] AS [RefName]
		,o.[TranNo]
		,[TranLineNo] = 'L1'
		,o.[TranDate]
		,CONVERT(VARCHAR(10), 'CT') AS [TUOM]
		,CONVERT(VARCHAR(10), 'EA') AS [DUOM]
		,CONVERT(VARCHAR(10), 'AUD') AS [CurrCode_TRN]
		,CONVERT(VARCHAR(10), 'AUD') AS [CurrCode_BASE]
		,CONVERT(VARCHAR(10), 'USD') AS [CurrCode_CON]
		,CONVERT(DECIMAL(18,6), o.[UC]) AS [UC_TUOM_TO_DUOM]
		,CONVERT(DECIMAL(18,6), o.[Qty]) AS [Qty_TUOM]
		,CONVERT(DECIMAL(18,6), o.[Qty] * o.[UC]) AS [Qty_DUOM]
		,CONVERT(DECIMAL(18,6), o.[Cost]) AS [UnitCost_TRN_TUOM]
		,CONVERT(DECIMAL(18,6), o.[Value]) AS [UnitPrice_TRN_TUOM]
		,CONVERT(DECIMAL(18,6), o.[Cost] / o.[UC]) AS [UnitCost_BASE_DUOM]
		,CONVERT(DECIMAL(18,6), o.[Value] / o.[UC]) AS [UnitPrice_BASE_DUOM]
	FROM cteData AS o	
	
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [SVC].[Sample_TranHeader]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO












/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Sample%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT  * 
	FROM [SVC].[Sample_TranHeader] AS o
	ORDER BY 1,2

*/
CREATE VIEW [SVC].[Sample_TranHeader]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteData AS (		
		SELECT TOP 100 [Id]
			,[RandomText] AS [Code]
			,[RandomText] + ' Name' AS [Name]			
			,o.[RandomDate] AS [TranDate]
			,o.[RandomDateStr] AS [TranDateStr]
			,o.[RandomInt1] AS [Qty]
			,o.[RandomDec1] / 100 AS [Cost]
			,o.[RandomDec2] / 100 AS [Value]
			,ROUND(o.[RandomInt2], -2) AS [UC]
			,[TranNo] = 'T' + FORMAT(o.[RandomDate], 'yyMMdd') + '_' + CONVERT(VARCHAR(10),o.[RandomSeqByDay])
		FROM [SVC].[Dev_RandomSample] AS o
	)
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.[Code] AS [RefCode]
		,o.[Name] AS [RefName]
		,o.[TranNo]
		,MAX(o.[TranDate]) AS [TranDate]
	FROM cteData AS o	
	GROUP BY o.[Code], o.[Name], o.[TranNo]
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [SVC].[Sample_Ref]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO













/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Sample%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT  * 
	FROM [SVC].[Sample_Ref] AS o
	ORDER BY 1,2

*/
CREATE VIEW [SVC].[Sample_Ref]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteData AS (
		SELECT MAX(o.[Id]) AS [Id]
			,[RandomText] AS [Code]
			,[RandomText] + ' Name' AS [Name]
			,[RandomText] + ' Description' AS [Desc]
			,MAX([RandomNo]) AS [No]
			,'Category ' + LEFT([RandomText],1) AS [Category]
			,'Type ' + LEFT(MAX([RandomNo]),1) AS [Type]
		FROM [SVC].[Dev_RandomSample] AS o
		GROUP BY o.[RandomText]
	)
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.[Code] AS [RefCode]
		,o.[Name] AS [RefName]
		,o.[Desc] AS [RefDesc]
		,CONVERT(VARCHAR(20), o.[Category]) AS [RefCategory]
		,CONVERT(VARCHAR(20), o.[Type]) AS [RefType]
		,o.[Id] AS [RefSeq]
		,o.[No] AS [RefNo]
		,CONVERT(VARCHAR(20), CASE WHEN CONVERT(INT, [No]) % 3 = 0 THEN 'Active' ELSE 'Inactive' END) AS [RefStatus]
	FROM cteData AS o

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [SVC].[Sample_Target]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO














/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Sample%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT  * 
	FROM [SVC].[Sample_Target] AS o
	ORDER BY 4,5

*/
CREATE VIEW [SVC].[Sample_Target]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteData AS (		
		SELECT TOP 100 [Id]
			,[RandomText] AS [Code]
			,[RandomText] + ' Name' AS [Name]			
			,o.[RandomDate] AS [TranDate]
			,o.[RandomDateStr] AS [TranDateStr]
			,o.[RandomInt1] AS [Qty]
			,o.[RandomDec1] / 100 AS [Cost]
			,o.[RandomDec2] / 100 AS [Value]
			,ROUND(o.[RandomInt2], -2) AS [UC]
			,[TranNo] = 'T' + FORMAT(o.[RandomDate], 'yyMMdd') + '_' + CONVERT(VARCHAR(10),o.[RandomSeqByDay])
		FROM [SVC].[Dev_RandomSample] AS o
	)
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.[Code] AS [RefCode]
		,o.[Name] AS [RefName]
		,o.[TranDate] AS [TargetDate]
		,CONVERT(VARCHAR(10), 'EA') AS [DUOM]
		,SUM(CONVERT(DECIMAL(18,6), o.[Qty] * o.[UC])) AS [Qty_DUOM]		
	FROM cteData AS o	
	GROUP BY o.[Code], o.[Name], o.[TranDate]

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  Table [AUT].[IngestionParam]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [AUT].[IngestionParam](
	[zID] [varchar](50) NULL,
	[zUPD] [datetime2](0) NULL,
	[BK_DE] [varchar](100) NULL,
	[BK_DE_OG] [varchar](100) NULL,
	[OF_ASAT] [datetime2](0) NULL,
	[OF_ALL] [smallint] NULL,
	[ScheduleName] [varchar](50) NULL,
	[IngestionSeq] [smallint] NULL,
	[StepName] [varchar](50) NULL,
	[StepSeq] [smallint] NULL,
	[ProcessCode] [varchar](50) NULL,
	[LakeSchemaName] [varchar](100) NULL,
	[LakeTableName] [varchar](100) NULL,
	[QN_LakeTable] [varchar](200) NULL,
	[QN_LakeTable_Group] [varchar](200) NULL,
	[SourceApp] [varchar](50) NULL,
	[QN_SourceTable] [varchar](100) NULL,
	[ScheduleList] [varchar](500) NULL,
	[Pattern] [varchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [UTL].[GetLakeQuery_FULL]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






/*
    /*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT *
    FROM [UTL].[GetLakeQuery_FULL]('Lake', 'MISC', '_TPL_REF'
    ,'MISC','[Core].[SVC].[Sample_Ref]'
	,'2026-02-06T11:00:00'
    );


	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 10 x.*	
	FROM [UTL].[Setting] AS o 
    CROSS APPLY [UTL].[GetLakeQuery_FULL]([LakeName], 'APP', 'Ref'
    ,'MISC', o.[QN_Core] + '.[SVC].[Sample_Ref]'
    ,FORMAT([CurrentTime], [TimeStampFormat])
    ) AS x

*/
CREATE FUNCTION [UTL].[GetLakeQuery_FULL]
(
    @Lake VARCHAR(100)
    ,@SchemaName VARCHAR(100)
    ,@TableName VARCHAR(100)
    ,@Source VARCHAR(100)
    ,@QN_SourceTable VARCHAR(500)
	,@TimeStampStr VARCHAR(100)
)
RETURNS TABLE
AS
RETURN
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
    WITH cteParam AS (
		SELECT [Lake] = @Lake
			,[SchemaName] = @SchemaName
			,[TableName]  = @TableName
			,[Source] = @Source
			,[QN_SourceTable] = @QN_SourceTable
			,[SourceTablePreparation]  = ''
			,[SourceTableCondidtion]  = ''
			,[TimeStampStr]  = @TimeStampStr
    )
	/*#*========== 🧩 PREPARE ==========*#*/
    ,cteTable AS (
		SELECT o.*
			/*#*---------- 📌 DETAIL ----------*#*/
			,[CreationQuery_Template] = CONVERT(VARCHAR(4000), 'SELECT NEWID() AS zID, ''#SOURCE#@#TIMESTAMP#'' AS zSTMPz, o.*  
INTO #LAKE#.#FULL# 
FROM #SOURCE_TABLE# AS o 
')
			,[IngestionQuery_Template] = CONVERT(VARCHAR(4000), 'TRUNCATE TABLE #LAKE#.#FULL#; 
#PREPARATION#  
INSERT #LAKE#.#FULL# 
SELECT NEWID() AS zID, ''#SOURCE#@#TIMESTAMP#'' AS zSTMPz, o.*  FROM #SOURCE_TABLE# AS o 
#CONDITION# ; 
')
			/*#*---------- 📌 DETAIL ----------*#*/
			,[ExtractionQuery_Template] = CONVERT(VARCHAR(4000), ' #PREPARATION# 
SELECT NEWID() AS zID, ''#SOURCE#@#TIMESTAMP#'' AS zSTMPz, o.* FROM #SOURCE_TABLE# AS o 
#CONDITION# ;
')
			/*#*---------- 📌 DETAIL ----------*#*/
			,[ValidationQuery_Template] = CONVERT(VARCHAR(4000), 'SELECT * FROM #LAKE#.#FULL#; ')
		FROM cteParam AS o
	)
	/*#*========== 🧩 PREPARE ==========*#*/
	, cteCN_Table AS (
		SELECT o.*
			,QUOTENAME(o.[Lake]) AS [QN_Lake]
			,QUOTENAME(o.[SchemaName]) + '.' + QUOTENAME(o.[TableName]) AS [QN_Table_FULL]
			--,o.[QN_SourceTable] AS [QN_SourceTable]
		FROM cteTable AS o
	)
	/*#*========== 🧩 PREPARE ==========*#*/
	,cteQuery AS (
		SELECT o.*
		/*#*---------- 📌 DETAIL ----------*#*/
		,[ValidationQuery] = REPLACE(REPLACE(o.[ValidationQuery_Template]
		, '#LAKE#', o.[QN_Lake])
		, '#FULL#', o.[QN_Table_FULL])
		/*#*---------- 📌 DETAIL ----------*#*/
		,[CreationQuery] = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(o.[CreationQuery_Template]
			, '#LAKE#', o.[QN_Lake]) 
			, '#FULL#', o.[QN_Table_FULL])
			, '#SOURCE#', o.[Source]) 
			, '#SOURCE_TABLE#', o.[QN_SourceTable]) 
			, '#TIMESTAMP#', o.[TimeStampStr])				
		/*#*---------- 📌 DETAIL ----------*#*/
		,[IngestionQuery] = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(o.[IngestionQuery_Template]
			, '#LAKE#', o.[QN_Lake]) 
			, '#FULL#', o.[QN_Table_FULL])
			, '#SOURCE#', o.[Source]) 
			, '#SOURCE_TABLE#', o.[QN_SourceTable]) 
			, '#PREPARATION#', o.[SourceTablePreparation])
			, '#CONDITION#', o.[SourceTableCondidtion])
			, '#TIMESTAMP#', o.[TimeStampStr])
		/*#*---------- 📌 DETAIL ----------*#*/
		,[ExtractionQuery] = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([ExtractionQuery_Template]
			,'#SOURCE#', o.[Source])
			,'#SOURCE_TABLE#', o.[QN_SourceTable])
			, '#PREPARATION#', o.[SourceTablePreparation])
			, '#CONDITION#', o.[SourceTableCondidtion] )
			, '#TIMESTAMP#', o.[TimeStampStr])
		FROM cteCN_Table AS o
	)

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT CONVERT(VARCHAR(100), o.[SchemaName]) AS [SchemaName]
		,CONVERT(VARCHAR(100), o.[TableName]) AS [TableName]
		,CONVERT(VARCHAR(200), o.[QN_Table_FULL]) AS [QN_Table_FULL]
		,CONVERT(VARCHAR(200), o.[QN_SourceTable]) AS [QN_SourceTable]
		,CONVERT(VARCHAR(4000), o.[ValidationQuery]) AS [ValidationQuery]
		,CONVERT(VARCHAR(4000), o.[CreationQuery]) AS [CreationQuery]		
		,CONVERT(VARCHAR(4000), o.[IngestionQuery]) AS [IngestionQuery]
		,CONVERT(VARCHAR(4000), o.[ExtractionQuery]) AS [ExtractionQuery]
	FROM cteQuery AS o

/*#*==================== 🔚 ====================*#*/

GO
/****** Object:  View [UTL].[Setting]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO














/*			
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Setting%';
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * 
	FROM [UTL].[Setting]

*/
CREATE VIEW [UTL].[Setting]
AS	
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteData AS (
		SELECT 'V90_Core' AS [CoreName]
		,'V90_Lake' AS [LakeName]
		/*#*---------- 📌 DETAIL ----------*#*/
		,'Adelaide Time' AS [DefaultTimeZoneDisplayName]
		,'Cen. Australia Standard Time' AS [DefaultTimeZoneSystemName]		
		/*#*---------- 📌 DETAIL ----------*#*/
		,[HelpCentreName] = 'ℹ️ Help Centre'
		,[ActivityMonitorName] = '🔔 Activity Monitor'
		,[PipelineRunName] = '✅ Pipeline Runs'
		,[HelpCentreLink] = 'https://app.powerbi.com/groups/me/apps/#APP_ID#/dashboards/#DASHBOARD_ID#?experience=power-bi'
		,[ActivityMonitorLink] = 'https://app.powerbi.com/groups/me/apps/#APP_ID#/dashboards/#DASHBOARD_ID#?experience=power-bi'
		,[PipelineRunLink] = 'https://app.powerbi.com/workloads/data-pipeline/monitoring/workspaces/#WORKSPACE_ID#/pipelines/#PIPELINE_NAME#/#PIPELINE_RUN_ID#?experience=power-bi'
		,[EmailBodyTemplate] = '<html><head> 
<style type="text/css"> body, div {font-family: Calibri, Arial, sans-serif; font-size: 16px; color: #333; } 
.box { margin: 10px 0 50px 0;} 
.btn {display: block; width: 200px; padding: 5px; margin-top: 20px; text-align: center; background-color: #e3e7e8; border: 1px solid #ccc;  border-radius: 5px; cursor: pointer; color: #000; text-decoration: none; } 
a { color: #000; text-decoration: none; } .failed {color: #ee2e24;}
.more{}
</style>
</head>
<body>
<div class="box">#CONTENT#</div>
<div class="box">#BUTTONS#</div>
<div class="box"></div>
</body></html>'
	)
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT CONVERT(VARCHAR(50), CASE WHEN CHARINDEX('_', o.[LakeName]) > 0 
		THEN LEFT(o.[LakeName], CHARINDEX('_', o.[LakeName]) - 1)
        ELSE o.[LakeName]
    END) AS [System]
		,CONVERT(VARCHAR(50), o.[LakeName]) AS [LakeName]
		,CONVERT(VARCHAR(50), o.[CoreName]) AS [CoreName]
		,CONVERT(VARCHAR(50), QUOTENAME(o.[LakeName])) AS [QN_Lake]
		,CONVERT(VARCHAR(50), QUOTENAME(o.[CoreName])) AS [QN_Core]
		/*#*---------- 📌 DETAIL ----------*#*/
		,CONVERT(VARCHAR(100), 'vincentduan@hotmail.com') AS [AdminEmail]
		/*#*---------- 📌 DETAIL ----------*#*/
		,CONVERT(VARCHAR(50), o.[HelpCentreName]) AS [HelpCentreName]
		,CONVERT(VARCHAR(50), o.[ActivityMonitorName]) AS [ActivityMonitorName]
		,CONVERT(VARCHAR(50), o.[PipelineRunName]) AS [PipelineRunName]
		/*#*---------- 📌 DETAIL ----------*#*/
		,CONVERT(VARCHAR(500), o.[HelpCentreLink]) AS [HelpCentreLink]
		,CONVERT(VARCHAR(500), o.[ActivityMonitorLink]) AS [ActivityMonitorLink]
		,CONVERT(VARCHAR(500), o.[PipelineRunLink]) AS [PipelineRunLink]		
		/*#*---------- 📌 DETAIL ----------*#*/
		,CONVERT(VARCHAR(50), o.[DefaultTimeZoneDisplayName]) AS [DefaultTimeZoneDisplayName]
		,CONVERT(VARCHAR(100), o.[DefaultTimeZoneSystemName]) AS [DefaultTimeZoneSystemName]
		,[UTC_Time] = CONVERT(DATETIME2(3), (SYSDATETIMEOFFSET() AT TIME ZONE 'UTC' ) ) 
		,[CurrentTime] = CONVERT(DATETIME2(3), (SYSDATETIMEOFFSET() AT TIME ZONE o.[DefaultTimeZoneSystemName]))
		/*#*---------- 📌 DETAIL ----------*#*/
		,CONVERT(VARCHAR(50), 'yyyy-MM-dd') AS [DateStrFormat]
		,CONVERT(VARCHAR(50), 'yyyy-MM-dd HH:mm:ss') AS [TimeStrFormat]
		,CONVERT(VARCHAR(50), 'yyyyMMddTHHmmss') AS [TimeStampFormat]
		/*#*---------- 📌 DETAIL ----------*#*/
		,[EmailBodyTemplate] = CONVERT(VARCHAR(4000), REPLACE(o.[EmailBodyTemplate], '#BUTTONS#', 
			'<a class="btn" href="'+  [HelpCentreLink] +'">' + [HelpCentreName] + '</a>'
			+ '<a class="btn" href="'+  [ActivityMonitorLink] +'">' + [ActivityMonitorName] + '</a>'
			+ '<a class="btn" href="'+  [PipelineRunLink] +'">' + [PipelineRunName] + '</a>'	
			))
	FROM cteData AS o

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  Table [AUT].[IngestionPartialQuery]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [AUT].[IngestionPartialQuery](
	[zID] [varchar](50) NOT NULL,
	[zUPD] [datetime2](3) NULL,
	[BK_DE] [varchar](100) NULL,
	[QN_TableGroup] [varchar](500) NULL,
	[SchemaName] [varchar](100) NULL,
	[TableName] [varchar](100) NULL,
	[QN_Table_FULL] [varchar](200) NULL,
	[QN_Table_PARTIAL] [varchar](200) NULL,
	[QN_Table_OVERLAP] [varchar](200) NULL,
	[QN_SourceTable] [varchar](200) NULL,
	[ValidationQuery] [varchar](max) NULL,
	[IngestionQuery_FULL] [varchar](max) NULL,
	[IngestionQuery_PARTIAL] [varchar](max) NULL,
	[ExtractionQuery] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  View [AUT].[IngestionList]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%AUT%', 'View';

	SELECT TOP 1000 * 
	-- SELECT * 
	FROM [AUT].[IngestionList] AS o
    WHERE 1=1
    --AND [SourceApp] = 'Demo App' AND [StepName] = 'Standard' AND ProcessCode = 'P001'
	ORDER BY 1,2,3

*/
CREATE VIEW [AUT].[IngestionList]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
    WITH cteVariable AS (
        SELECT o.[DefaultTimeZoneDisplayName],o.[DefaultTimeZoneSystemName]
        ,FORMAT(o.[CurrentTime], o.[TimeStampFormat]) AS [TimeStampStr]
        ,o.[LakeName],o.[CoreName]
		,o.[QN_Lake],o.[QN_Core]
        FROM [UTL].[Setting] AS o
    )
    ,cteTableWithFullQuery AS (
        SELECT o.[ScheduleName]
            ,o.[IngestionSeq]
            ,o.[StepName]
            ,o.[StepSeq]
            ,o.[ProcessCode]
            ,o.[LakeSchemaName]
            ,o.[LakeTableName]
            ,o.[QN_LakeTable]
            ,o.[QN_LakeTable_Group]
            ,o.[Pattern]
            ,o.[SourceApp]
            ,o.[QN_SourceTable]            
            ,x.[IngestionQuery]
            ,x.[ExtractionQuery]
            ,x.[CreationQuery]
        FROM [AUT].[IngestionParam] AS o
        CROSS JOIN cteVariable AS v
        CROSS APPLY [UTL].[GetLakeQuery_FULL](v.[LakeName], o.[LakeSchemaName], o.[LakeTableName]
        ,o.[SourceApp], o.[QN_SourceTable], v.[TimeStampStr]) AS x
        WHERE o.[OF_ALL] = 0
    )
    ,cteQuery_PARTIAL AS (
        SELECT o.[QN_Table_FULL] AS [QN_LakeTable], o.[IngestionQuery_FULL] AS [IngestionQuery], '' AS [ExtractionQuery]
        FROM [AUT].[IngestionPartialQuery] AS o
        UNION 
        SELECT o.[QN_Table_PARTIAL] AS [QN_LakeTable], o.[IngestionQuery_PARTIAL] AS [IngestionQuery], o.[ExtractionQuery]
        FROM [AUT].[IngestionPartialQuery] AS o
    )
    
    /*#*========== ✅ OUTPUT ==========*#*/
    SELECT o.[SourceApp]
        ,o.[ScheduleName]
        ,o.[IngestionSeq]
        ,o.[StepName]
        ,o.[StepSeq]
        ,o.[ProcessCode]
        ,o.[LakeSchemaName]
        ,o.[LakeTableName]        
        ,o.[QN_SourceTable]
        ,o.[QN_LakeTable]
        ,o.[QN_LakeTable_Group]
        ,o.[Pattern]
        ,ISNULL(x.[QN_LakeTable], o.[QN_LakeTable]) AS [QN_TableGroup]
        ,ISNULL(x.[IngestionQuery], o.[IngestionQuery]) AS [IngestionQuery]
        ,ISNULL(x.[ExtractionQuery], o.[ExtractionQuery]) AS [ExtractionQuery]
        ,o.[CreationQuery]
    FROM cteTableWithFullQuery AS o    
	LEFT JOIN [cteQuery_PARTIAL] AS x ON x.[QN_LakeTable] = o.[QN_LakeTable]

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  Table [MRT].[_TPL_REF]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [MRT].[_TPL_REF](
	[zID] [varchar](50) NOT NULL,
	[zUPD] [datetime2](3) NULL,
	[BK_SRC] [varchar](20) NULL,
	[BK_DE] [varchar](100) NULL,
	[BK_DE_OG] [varchar](100) NULL,
	[DV_A] [varchar](50) NULL,
	[DV_B] [varchar](50) NULL,
	[DV_C] [varchar](50) NULL,
	[EntityCode] [varchar](50) NULL,
	[EntityName] [varchar](100) NULL,
	[EntityDesc] [varchar](100) NULL,
	[EntityCategory] [varchar](50) NULL,
	[EntityType] [varchar](50) NULL,
	[EntityStatus] [varchar](50) NULL,
	[EntityNo] [varchar](50) NULL,
	[EntitySeq] [varchar](50) NULL,
	[CX_DE] [varchar](max) NULL,
	[DL_DE] [varchar](500) NULL,
	[CA_zStatus] [varchar](50) NULL,
	[CA_zFlag] [smallint] NULL,
	[CA_zLock] [varchar](500) NULL,
	[CA_zMemo] [varchar](500) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  View [AAM].[_TPL_REF]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
















/*			
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%TPL_REF%';
	
	SELECT TOP 100 * 
	-- SELECT COUNT(*)
	FROM [AAM].[_TPL_REF]


*/
CREATE VIEW [AAM].[_TPL_REF]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.[zID]
      ,o.[BK_SRC]
      ,o.[BK_DE]
      ,o.[DV_A]
      ,o.[DV_B]
      ,o.[DV_C]
      ,o.[EntityCode]
      ,o.[EntityName]
      ,o.[EntityDesc]
      ,o.[EntityCategory]
      ,o.[EntityType]
      ,o.[EntityStatus]
      ,o.[EntityNo]
      ,o.[EntitySeq]
      /*#*---------- 📌 DETAIL ----------*#*/
      ,JSON_VALUE(o.[CX_DE], '$.Lake.ExtA') AS ExtA
      /*#*---------- 📌 DETAIL ----------*#*/
      ,o.[DL_DE]
      /*#*---------- 📌 DETAIL ----------*#*/
      ,o.[CA_zStatus] AS [zStatus]
      ,o.[CA_zFlag] AS [zFlag]
      ,o.[CA_zLock] AS [zLock]
      ,o.[CA_zMemo] AS [zMemo]      
  FROM [MRT].[_TPL_REF] AS o
  WHERE [CA_zStatus] = 'Valid'

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  Table [MRT].[_TPL_TRN]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [MRT].[_TPL_TRN](
	[zID] [varchar](50) NOT NULL,
	[zUPD] [datetime2](3) NULL,
	[BK_SRC] [varchar](20) NULL,
	[BK_DE] [varchar](100) NULL,
	[BK_DE_OG] [varchar](100) NULL,
	[BK_Tran] [varchar](100) NULL,
	[BK_Entity] [varchar](100) NULL,
	[BK_Entity_OG] [varchar](100) NULL,
	[DV_A] [varchar](50) NULL,
	[DV_B] [varchar](50) NULL,
	[DV_C] [varchar](50) NULL,
	[EntityCode] [varchar](50) NULL,
	[EntityName] [varchar](100) NULL,
	[TranNo] [varchar](100) NULL,
	[TranLineNo] [varchar](20) NULL,
	[TranDate] [datetime2](0) NULL,
	[TUOM] [varchar](50) NULL,
	[DUOM] [varchar](50) NULL,
	[CurrCode_TRN] [varchar](50) NULL,
	[CurrCode_BASE] [varchar](50) NULL,
	[CurrCode_CON] [varchar](50) NULL,
	[UC_TUOM_TO_DUOM] [decimal](18, 6) NULL,
	[Qty_TUOM] [decimal](18, 6) NULL,
	[Qty_DUOM] [decimal](18, 6) NULL,
	[UnitCost_TRN_TUOM] [decimal](18, 6) NULL,
	[UnitPrice_TRN_TUOM] [decimal](18, 6) NULL,
	[UnitCost_BASE_DUOM] [decimal](18, 6) NULL,
	[UnitPrice_BASE_DUOM] [decimal](18, 6) NULL,
	[CA_BK_Date] [datetime2](7) NULL,
	[CA_Qty_DUOM] [decimal](18, 6) NULL,
	[CA_Cost_BASE] [decimal](18, 6) NULL,
	[CA_Value_BASE] [decimal](18, 6) NULL,
	[CA_Margin_BASE] [decimal](18, 6) NULL,
	[CA_Cost_CON] [decimal](18, 6) NULL,
	[CA_Value_CON] [decimal](18, 6) NULL,
	[CA_Margin_CON] [decimal](18, 6) NULL,
	[CA_MarginRatio] [decimal](18, 6) NULL,
	[CA_MarginBand] [varchar](50) NULL,
	[CA_zStatus] [varchar](50) NULL,
	[CA_zFlag] [smallint] NULL,
	[CA_zLock] [varchar](500) NULL,
	[CA_zMemo] [varchar](500) NULL
) ON [PRIMARY]
GO
/****** Object:  View [AAM].[MST_DV_A]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
















/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%DV%', 'View';

	SELECT TOP 1000 * 
	-- SELECT * 
	FROM [AAM].[MST_DV_A] AS o
	ORDER BY 1,2,3

*/
CREATE VIEW [AAM].[MST_DV_A]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteData AS (
		SELECT *
		FROM (VALUES
			/*#*---------- 📌 DETAIL: Framework ----------*#*/
			('G1', 'Business Group 1', 'Valid')
			,('G2', 'Business Group 1', 'Invalid')
		) AS o ([Code], [Name], [Status])
	)

	SELECT CONVERT(VARCHAR(100), o.[Code]) AS [DV_A]
			,CONVERT(VARCHAR(100), o.[Name]) AS [DV_A_Name]
			,CONVERT(VARCHAR(2000), o.[Status]) AS [DV_A_Status]
	FROM cteData AS o
	WHERE o.[Status] = 'Valid'

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [AAM].[MST_DV_B]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
















/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%DV%', 'View';

	SELECT TOP 1000 * 
	-- SELECT * 
	FROM [AAM].[MST_DV_B] AS o
	ORDER BY 1,2,3

*/
CREATE VIEW [AAM].[MST_DV_B]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteData AS (
		SELECT *
		FROM (VALUES
			/*#*---------- 📌 DETAIL: Framework ----------*#*/
			('AU', 'Australia', 'Valid')
			,('NZ', 'New Zealand', 'Invalid')
		) AS o ([Code], [Name], [Status])
	)

	SELECT CONVERT(VARCHAR(100), o.[Code]) AS [DV_B]
			,CONVERT(VARCHAR(100), o.[Name]) AS [DV_B_Name]
			,CONVERT(VARCHAR(2000), o.[Status]) AS [DV_B_Status]
	FROM cteData AS o
	WHERE o.[Status] = 'Valid'

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [AAM].[MST_DV_C]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
















/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%DV%', 'View';

	SELECT TOP 1000 * 
	-- SELECT * 
	FROM [AAM].[MST_DV_C] AS o
	ORDER BY 1,2,3

*/
CREATE VIEW [AAM].[MST_DV_C]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteData AS (
		SELECT *
		FROM (VALUES
			/*#*---------- 📌 DETAIL: Framework ----------*#*/
			('DOM', 'Domestic', 'Valid') 
			,('INT', 'International', 'Invalid')
		) AS o ([Code], [Name], [Status])
	)

	SELECT CONVERT(VARCHAR(100), o.[Code]) AS [DV_C]
			,CONVERT(VARCHAR(100), o.[Name]) AS [DV_C_Name]
			,CONVERT(VARCHAR(2000), o.[Status]) AS [DV_C_Status]
	FROM cteData AS o
	WHERE o.[Status] = 'Valid'

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [AAM].[_TPL_TRN]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




















/*			
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%_TPL_TRN%';
	
	SELECT TOP 100 * 
	-- SELECT COUNT(*)
	FROM [AAM].[_TPL_TRN] AS o


*/
CREATE VIEW [AAM].[_TPL_TRN]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.[zID]
      ,o.[BK_SRC]
      ,o.[BK_DE]
      ,o.[BK_Tran]
      ,o.[BK_Entity]
      /*#*---------- 📌 DETAIL ----------*#*/
      ,o.[CA_BK_Date] AS [BK_Date]
      /*#*---------- 📌 DETAIL ----------*#*/
      ,o.[DV_A], rDV_A.[DV_A_Name]
      ,o.[DV_B], rDV_B.[DV_B_Name]
      ,o.[DV_C], rDV_C.[DV_C_Name]
      ,o.[EntityCode]
      ,o.[EntityName]
      ,o.[TranNo]
      ,o.[TranDate]
      ,o.[TUOM]
      ,o.[DUOM]
      ,o.[CurrCode_TRN]
      ,o.[CurrCode_BASE]
      ,o.[CurrCode_CON]
      ,o.[UC_TUOM_TO_DUOM]
      ,o.[Qty_TUOM]
      ,o.[Qty_DUOM]
      ,o.[UnitCost_TRN_TUOM]
      ,o.[UnitPrice_TRN_TUOM]
      ,o.[UnitCost_BASE_DUOM]
      ,o.[UnitPrice_BASE_DUOM]
      /*#*---------- 📌 DETAIL ----------*#*/
      ,o.[CA_Qty_DUOM]
      ,o.[CA_Cost_BASE]
      ,o.[CA_Value_BASE]
      ,o.[CA_Margin_BASE]
      ,o.[CA_Cost_CON]
      ,o.[CA_Value_CON]
      ,o.[CA_MarginBand] AS [MarginBand]
      /*#*---------- 📌 DETAIL ----------*#*/
      ,o.[CA_zStatus] AS [zStatus]
      ,o.[CA_zFlag] AS [zFlag]
      ,o.[CA_zLock] AS [zLock]
      ,o.[CA_zMemo] AS [zMemo]      
  FROM [MRT].[_TPL_TRN] AS o
  INNER JOIN [AAM].[MST_DV_A] AS rDV_A ON rDV_A.[DV_A] = o.[DV_A]
  INNER JOIN [AAM].[MST_DV_B] AS rDV_B ON rDV_B.[DV_B] = o.[DV_B]
  INNER JOIN [AAM].[MST_DV_C] AS rDV_C ON rDV_C.[DV_C] = o.[DV_C]
  INNER JOIN [AAM].[_TPL_REF] AS rREF ON rREF.[BK_DE] = o.[BK_Entity]

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [AAC].[_TPL_TRN]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



















/*			
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%_TPL_TRN%';
	
	SELECT TOP 100 * 
	-- SELECT COUNT(*)
	FROM [AAC].[_TPL_TRN] AS o


*/
CREATE VIEW [AAC].[_TPL_TRN]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.[zID]
      ,o.[BK_SRC]
      ,o.[BK_DE]
      ,o.[BK_Tran]
      ,o.[BK_Entity]
      /*#*---------- 📌 DETAIL ----------*#*/
      ,o.[BK_Date]
      /*#*---------- 📌 DETAIL ----------*#*/
      ,o.[DV_A]
      ,o.[DV_B]
      ,o.[DV_C]
      ,o.[EntityCode] AS [Entity Code]
      ,o.[EntityName] AS [Entity Name]
      ,o.[TranNo] AS [Tran No]
      ,o.[TranDate] AS [Tran Date]
      ,o.[TUOM] AS [TUOM]
      ,o.[DUOM] AS [DUOM]
      ,o.[CurrCode_TRN]  AS [Curr Code TRN]
      ,o.[CurrCode_BASE] AS [Curr Code BASE]
      ,o.[CurrCode_CON] AS [Curr Code CON]
      /*#*---------- 📌 DETAIL ----------*#*/
      ,o.[CA_Qty_DUOM]
      ,o.[CA_Cost_BASE]
      ,o.[CA_Value_BASE]
      ,o.[CA_Margin_BASE]
      ,o.[CA_Cost_CON]
      ,o.[CA_Value_CON]
      ,o.[MarginBand] AS [Margin Band]
      /*#*---------- 📌 DETAIL ----------*#*/
      ,o.[zStatus]
      ,o.[zFlag]
      ,o.[zLock]
      ,o.[zMemo]
  FROM [AAM].[_TPL_TRN] AS o


/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  Table [UTL].[Log]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [UTL].[Log](
	[zID] [varchar](50) NOT NULL,
	[zUPD] [datetime2](3) NULL,
	[ID_Paired] [varchar](50) NULL,
	[System] [varchar](50) NULL,
	[Component] [varchar](50) NULL,
	[Controller] [varchar](100) NULL,
	[Action] [varchar](500) NULL,
	[RunBy] [varchar](500) NULL,
	[RunTime] [datetime2](3) NULL,
	[RunTime_UTC] [datetime2](3) NULL,
	[Status] [varchar](50) NULL,
	[Message] [varchar](500) NULL,
	[Detail] [varchar](4000) NULL
) ON [PRIMARY]
GO
/****** Object:  View [UTL].[LogPaired]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








/*			
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Log%';
	
	SELECT TOP 100 * 
	-- SELECT COUNT(*)
	FROM [UTL].[LogPaired] AS o
	WHERE 1=1
	--AND ID_Paired = '0DA00A1C-C967-4775-96B5-A020ADCDED75'
	AND [Priority] = 'Critical'
	ORDER BY StartTime Desc

	SELECT TOP 100 * 
	-- SELECT COUNT(*)
	FROM [UTL].[Log] AS o
	WHERE 1=1
	AND ID_Paired = '0DA00A1C-C967-4775-96B5-A020ADCDED75'
	ORDER BY RunTime Desc

*/
CREATE VIEW [UTL].[LogPaired]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteSeq AS (
		SELECT [zID],[ID_Paired]
		,ROW_NUMBER() OVER (PARTITION BY [ID_Paired] ORDER BY o.[RunTime]) AS [Seq_Asc]
		,ROW_NUMBER() OVER (PARTITION BY [ID_Paired] ORDER BY o.[RunTime] DESC) AS [Seq_Desc]
		FROM [UTL].[Log] AS o
		INNER JOIN [UTL].[Setting] AS x ON x.[System] = o.[System]
    )
	/*#*---------- 📌 DETAIL ----------*#*/
	, cteKey AS (
		SELECT o.[zID] AS [zID_Start], x.[zID] AS [zID_End]
		,o.[ID_Paired]
		FROM cteSeq AS o
		LEFT JOIN cteSeq AS x ON o.[ID_Paired] = x.[ID_Paired] AND x.[Seq_Desc] = 1
		WHERE o.[Seq_Asc] = 1
	)
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT pk.[ID_Paired], pk.[zID_Start], pk.[zID_End]
		,rStart.[System]
		,CASE WHEN CHARINDEX('*', rStart.[Controller]) > 0 THEN LEFT(rStart.[Controller], CHARINDEX('*', rStart.[Controller]) - 1) ELSE rStart.[Controller] END AS [Controller]	
		,rStart.[Action]
		,[Action_NoTag] = CASE WHEN rStart.[Action] LIKE '{%}%' THEN TRIM(SUBSTRING(rStart.[Action], CHARINDEX('}', rStart.[Action]) + 1, LEN(rStart.[Action]))) ELSE rStart.[Action] END
		/*#*---------- 📌 DETAIL ----------*#*/
		,[Type] = CONVERT(VARCHAR(50), CASE WHEN rEnd.[zID] IS NULL THEN 'Unpaired' ELSE 'Paired' END)
		,[Priority] = CONVERT(VARCHAR(50), CASE WHEN CHARINDEX('CRITICAL', rStart.[Message]) > 0 THEN 'Critical'
				  ELSE 'Standard' END)
		/*#*---------- 📌 DETAIL ----------*#*/
		,CONVERT(VARCHAR(50), FORMAT(rStart.[RunTime], 'HH:mm:ss')) AS [StartTime]
		,CONVERT(VARCHAR(50), FORMAT(rEnd.[RunTime], 'HH:mm:ss')) AS [EndTime]
		,DATEDIFF(SECOND, rStart.[RunTime], rEnd.[RunTime]) AS [DurationSeconds]
		,CONVERT(VARCHAR(50), CASE WHEN DATEDIFF(SECOND, rStart.[RunTime], rEnd.[RunTime]) > 60 THEN FORMAT(DATEDIFF(SECOND, rStart.[RunTime], rEnd.[RunTime])/60.0, '0.0') + ' mins' 
				ELSE FORMAT( DATEDIFF(SECOND, rStart.[RunTime], rEnd.[RunTime]), '0') + ' secs' END) AS [Duration]
		,CONVERT(DATE,rStart.[RunTime]) AS [RunDate]
		,rStart.[RunTime]
		,rStart.[RunBy]
		,rStart.[Message]
	FROM cteKey AS pk
	INNER JOIN [UTL].[Log] AS rStart ON rStart.[zID] = pk.[zID_Start]
	LEFT JOIN [UTL].[Log] AS rEnd ON rEnd.[zID] = pk.[zID_End]
  

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  Table [UTL].[Calendar]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [UTL].[Calendar](
	[zID] [varchar](50) NOT NULL,
	[zUPD] [datetime2](3) NULL,
	[DateInt] [int] NULL,
	[DateStr] [varchar](50) NULL,
	[DateKey] [datetime2](0) NULL,
	[DateName] [varchar](50) NULL,
	[DateFullName] [varchar](50) NULL,
	[DayOfWeekKey] [smallint] NULL,
	[DayOfWeekName] [varchar](50) NULL,
	[DayOfMonthKey] [smallint] NULL,
	[DayOfYearKey] [smallint] NULL,
	[DayOfHalfYearKey] [smallint] NULL,
	[DayOfQuarterKey] [smallint] NULL,
	[DayOfFinancialQuarterKey] [smallint] NULL,
	[YearKey] [datetime2](0) NULL,
	[YearName] [varchar](50) NULL,
	[HalfYearKey] [datetime2](0) NULL,
	[HalfYearName] [varchar](50) NULL,
	[QuarterKey] [datetime2](0) NULL,
	[QuarterName] [varchar](50) NULL,
	[QuarterFullName] [varchar](50) NULL,
	[MonthKey] [datetime2](0) NULL,
	[MonthName] [varchar](50) NULL,
	[MonthFullName] [varchar](50) NULL,
	[MonthOfYearKey] [smallint] NULL,
	[MonthOfYearName] [varchar](50) NULL,
	[WeekKey] [datetime2](0) NULL,
	[WeekName] [varchar](50) NULL,
	[WeekFullName] [varchar](50) NULL,
	[WeekOfYearKey] [smallint] NULL,
	[MonthOfQuarterKey] [smallint] NULL,
	[FinancialYearKey] [datetime2](0) NULL,
	[FinancialYearName] [varchar](50) NULL,
	[FinancialPeriod] [varchar](50) NULL,
	[FinancialYearKey_April] [datetime2](0) NULL,
	[FinancialYearName_April] [varchar](50) NULL,
	[FinancialPeriod_April] [varchar](50) NULL,
	[MonthOfFinancialYearKey] [smallint] NULL,
	[MonthOfFinancialYearKey_April] [smallint] NULL,
	[FinancialQuarterKey] [datetime2](0) NULL,
	[FinancialQuarterName] [varchar](50) NULL,
	[FinancialQuarterFullName] [varchar](50) NULL,
	[MonthOfFinancialQuarterKey] [smallint] NULL,
	[FinancialPeriod_January] [varchar](50) NULL,
	[TotalDays_Month] [smallint] NULL,
	[TotalDays_Year] [smallint] NULL,
	[DaysElapsed_Month] [smallint] NULL,
	[DaysElapsed_Year] [smallint] NULL,
	[WeekdayCount] [smallint] NULL,
	[TotalWeekdays_Month] [smallint] NULL,
	[TotalWeekdays_Year] [smallint] NULL,
	[WeekdaysElapsed_Month] [smallint] NULL,
	[WeekdaysElapsed_Year] [smallint] NULL,
	[WeekdaysElapsedRate_Month] [decimal](18, 8) NULL,
	[DaysElapsedRate_Month] [decimal](18, 8) NULL,
	[WeekdaysElapsedRate_Year] [decimal](18, 8) NULL,
	[DaysElapsedRate_Year] [decimal](18, 8) NULL,
	[CA_DayOffset] [smallint] NULL,
	[CA_WeekOffset] [smallint] NULL,
	[CA_MonthOffset] [smallint] NULL,
	[CA_QuarterOffset] [smallint] NULL,
	[CA_YearOffset] [smallint] NULL,
	[CA_WeekOffset_ByThursday] [smallint] NULL,
	[CA_FinancialYearOffset] [smallint] NULL,
	[CA_FinancialQuarterOffset] [smallint] NULL,
	[CA_DayOffset_Category] [varchar](50) NULL,
	[CA_WeekOffset_Category] [varchar](50) NULL,
	[CA_MonthOffset_Category] [varchar](50) NULL,
	[CA_QuarterOffset_Category] [varchar](50) NULL,
	[CA_FinancialQuarterOffset_Category] [varchar](50) NULL,
	[CA_YearOffset_Category] [varchar](50) NULL,
	[CA_FinancialYearOffset_Category] [varchar](50) NULL,
	[CA_DayOffset_Category_Simple] [varchar](50) NULL,
	[CA_WeekOffset_Category_Simple] [varchar](50) NULL,
	[CA_MonthOffset_Category_Simple] [varchar](50) NULL,
	[CA_QuarterOffset_Category_Simple] [varchar](50) NULL,
	[CA_FinancialQuarterOffset_Category_Simple] [varchar](50) NULL,
	[CA_YearOffset_Category_Simple] [varchar](50) NULL,
	[CA_FinancialYearOffset_Category_Simple] [varchar](50) NULL,
	[CA_DayOffset_Category_Default] [varchar](50) NULL,
	[CA_WeekOffset_Category_Default] [varchar](50) NULL,
	[CA_MonthOffset_Category_Default] [varchar](50) NULL,
	[CA_QuarterOffset_Category_Default] [varchar](50) NULL,
	[CA_FinancialQuarterOffset_Category_Default] [varchar](50) NULL,
	[CA_YearOffset_Category_Default] [varchar](50) NULL,
	[CA_FinancialYearOffset_Category_Default] [varchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  View [AAM].[Calendar]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





/*			
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Calendar%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * 
	FROM [AAM].[Calendar]
	ORDER BY 1,2,3

	/*#*---------- 🔍 EXAMPLE ----------*#*/
	SELECT x.MonthOfFinancialYearKey
	FROM [AAM].[Calendar] AS x 
	WHERE x.[DateKey] = DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0)
	ORDER BY 1,2,3

*/
CREATE VIEW [AAM].[Calendar]
AS
/*#*{Classification},{Reporting View},{Views}*#*/	
	SELECT o.[DateKey] AS [Day] 
		,o.[DateName] AS [DateName] 
		,o.[YearKey] 
		,o.[QuarterKey] 
		,o.[MonthKey] 
		,o.[WeekKey] 
		,o.[DayOfWeekKey] 
		,o.[DayOfMonthKey]
		,o.[YearName] AS [Year] 
		,o.[QuarterName] AS [Quarter] 
		,o.[MonthKey] AS [Month] 
		,o.[WeekName] AS [Week] 
		,o.[DayOfWeekName] AS [DayOfWeek]	 
		,o.[MonthOfYearKey] 
		,o.[MonthOfYearName] AS [MonthOfYear] 
		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[DateFullName] AS [DateFullName] 
		,o.[WeekFullName] AS [WeekFullName] 
		,o.[QuarterFullName] AS [QuarterFullName] 
		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[CA_YearOffset] AS [YearOffset] 
		,CASE WHEN o.[CA_YearOffset] = - 1 THEN 'Yes' ELSE 'No' END AS [LastYear] 
		,CASE WHEN o.[CA_YearOffset] = 0 THEN 'Yes' ELSE 'No' END AS [CurrentYear] 	
		/*#*---------- 📌 DETAIL ----------*#*/
		,CASE WHEN o.[CA_QuarterOffset] = 0 THEN 'Yes' ELSE 'No' END AS [CurrentQuarter]
		,CASE WHEN o.[CA_QuarterOffset] = -1 THEN 'Yes' ELSE 'No' END AS [LastQuarter]
		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[CA_MonthOffset] AS [MonthOffset] 	
		,CASE WHEN o.[CA_MonthOffset] BETWEEN 0 AND 3 THEN 'Yes' ELSE 'No' END AS [Forward4Months] 	
		,CASE WHEN o.[CA_MonthOffset] BETWEEN 1 AND 3 THEN 'Yes' ELSE 'No' END AS [Next3Months] 	
		,CASE WHEN o.[CA_MonthOffset] BETWEEN - 3 AND -1 THEN 'Yes' ELSE 'No' END AS [Previous3Months] 	
		,CASE WHEN o.[CA_MonthOffset] BETWEEN - 3 AND 0 THEN 'Yes' ELSE 'No' END AS [Rolling4Months] 	
		,CASE WHEN o.[CA_MonthOffset] BETWEEN - 11	AND 0 THEN 'Yes' ELSE 'No' END AS [Rolling12Months] 
		,CASE WHEN o.[CA_MonthOffset] BETWEEN - 12 AND 0 THEN 'Yes' ELSE 'No' END AS [Rolling13Months] 
		,CASE WHEN o.[CA_MonthOffset] BETWEEN - 13 AND 0 THEN 'Yes' ELSE 'No' END AS [Rolling14Months] 
		,CASE WHEN o.[CA_MonthOffset] BETWEEN - 23 AND 0 THEN 'Yes' ELSE 'No' END AS [Rolling24Months] 
		,CASE WHEN o.[CA_MonthOffset] BETWEEN - 24 AND 0 THEN 'Yes' ELSE 'No' END AS [Rolling25Months] 
		,CASE WHEN o.[CA_MonthOffset] BETWEEN - 35 AND 0 THEN 'Yes' ELSE 'No' END AS [Rolling36Months] 
		,CASE WHEN o.[CA_MonthOffset] = 0 THEN 'Yes' ELSE 'No' END AS [CurrentMonth] 
		,CASE WHEN o.[CA_MonthOffset] = - 1 THEN 'Yes' ELSE 'No' END AS [LastMonth] 
	
		,CASE WHEN o.[CA_MonthOffset] BETWEEN - 12 AND - 1 THEN 'Yes' ELSE 'No' END AS [Previous12Months] 
		,CASE WHEN o.[CA_MonthOffset] BETWEEN - 13 AND - 1 THEN 'Yes' ELSE 'No' END AS [Previous13Months] 
		,CASE WHEN o.[CA_MonthOffset] BETWEEN - 14 AND - 1 THEN 'Yes' ELSE 'No' END AS [Previous14Months] 
		,CASE WHEN o.[CA_MonthOffset] BETWEEN - 24 AND - 1 THEN 'Yes' ELSE 'No' END AS [Previous24Months]
		,CASE WHEN o.[CA_MonthOffset] BETWEEN - 14 AND - 2 THEN 'Yes' ELSE 'No' END AS [Previous13Months_ByLastMonth] 	
	
	
		,CASE WHEN o.[CA_MonthOffset] BETWEEN 0 AND 5 THEN 'Yes' ELSE 'No' END AS [Next6Months] 
		,CASE WHEN o.[CA_MonthOffset] BETWEEN 0 AND 9 THEN 'Yes' ELSE 'No' END AS [Next10Months] 
		,CASE WHEN o.[CA_MonthOffset] BETWEEN 0 AND 11 THEN 'Yes' ELSE 'No' END AS [Next12Months] 
		,CASE WHEN o.[CA_MonthOffset] BETWEEN 0 AND 12 THEN 'Yes' ELSE 'No' END AS [Next13Months] 	
		,CASE WHEN o.[CA_MonthOffset] BETWEEN 1 AND 12 THEN 'Yes' ELSE 'No' END AS [Next12Months_ByNextMonth]
	
		,CASE WHEN o.[CA_MonthOffset] BETWEEN 1 AND 6 THEN 'Yes' ELSE 'No' END AS [Future6Months] 
		,CASE WHEN o.[CA_MonthOffset] BETWEEN 1 AND 10 THEN 'Yes' ELSE 'No' END AS [Future10Months] 
		,CASE WHEN o.[CA_MonthOffset] BETWEEN 1 AND 12 THEN 'Yes' ELSE 'No' END AS [Future12Months] 
		,CASE WHEN o.[CA_MonthOffset] BETWEEN 1 AND 13 THEN 'Yes' ELSE 'No' END AS [Future13Months]
	
		,CASE WHEN o.[CA_MonthOffset] BETWEEN -6 AND 6 THEN 'Yes' ELSE 'No' END AS [Previous6AndNext6Months]

		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[CA_WeekOffset] AS [WeekOffset] 
		,o.[WeekdayCount]
		,CASE WHEN o.[CA_WeekOffset] = - 1 THEN 'Yes' ELSE 'No' END AS [LastWeek]
		,CASE WHEN o.[CA_WeekOffset] = 0 THEN 'Yes' ELSE 'No' END AS [CurrentWeek]
		,CASE WHEN o.[CA_WeekOffset] = 1 THEN 'Yes' ELSE 'No' END AS [NextWeek]	
		,CASE WHEN o.[CA_WeekOffset] BETWEEN -10 AND -1 THEN 'Yes' ELSE 'No' END AS [Previous10Weeks]
		,CASE WHEN o.[CA_WeekOffset] BETWEEN -9 AND 0 THEN 'Yes' ELSE 'No' END AS [Rolling10Weeks]
		,CASE WHEN o.[CA_WeekOffset] BETWEEN -12 AND -1 THEN 'Yes' ELSE 'No' END AS [Previous12Weeks]
		,CASE WHEN o.[CA_WeekOffset] BETWEEN -13 AND -1 THEN 'Yes' ELSE 'No' END AS [Previous13Weeks]
		,CASE WHEN o.[CA_WeekOffset] BETWEEN -52 AND -1 THEN 'Yes' ELSE 'No' END AS [Previous52Weeks]
		,CASE WHEN o.[CA_WeekOffset] BETWEEN -104 AND -1 THEN 'Yes' ELSE 'No' END AS [Previous104Weeks]

		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[CA_DayOffset] AS [DayOffset]
		,CASE WHEN o.[CA_DayOffset] BETWEEN - 7 AND - 1 THEN 'Yes' ELSE 'No' END AS [Last7Days] 
		,CASE WHEN o.[CA_DayOffset] BETWEEN - 30 AND - 1 THEN 'Yes' ELSE 'No' END AS [Last30Days] 
		,CASE WHEN o.[CA_DayOffset] = - 1 THEN 'Yes' ELSE 'No' END AS [Yesterday] 
		,CASE WHEN o.[CA_DayOffset] = 0 THEN 'Yes' ELSE 'No' END AS [Today] 
		,CASE WHEN o.[CA_DayOffset] = 1 THEN 'Yes' ELSE 'No' END AS [Tomorrow] 
		,CASE WHEN o.[CA_DayOffset] BETWEEN 1 AND 30 THEN 'Yes' ELSE 'No' END AS [Next30Days] 
		,CASE WHEN o.[CA_DayOffset] BETWEEN - 6 AND 0 THEN 'Yes' ELSE 'No' END AS [Rolling7Days] 
		,CASE WHEN o.[CA_DayOffset] BETWEEN - 7 AND 0 THEN 'Yes' ELSE 'No' END AS [Rolling8Days] 
		,CASE WHEN o.[CA_DayOffset] BETWEEN - 30 AND 0 THEN 'Yes' ELSE 'No' END AS [Rolling31Days] 	
		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[CA_FinancialYearOffset] AS [FinancialYearOffset] 


		,CASE WHEN o.[CA_FinancialYearOffset] = - 1 THEN 'Yes' ELSE 'No' END AS [LastFinancialYear] 
		,CASE WHEN o.[CA_FinancialYearOffset] = 0 THEN 'Yes' ELSE 'No' END AS [CurrentFinancialYear]
		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[CA_FinancialQuarterOffset] AS [FinancialQuarterOffset]
		,CASE WHEN o.[CA_FinancialQuarterOffset] = 0 THEN 'Yes' ELSE 'No' END AS [CurrentFinancialQuarter] 
		,o.[FinancialQuarterKey]
		,o.[FinancialQuarterName]
		,o.[FinancialQuarterFullName]
		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[FinancialYearKey]
		,o.[FinancialYearName]
		,o.[MonthOfFinancialYearKey]
		,o.[FinancialPeriod]
		,o.[FinancialYearKey_April]
		,o.[FinancialYearName_April]
		,o.[MonthOfFinancialYearKey_April] 
		,o.[FinancialPeriod_April]	
		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[CA_DayOffset_Category] AS [DayCategory]
		,o.[CA_YearOffset_Category] AS [YearCategory]
		,o.[CA_QuarterOffset_Category] AS [QuarterCategory] 
		,o.[CA_MonthOffset_Category] AS [MonthCategory]
		,o.[CA_WeekOffset_Category] AS [WeekCategory]
		,o.[CA_FinancialYearOffset_Category] AS [FinancialYearCategory]
		,o.[CA_FinancialQuarterOffset_Category] AS [FinancialQuarterCategory] 
		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[CA_DayOffset_Category_Simple] AS [DayCategory_Simple]
		,o.[CA_YearOffset_Category_Simple] AS [YearCategory_Simple]
		,o.[CA_QuarterOffset_Category_Simple] AS [QuarterCategory_Simple] 
		,o.[CA_MonthOffset_Category_Simple] AS [MonthCategory_Simple]
		,o.[CA_WeekOffset_Category_Simple] AS [WeekCategory_Simple]
		,o.[CA_FinancialYearOffset_Category_Simple] AS [FinancialYearCategory_Simple]
		,o.[CA_FinancialQuarterOffset_Category_Simple] AS [FinancialQuarterCategory_Simple] 
		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[CA_DayOffset_Category_Default] AS [DayCategory_Default]
		,o.[CA_YearOffset_Category_Default] AS [YearCategory_Default]
		,o.[CA_QuarterOffset_Category_Default] AS [QuarterCategory_Default] 
		,o.[CA_MonthOffset_Category_Default] AS [MonthCategory_Default]
		,o.[CA_WeekOffset_Category_Default] AS [WeekCategory_Default]
		,o.[CA_FinancialYearOffset_Category_Default] AS [FinancialYearCategory_Default]
		,o.[CA_FinancialQuarterOffset_Category_Default] AS [FinancialQuarterCategory_Default] 	

	  FROM [UTL].[Calendar] AS o


/*#*==================== 🔚 ====================*#*/

GO
/****** Object:  View [AAC].[_TPL_Calendar]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%_TPL_Calendar%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 10 * 
	-- SELECT COUNT(*)
	FROM [AAC].[_TPL_Calendar]
	ORDER BY 1,2,3

*/
CREATE VIEW [AAC].[_TPL_Calendar]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.[Day]
      ,o.[YearKey]
      ,o.[QuarterKey]
      ,o.[MonthKey]
      ,o.[WeekKey]
      ,o.[DayOfWeekKey]
      ,o.[DayOfMonthKey]
      ,o.[Year]
      ,o.[Quarter]
      ,o.[Month]
      ,o.[Week]
      ,o.[DayOfWeek] AS [Day of Week]
      ,o.[MonthOfYearKey]
      ,o.[MonthOfYear] AS [Month of Year]
      ,o.[DateFullName] AS [Date Full]
      ,o.[WeekFullName] AS [Week Full]
      ,o.[QuarterFullName] AS [Quarter Full]
      ,o.[YearOffset] AS [Year Offset]
      ,o.[YearCategory] AS [Year Category]
      ,o.[LastYear] AS [Last Year]
      ,o.[CurrentYear] AS [Current Year]
      ,o.[CurrentQuarter] AS [Current Quarter]
      ,o.[LastQuarter] AS [Last Quarter]
      ,o.[QuarterCategory] AS [Quarter Category]
      ,o.[MonthOffset] AS [Month Offset]
      ,o.[MonthCategory] AS [Month Category]
      ,o.[MonthCategory_Simple] AS [Month Category Simple]
      ,o.[MonthCategory_Default] AS [Month Category Default]
      ,o.[Forward4Months] AS [Forward 4 Months]
      ,o.[Next3Months] AS [Next 3 Months]
      ,o.[Previous3Months] AS [Previous 3 Months]
      ,o.[Rolling4Months] AS [Rolling 4 Months]
      ,o.[Rolling12Months] AS [Rolling 12 Months]
      ,o.[Rolling13Months] AS [Rolling 13 Months]
      ,o.[Rolling14Months] AS [Rolling 14 Months]
      ,o.[Rolling24Months] AS [Rolling 24 Months]
      ,o.[Rolling25Months] AS [Rolling 25 Months]
      ,o.[Rolling36Months] AS [Rolling 36 Months]
      ,o.[CurrentMonth] AS [Current Month]
      ,o.[LastMonth] AS [Last Month]
      ,o.[Previous12Months] AS [Previous 12 Months]
      ,o.[Previous13Months] AS [Previous 13 Months]
      ,o.[Previous14Months] AS [Previous 14 Months]
      ,o.[Previous24Months] AS [Previous 24 Months]
      ,o.[Previous13Months_ByLastMonth] AS [Previous 13 Months By Last Month]
      ,o.[Next6Months] AS [Next 6 Months]
      ,o.[Next10Months] AS [Next 10 Months]
      ,o.[Next12Months] AS [Next 12 Months]
      ,o.[Next13Months] AS [Next 13 Months]
      ,o.[Next12Months_ByNextMonth] AS [Next 12 Months By Next Month]
      ,o.[Future6Months] AS [Future 6 Months]
      ,o.[Future10Months] AS [Future 10 Months]
      ,o.[Future12Months] AS [Future 12 Months]
      ,o.[Future13Months] AS [Future 13 Months]
      ,o.[Previous6AndNext6Months] AS [Previous 6 And Next 6 Months]
      ,o.[WeekOffset] AS [Week Offset]
      ,o.[WeekCategory] AS [Week Category]
      ,o.[LastWeek] AS [Last Week]
      ,o.[CurrentWeek] AS [Current Week]
      ,o.[NextWeek] AS [Next Week]
      ,o.[Previous10Weeks] AS [Previous 10 Weeks]
      ,o.[Rolling10Weeks] AS [Rolling 10 Weeks]
      ,o.[Previous12Weeks] AS [Previous 12 Weeks]
      ,o.[Previous13Weeks] AS [Previous 13 Weeks]
      ,o.[Previous52Weeks] AS [Previous 52 Weeks]
      ,o.[Previous104Weeks] AS [Previous 104 Weeks]      
      ,o.[DayOffset] AS [Day Offset]
      ,o.[DayCategory] AS [Day Category]
      ,o.[DayCategory_Simple] AS [Day Category Simple]
      ,o.[DayCategory_Default] AS [Day Category Default]
      ,o.[Last7Days] AS [Last 7 Days]
      ,o.[Last30Days] AS [Last 30 Days]
      ,o.[Yesterday]
      ,o.[Today]
      ,o.[Tomorrow]
      ,o.[Next30Days] AS [Next 30 Days]
      ,o.[Rolling7Days] AS [Rolling 7 Days]
      ,o.[Rolling8Days] AS [Rolling 8 Days]
      ,o.[Rolling31Days] AS [Rolling 31 Days]
      ,o.[FinancialYearOffset] AS [Financial Year Offset]
      ,o.[FinancialYearCategory] AS [Financial Year Category]
      ,o.[FinancialYearCategory_Simple] AS [Financial Year Category Simple]
      ,o.[FinancialYearCategory_Default] AS [Financial Year Category Default]
      ,o.[LastFinancialYear] AS [Last Financial Year]
      ,o.[CurrentFinancialYear] AS [Current Financial Year]
      ,o.[FinancialQuarterOffset] AS [Financial Quarter Offset]
      ,o.[FinancialQuarterCategory] AS [Financial Quarter Category]
      ,o.[CurrentFinancialQuarter] AS [Current Financial Quarter]
      ,o.[FinancialQuarterKey]
      ,o.[FinancialQuarterName] AS [Financial Quarter]
      ,o.[FinancialQuarterFullName] AS [Financial Quarter Full]
      ,o.[FinancialYearKey]
      ,o.[FinancialYearName] AS [Financial Year]
      ,o.[FinancialPeriod] AS [Financial Period]	   
  FROM [AAM].[Calendar] AS o  
  WHERE o.[FinancialYearOffset] BETWEEN -3 AND 1


/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [AAC].[Variable]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







/*			
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%_TPL_TRN%';
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT *
	FROM [AAC].[Variable] AS o

*/
CREATE VIEW [AAC].[Variable]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteParam AS (
        SELECT [System]
          ,[AdminEmail]
          ,[UTC_Time]
          ,[CurrentTime]
          ,FORMAT([CurrentTime], o.[TimeStrFormat]) AS [CurrentTimeStr]
          ,[DayName] = DATENAME(WEEKDAY, [CurrentTime])
      FROM [UTL].[Setting] AS o
    )
    ,cteDayStyle AS (
        SELECT o.*
        FROM (
            VALUES
                  ('Monday',    N'📢', '#000000', '#AFEEEE') -- PaleTurquoise
                , ('Tuesday',   N'✨', '#000000', '#98FB98') -- PaleGreen
                , ('Wednesday', N'📰', '#000000', '#EEE8AA') -- PaleGoldenrod
                , ('Thursday',  N'🔔', '#000000', '#DB7093') -- PaleVioletRed
                , ('Friday',    N'🌐', '#000000', '#ADD8E6') -- LightBlue
                , ('Saturday',  N'✨', '#000000', '#FFEFD5') -- PapayaWhip
                , ('Sunday',    N'🗞️', '#000000', '#FFB6C1') -- LightPink
        ) AS o([DayName], [Icon],[TextColour], [BgColor])
    )
    
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.[System] AS [zID]
		/*#*---------- 📌 DETAIL ----------*#*/
        ,o.[CurrentTime] AS [Updated]
        /*#*---------- 📌 DETAIL ----------*#*/
        ,[Badge Text] = CONVERT(VARCHAR(50), ISNULL(rStyle.[Icon],'') + ' What’s New?') 
		,[Badge Text Color] = CONVERT(VARCHAR(20), ISNULL(rStyle.[TextColour],'#000000'))
		,[Badge Bg Color] = CONVERT(VARCHAR(20), ISNULL(rStyle.[BgColor], '#FFFFFF'))
		,[Badge Link] = CONVERT(VARCHAR(500), '')
		,[Badge Tooltip] = CONVERT(VARCHAR(500), REPLACE('🕔 #TIME#, the dataset has been refreshed.', '#TIME#', o.[CurrentTimeStr])) 
        
        /*#*---------- 📌 DETAIL ----------*#*/
		,[Pivot Title] = CONVERT(VARCHAR(100), 'Choose Rows, Columns, and Values. Display follows your selection order. Click the +/- icons to drill up or down. ')
		,[Pivot Description] = CONVERT(VARCHAR(200), 'Save your current selection as a personal bookmark to quickly return to this view later.')
		,[Pivot Text Color] = CONVERT(VARCHAR(50), '#0088FF') 
        /*#*---------- 📌 DETAIL ----------*#*/
		,[Filter Tooltip] = CONVERT(VARCHAR(100), '🔖 More Filters: Refine your view by applying additional filters to focus on what matters most.')
		,[Reset Tooltip] = CONVERT(VARCHAR(100), '🧽 Reset Filters: Reset your selections and start fresh by clearing all applied filters.')
		,[Back Tooltip] = CONVERT(VARCHAR(100), '⬅️ Go Back: Return to your previous view with all current filters and changes applied.')
		,[Pivot Tooltip] = CONVERT(VARCHAR(100), 'ℹ️ Open Pivot: Explore your data freely by selecting columns, rows, and values in the Pivot.')
        /*#*---------- 📌 DETAIL ----------*#*/
		,[Agent Tooltip] = CONVERT(VARCHAR(100), '💬 AI Assistant: Get instant insights and answers by chatting with the AI agent about your data.')
		,[Agent Color] = CONVERT(VARCHAR(50), '#BB99FF')
		,[Agent Link] = CONVERT(VARCHAR(500), '')
        /*#*---------- 📌 DETAIL ----------*#*/
        ,CONVERT(VARCHAR(50), '#04AA6D') AS [Text Color Green]
		,CONVERT(VARCHAR(50), '#FF9933') AS [Text Color Amber]
		,CONVERT(VARCHAR(50), '#FF4D4D') AS [Text Color Red]
		,CONVERT(VARCHAR(50), '#FFD11A') AS [Text Color Yellow]
		,CONVERT(VARCHAR(50), '#000000') AS [Text Color Black]
		,CONVERT(VARCHAR(50), '#FF4D4D') AS [Text Color Grey]
		/*#*---------- 📌 DETAIL ----------*#*/
		,CONVERT(VARCHAR(50), '#98FB98') AS [Bg Color Green]
		,CONVERT(VARCHAR(50), '#FFEFD5') AS [Bg Color Amber]
		,CONVERT(VARCHAR(50), '#FFB6C1') AS [Bg Color Red]
		,CONVERT(VARCHAR(50), '#FEE634') AS [Bg Color Yellow]	
		,CONVERT(VARCHAR(50), '#4D4D4D') AS [Bg Color Black]
		,CONVERT(VARCHAR(50), '#BFBFBF') AS [Bg Color Grey]
    FROM cteParam AS o     
    LEFT JOIN cteDayStyle AS rStyle ON rStyle.[DayName] = o.[DayName]

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [AAC].[_TPL_REF]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*			
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%_TPL_REF%';
	
	SELECT TOP 100 * 
	-- SELECT COUNT(*)
	FROM [AAC].[_TPL_REF] AS o


*/
CREATE VIEW [AAC].[_TPL_REF]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.[zID]
      ,o.[BK_SRC]
      ,o.[BK_DE]      
      /*#*---------- 📌 DETAIL ----------*#*/
      ,o.[DV_A]
      ,o.[DV_B]
      ,o.[DV_C]
      ,o.[EntityCode] AS [Entity Code]
      ,o.[EntityName] AS [Entity Name]      
      ,o.[EntityDesc] AS [Entity Desc]
      ,o.[EntityCategory] AS [Entity Category]
      ,o.[EntityType] AS [Entity Type]
      ,o.[EntityStatus] AS [Entity Status]
      ,o.[ExtA] AS [Ext A]      
      /*#*---------- 📌 DETAIL ----------*#*/
      ,o.[zStatus]
      ,o.[zFlag]
      ,o.[zLock]
      ,o.[zMemo]
  FROM [AAM].[_TPL_REF] AS o


/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [AAC].[KPI_Calendar]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%KPI_Calendar%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 10 * 
	-- SELECT COUNT(*)
	FROM [AAC].[KPI_Calendar]
	ORDER BY 1,2,3

*/
CREATE VIEW [AAC].[KPI_Calendar]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.[Day]
      ,o.[MonthKey]
      ,o.[Year]
      ,o.[Quarter]
      ,o.[Month]
      ,o.[MonthCategory] AS [Month Category]
      ,o.[MonthCategory_Simple] AS [Month Category Simple]
      ,o.[MonthCategory_Default] AS [Month Category Default]
      ,o.[FinancialYearCategory] AS [Financial Year Category]
      ,o.[FinancialYearCategory_Simple] AS [Financial Year Category Simple]
      ,o.[FinancialYearCategory_Default] AS [Financial Year Category Default]
  FROM [AAM].[Calendar] AS o  
  WHERE o.[FinancialYearOffset] BETWEEN -1 AND 1
  AND o.[DayOfMonthKey] = 1


/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [SVC].[Meta_Database]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Meta%';
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 10 * 
	FROM [SVC].[Meta_Database]

*/
CREATE VIEW [SVC].[Meta_Database]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteData AS (
		SELECT 'Lake' AS [Code], [LakeName] AS [Name], 1 AS [Seq], 'Lake' AS [Category], 'Original data objects organized by source' AS [Desc] FROM [UTL].[Setting]
		UNION 
		SELECT 'Core' AS [Code], [CoreName] AS [Name], 2 AS [Seq], 'Core' AS [Category], 'Harmonized and Analytics data entities' AS [Desc] FROM [UTL].[Setting]
	)
	,cteScript AS (
	SELECT [DatabaseScript] = CONVERT(VARCHAR(500), 'CREATE DATABASE [#DB#]  COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8
GO
ALTER DATABASE [#DB#] SET RECOVERY SIMPLE;
GO ')
	
	)
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT CONVERT(VARCHAR(100), QUOTENAME(o.[Name])) AS [BK_DE]
		,CONVERT(VARCHAR(50), o.[Code]) AS [DatabaseCode]
		,CONVERT(VARCHAR(100), o.[Name]) AS [DatabaseName]
		,CONVERT(VARCHAR(100), QUOTENAME(o.[Name])) AS [QN_Database]
		,CONVERT(VARCHAR(50), o.[Category]) AS [DatabaseCategory]
		,CONVERT(SMALLINT, o.[Seq]) AS [DatabaseSeq]
		/*#*---------- 📌 DETAIL ----------*#*/
		,CONVERT(VARCHAR(500), o.[Desc]) AS [DatabaseDesc]
		,REPLACE([DatabaseScript], '#DB#' , o.[Name])  AS [DatabaseScript]
	FROM cteData AS o
	CROSS JOIN cteScript AS s

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [VPL].[Meta_Column]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









/*	
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Meta%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT  * 
	FROM [VPL].[Meta_Column]
	ORDER BY 3,4,5

*/
CREATE VIEW [VPL].[Meta_Column]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.[TABLE_CATALOG]
			,o.[TABLE_SCHEMA]
			,o.[TABLE_NAME]
			,x.[TABLE_TYPE]
			,o.[ORDINAL_POSITION]
			,o.[COLUMN_NAME]
			,o.[CHARACTER_MAXIMUM_LENGTH]
			,o.[DATA_TYPE]
			,o.[NUMERIC_PRECISION]
			 ,o.[NUMERIC_SCALE]
			 ,o.[DATETIME_PRECISION]
		FROM [V90_Lake].INFORMATION_SCHEMA.COLUMNS AS o	
		INNER JOIN [V90_Lake].INFORMATION_SCHEMA.TABLES AS x ON o.TABLE_CATALOG = x.TABLE_CATALOG AND o.TABLE_SCHEMA = x.TABLE_SCHEMA AND o.TABLE_NAME = x.TABLE_NAME

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [SVC].[Meta_Schema]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Meta%';
	
	SELECT TOP 100 * 
	FROM [SVC].[Meta_Schema]
	ORDER BY SchemaSeq

*/
CREATE VIEW [SVC].[Meta_Schema]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteParam AS (
		SELECT o.*
		FROM (VALUES 
			('Core', 'UTL', 'Utility', 'Utility - Common utility lookups and shared references', 99)
			,('Core', 'SVC', 'Service', 'Services - Shared services, procedures, and jobs', 95)
			/*#*---------- 📌 DETAIL ----------*#*/
			,('Core', 'AUT', 'Automation', 'Automation Control - Controls and manages automated actions', 21)
			/*#*---------- 📌 DETAIL ----------*#*/
			,('Core', 'AAM', 'Access', 'Accessible Artifact of Mart in Core - Exposing data for querying', 41)
			,('Core', 'AAC', 'Access', 'Accessible Artifact for Consumption Friendly Named - exposing data for modelling', 42)
			
			/*#*---------- 📌 DETAIL ----------*#*/
			,('Core', 'HUB', 'Storage', 'Hub/Stem - Physical storage area', 20)
			,('Core', 'MRT', 'Storage', 'Mart/Branch - Physical storage area', 40)			

			/*#*---------- 📌 DETAIL ----------*#*/
			,('Core', 'VPL', 'Access', 'View Point of Lake - Exposing data from Root', 70)
			,('Core', 'PAX', 'Advanced', 'Performance & Advanced Analytics', 65)
			/*#*---------- 📌 DETAIL ----------*#*/
			,('Lake', 'UTL', 'Utility', 'Common utility lookups and shared references', 10)
			,('Lake', 'AAL', 'Access', 'Accessible Artifact exposing data for querying', 11)
			,('Lake', 'APP', 'Business System', 'Demo App data', 12)
			,('Lake', 'MISC', 'Business System', 'Miscellaneous sources', 19)
			
		) AS o([DatabaseCode],[Code], [Category], [Desc], [Seq])
	)
	,cteParamWithDB AS (
		SELECT o.*
		,x.[DatabaseName]
		,x.[DatabaseSeq]
		FROM cteParam AS o
		INNER JOIN [SVC].[Meta_Database] AS x ON x.[DatabaseCode] = o.[DatabaseCode]

	)
	,cteRaw AS (
		SELECT o.[TABLE_CATALOG], o.[TABLE_SCHEMA]
		FROM INFORMATION_SCHEMA.TABLES AS o		
		GROUP BY o.[TABLE_CATALOG], o.[TABLE_SCHEMA]
		
		UNION 

		SELECT o.[TABLE_CATALOG], o.[TABLE_SCHEMA]
		FROM  [VPL].[Meta_Column] AS o		
		GROUP BY o.[TABLE_CATALOG], o.[TABLE_SCHEMA]
    )
	,cteData AS (
		SELECT o.[TABLE_CATALOG] AS [DatabaseName]
			,o.[TABLE_SCHEMA] AS [Code]
		FROM cteRaw AS o 
		WHERE o.[TABLE_SCHEMA] NOT IN ('sys','queryinsights')
	)

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT CONVERT(VARCHAR(100), QUOTENAME(o.[DatabaseName]) + '.' + QUOTENAME(o.[Code])) AS [BK_DE]
		,CONVERT(VARCHAR(100), QUOTENAME(o.[DatabaseName])) AS [BK_Database]
		,CONVERT(VARCHAR(20), o.[Code]) AS [SchemaCode]
		,CONVERT(VARCHAR(100), x.[Code]) AS [SchemaName]
		,CONVERT(VARCHAR(100), QUOTENAME(o.[Code])) AS [QN_Schema]
		,CONVERT(VARCHAR(100),x.[DatabaseCode]) AS [DatabaseCode]
		,CONVERT(VARCHAR(100),o.[DatabaseName]) AS [DatabaseName]
		,CONVERT(VARCHAR(100),QUOTENAME(o.[DatabaseName])) AS [QN_Database]
		,CONVERT(VARCHAR(200),QUOTENAME(o.[DatabaseName]) + '.' + QUOTENAME(o.[Code])) AS [QN_DatabaseSchema]
		/*#*---------- 📌 DETAIL ----------*#*/
		,CONVERT(VARCHAR(500), x.[Desc]) AS [SchemaDesc]
		,x.[DatabaseSeq]
		,CONVERT(SMALLINT, x.[Seq]) AS [SchemaSeq]		
		/*#*---------- 📌 DETAIL ----------*#*/
		,[SchemaCategory] = CONVERT(VARCHAR(50), ISNULL(x.[Category], 'Business')) 
	FROM cteData AS o
	INNER JOIN cteParamWithDB AS x ON x.[DatabaseName] = o.[DatabaseName] AND x.[Code] = o.[Code]
	

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [SVC].[Meta_Table]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
















/*	
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Meta%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT  * 
	FROM [SVC].[Meta_Table]
	ORDER BY 3,4,5

*/
CREATE VIEW [SVC].[Meta_Table]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteRaw AS (
		SELECT o.[TABLE_CATALOG], o.[TABLE_SCHEMA], o.[TABLE_NAME], o.[TABLE_TYPE]
		FROM INFORMATION_SCHEMA.TABLES AS o		

		UNION

		SELECT o.[TABLE_CATALOG], o.[TABLE_SCHEMA], o.[TABLE_NAME], o.[TABLE_TYPE]
		FROM  [VPL].[Meta_Column] AS o		
		GROUP BY o.[TABLE_CATALOG], o.[TABLE_SCHEMA], o.[TABLE_NAME], o.[TABLE_TYPE]

    )
	,cteData AS (
		SELECT o.[TABLE_CATALOG] AS [DatabaseName]
			,o.[TABLE_SCHEMA] AS [SchemaName]
			,o.[TABLE_NAME] AS [TableName]
			,o.[TABLE_TYPE] AS [TableType]
			,[TableSeq] = ROW_NUMBER() OVER ( PARTITION BY o.[TABLE_CATALOG], o.[TABLE_SCHEMA] ORDER BY o.[TABLE_TYPE], o.[TABLE_NAME])
		FROM cteRaw AS o
		WHERE o.[TABLE_SCHEMA] NOT IN ('sys','queryinsights') 
	)
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT [BK_DE] = CONVERT(VARCHAR(100), CONCAT_WS('.', QUOTENAME(o.[DatabaseName]), QUOTENAME(o.[SchemaName]), QUOTENAME(o.[TableName])))
        ,[BK_Database] = CONVERT(VARCHAR(50), QUOTENAME(o.[DatabaseName]))
        ,[BK_Schema] = CONVERT(VARCHAR(100), CONCAT_WS('.', QUOTENAME(o.[DatabaseName]), QUOTENAME(o.[SchemaName])))
        ,[QN_Database] = CONVERT(VARCHAR(50),QUOTENAME(o.[DatabaseName]))
        ,[QN_Schema] = CONVERT(VARCHAR(100),QUOTENAME(o.[SchemaName]))
        ,[QN_Table] = CONVERT(VARCHAR(100),QUOTENAME(o.[TableName]))
		,[QN_SchemaTable] = CONVERT(VARCHAR(100), CONCAT_WS('.', QUOTENAME(o.[SchemaName]), QUOTENAME(o.[TableName])))
		,[DatabaseName] = CONVERT(VARCHAR(50), o.[DatabaseName])
		,x.[DatabaseCode]
        ,[SchemaName] = CONVERT(VARCHAR(100), o.[SchemaName])
        ,[TableName] = CONVERT(VARCHAR(100), o.[TableName])
		/*#*---------- 📌 DETAIL ----------*#*/
		,[TableType] = CONVERT(VARCHAR(100), CASE WHEN o.[TableType] = 'VIEW' THEN 'View' ELSE 'Table' END )
		,[TablePattern] = CASE WHEN CHARINDEX('_FULL', o.[TableName]) > 0 THEN 'PARTIAL_FULL'
                                                WHEN CHARINDEX('_PARTIAL', o.[TableName]) > 0 THEN 'PARTIAL_NEW'
                                                WHEN CHARINDEX('_QUERY', o.[TableName]) > 0 THEN 'PARTIAL_QUERY'
                                                WHEN CHARINDEX('_OVERLAP', o.[TableName]) > 0 THEN 'PARTIAL_OVERLAP'
                                                WHEN o.[TableType] = 'BASE TABLE' THEN 'FULL'
                                                WHEN o.[TableType] = 'VIEW' THEN 'N.A.'
                                                ELSE 'UNKNOWN' END		
		,x.[DatabaseSeq]
		,x.[SchemaCategory]
		,x.[SchemaSeq]
		,CONVERT(SMALLINT, [TableSeq]) AS [TableSeq]
		/*#*---------- 📌 DETAIL ----------*#*/
		,[TableCategory] = CONVERT(VARCHAR(100), 
															CASE WHEN CHARINDEX('Calendar', o.[TableName]) > 0 THEN 'Calendar'
																	WHEN o.[TableName] = 'Log' THEN 'Log'
																	WHEN CHARINDEX('Meta_', o.[TableName]) > 0 THEN 'Meta Data'
																	/*#*---------- 📌 DETAIL ----------*#*/
																	WHEN o.[TableName] IN ('Variable', 'Session') THEN 'Framework'
																	WHEN CHARINDEX('TPL_', o.[TableName]) > 0 THEN 'Framework'
																	WHEN CHARINDEX('Template', o.[TableName]) > 0 THEN 'Framework'
																	/*#*---------- 📌 DETAIL ----------*#*/
																	WHEN CHARINDEX('MST_', o.[TableName]) > 0 THEN 'Master Data'
																	ELSE 'Standard'
															END) 
	FROM cteData AS o
	LEFT JOIN [SVC].[Meta_Schema] AS x ON x.[DatabaseName] = o.[DatabaseName] AND x.[SchemaName] = o.[SchemaName]

	
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [SVC].[Meta_Column]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO















/*	
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Meta%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT  * 
	-- SELECT DISTINCT [BK_DE]
	FROM [SVC].[Meta_Column]
	ORDER BY 1,2,3

*/
CREATE VIEW [SVC].[Meta_Column]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteRaw AS (
		SELECT o.[TABLE_CATALOG],o.[TABLE_SCHEMA],o.[TABLE_NAME],o.[ORDINAL_POSITION],o.[COLUMN_NAME]
		,o.[CHARACTER_MAXIMUM_LENGTH],o.[DATA_TYPE],o.[NUMERIC_PRECISION],o.[NUMERIC_SCALE],o.[DATETIME_PRECISION]
		FROM INFORMATION_SCHEMA.COLUMNS AS o

		UNION

		SELECT o.[TABLE_CATALOG],o.[TABLE_SCHEMA],o.[TABLE_NAME],o.[ORDINAL_POSITION],o.[COLUMN_NAME]
		,o.[CHARACTER_MAXIMUM_LENGTH],o.[DATA_TYPE],o.[NUMERIC_PRECISION],o.[NUMERIC_SCALE],o.[DATETIME_PRECISION]
		FROM  [VPL].[Meta_Column] AS o

    )
	,cteData AS (
		SELECT o.[TABLE_CATALOG] AS [DatabaseName]
			,o.[TABLE_SCHEMA] AS [SchemaName]		
			,o.[TABLE_NAME] AS [TableName]
			,o.[ORDINAL_POSITION] AS [ColumnSeq]		
			,o.[COLUMN_NAME] AS [ColumnName]		
			,o.[CHARACTER_MAXIMUM_LENGTH] AS [ColumnLength]
			,o.[DATA_TYPE] AS [ColumnType]
			,CASE WHEN o.[DATA_TYPE] IN ('varchar', 'nvarchar', 'char', 'nchar') 
				THEN o.[DATA_TYPE] + '(' + 
					CASE 
						WHEN o.[CHARACTER_MAXIMUM_LENGTH] = -1 THEN 'MAX'
						ELSE CAST(o.[CHARACTER_MAXIMUM_LENGTH] AS VARCHAR(10))
					END + ')'
			WHEN o.[DATA_TYPE] IN ('decimal', 'numeric')
				THEN o.[DATA_TYPE] + '(' + 
					CAST(o.[NUMERIC_PRECISION] AS VARCHAR(10)) + ',' + 
					CAST(o.[NUMERIC_SCALE] AS VARCHAR(10)) + ')'
			WHEN o.[DATA_TYPE] IN ('datetime2', 'datetimeoffset', 'time')
				THEN o.[DATA_TYPE] + '(' + CAST(o.[DATETIME_PRECISION] AS VARCHAR(10)) + ')'
			ELSE o.[DATA_TYPE]
			END AS [ColumnTypeSpec]
		FROM cteRaw AS o
		WHERE o.[TABLE_SCHEMA] NOT IN ('sys','queryinsights')
    )
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT [BK_DE] = CONVERT(VARCHAR(100), CONCAT_WS('.', QUOTENAME(o.[DatabaseName]), QUOTENAME(o.[SchemaName]), QUOTENAME(o.[TableName]) , QUOTENAME(o.[ColumnName])))       
		,[QN_Column] = QUOTENAME(o.[ColumnName])
		,[ColumnName] = CONVERT(VARCHAR(100), o.[ColumnName])
		,[ColumnSeq] = CONVERT(SMALLINT, o.[ColumnSeq])
		/*#*---------- 📌 DETAIL ----------*#*/
		,[ColumnType] = CONVERT(VARCHAR(100), o.[ColumnType])
		,[ColumnTypeSpec] = CONVERT(VARCHAR(100), o.[ColumnTypeSpec])
		,[ColumnCategory] = CONVERT(VARCHAR(100), 
															CASE WHEN o.[ColumnName] IN ('zID', 'zUPD') THEN 'Universal Tag'
																	WHEN o.[ColumnName] IN ('zSTMPz', 'zUPD') THEN 'Extraction Tag'
																	WHEN LEFT(o.[ColumnName],3) = 'BK_' THEN 'Business Key'
																	WHEN LEFT(o.[ColumnName],3) = 'CX_' THEN 'Capsule'
																	WHEN LEFT(o.[ColumnName],3) = 'CA_' THEN 'Metric'
																	ELSE 'Attribute'
															END) 
		/*#*---------- 📌 DETAIL ----------*#*/
		,x.[BK_DE] AS [BK_Table]
		,x.[BK_Database]
		,x.[BK_Schema]
		,x.[QN_Database]
		,x.[QN_Schema]
		,x.[QN_Table]
		,x.[QN_SchemaTable]
		,x.[DatabaseName]
		,x.[DatabaseCode]
		,x.[SchemaName]
		,x.[TableName]
		,x.[TableType]
		,x.[TablePattern]
		,x.[DatabaseSeq]
		,x.[SchemaCategory]
		,x.[SchemaSeq]
		,x.[TableSeq]
		,x.[TableCategory]
	FROM cteData AS o
	LEFT JOIN [SVC].[Meta_Table] AS x ON x.[DatabaseName] = o.[DatabaseName] AND x.[SchemaName] = o.[SchemaName] AND x.[TableName] = o.[TableName]

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [SVC].[Meta_Proc]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

















/*	
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Meta%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT  * 
	FROM [SVC].[Meta_Proc]
	ORDER BY 3,4,5

*/
CREATE VIEW [SVC].[Meta_Proc]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteProc AS (
		SELECT DB_NAME() AS [DatabaseName]
			,SCHEMA_NAME(p.[schema_id]) AS [SchemaName]
			,p.[name] AS [ProcName]		
		FROM [sys].[procedures] AS p		
    )
	,cteData AS (
		SELECT o.*
			,[ProcSeq] = ROW_NUMBER() OVER ( PARTITION BY o.[DatabaseName], o.[SchemaName] ORDER BY o.[ProcName])
		FROM cteProc AS o
	)
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT [BK_DE] = CONVERT(VARCHAR(100), CONCAT_WS('.', QUOTENAME(o.[DatabaseName]), QUOTENAME(o.[SchemaName]), QUOTENAME(o.[ProcName])))
        ,[BK_Database] = CONVERT(VARCHAR(50), QUOTENAME(o.[DatabaseName]))
        ,[BK_Schema] = CONVERT(VARCHAR(100), CONCAT_WS('.', QUOTENAME(o.[DatabaseName]), QUOTENAME(o.[SchemaName])))
        ,[QN_Database] = CONVERT(VARCHAR(50),QUOTENAME(o.[DatabaseName]))
        ,[QN_Schema] = CONVERT(VARCHAR(100),QUOTENAME(o.[SchemaName]))
        ,[QN_Proc] = CONVERT(VARCHAR(100),QUOTENAME(o.[ProcName]))
		,[DatabaseName] = CONVERT(VARCHAR(50), o.[DatabaseName])
		,x.[DatabaseCode]
        ,[SchemaName] = CONVERT(VARCHAR(100), o.[SchemaName])
        ,[ProcName] = CONVERT(VARCHAR(100), o.[ProcName])
		/*#*---------- 📌 DETAIL ----------*#*/
		,x.[DatabaseSeq]
		,x.[SchemaCategory]
		,x.[SchemaSeq]
		,CONVERT(SMALLINT, [ProcSeq]) AS [ProcSeq]
		/*#*---------- 📌 DETAIL ----------*#*/
		,[ProcCategory] = CONVERT(VARCHAR(100), 
															CASE WHEN CHARINDEX('Reload', o.[ProcName]) > 0 THEN 'Reload'
																	WHEN CHARINDEX('Refresh', o.[ProcName]) > 0 THEN 'Refresh'
																	WHEN CHARINDEX('Update', o.[ProcName]) > 0 THEN 'Update'
																	WHEN CHARINDEX('Empty', o.[ProcName]) > 0 THEN 'Empty'
																	WHEN CHARINDEX('Prune', o.[ProcName]) > 0 THEN 'Prune'
																	WHEN CHARINDEX('Set', o.[ProcName]) > 0 THEN 'Set'
																	WHEN CHARINDEX('Remove', o.[ProcName]) > 0 THEN 'Remove'
																	WHEN CHARINDEX('Add', o.[ProcName]) > 0 THEN 'Add'
																	WHEN CHARINDEX('Seed', o.[ProcName]) > 0 THEN 'Seed'
																	ELSE 'Unknown'
															END) 
	FROM cteData AS o
	LEFT JOIN [SVC].[Meta_Schema] AS x ON x.[DatabaseName] = o.[DatabaseName] AND x.[SchemaName] = o.[SchemaName]

	
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [SVC].[Meta_ProcScript]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




















/*	
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Meta%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT  * 
	FROM [SVC].[Meta_ProcScript]
	ORDER BY 3,4,5

*/
CREATE VIEW [SVC].[Meta_ProcScript]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteParam AS (		
		SELECT p.[object_id]
		 ,STRING_AGG(prm.[name], ',') WITHIN GROUP (ORDER BY prm.[parameter_id]) AS [ParamList]
		 ,COUNT(prm.[name]) AS [ParamCount]
		FROM [sys].[procedures] AS p
		LEFT JOIN [sys].[parameters] AS prm ON prm.[object_id] = p.[object_id]
		 GROUP BY p.[object_id]
	)
	, cteScript AS (
		SELECT DB_NAME() AS [DatabaseName]
			,SCHEMA_NAME(p.[schema_id]) AS [SchemaName]
			,p.[name] AS [ProcName]
			,pl.[ParamList] AS [ProcParamList]
			,pl.[ParamCount] AS [ProcParamCount]
			,m.[definition] AS [ProcScript]
		FROM [sys].[procedures] AS p
		LEFT JOIN [sys].[sql_modules] AS m ON m.[object_id] = p.[object_id]
		LEFT JOIN cteParam AS pl ON pl.[object_id] = p.[object_id] 	
    )	
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.[BK_DE]
      ,o.[BK_Database]
      ,o.[BK_Schema]
      ,o.[QN_Database]
      ,o.[QN_Schema]
      ,o.[QN_Proc]
      ,o.[DatabaseName]
	  ,o.[DatabaseCode]
      ,o.[SchemaName]
      ,o.[ProcName]
      ,o.[DatabaseSeq]
      ,o.[SchemaCategory]
      ,o.[SchemaSeq]
      ,o.[ProcSeq]
      ,o.[ProcCategory]
	  ,x.[ProcParamList]
	  ,x.[ProcParamCount]
	  ,x.[ProcScript]
	  ,[ProcScriptLen] = CONVERT(INT, LEN(x.[ProcScript]))
	FROM [SVC].[Meta_Proc] AS o
	LEFT JOIN cteScript AS x ON x.[DatabaseName] = o.[DatabaseName] AND x.[SchemaName] = o.[SchemaName] AND x.[ProcName] = o.[ProcName]

	
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [SVC].[Meta_Object]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/
	EXEC [SVC].[FindX] '%Meta%';
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 100 * 
	FROM [SVC].[Meta_Object] AS o
	WHERE o.[SchemaName] LIKE 'AUT%'
	ORDER BY DatabaseSeq,SchemaSeq,ObjectSeq

	/*#*---------- 🔍 EXAMPLE ----------*#*/
	SELECT o.[ObjectType], COUNT(*) AS C
	FROM [SVC].[Meta_Object] AS o
	GROUP BY o.[ObjectType]
	ORDER BY 1,2

*/
CREATE VIEW [SVC].[Meta_Object]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteQuery AS (
		 SELECT CONVERT(VARCHAR(50), [Type]) AS [Type]
			,CONVERT(VARCHAR(500), [Script]) AS [Script]
		 FROM (VALUES ( 'Table', 'SELECT TOP 100 * 
    FROM #TABLE# 
    ORDER BY 3,4 ;')
	,( 'Column', 'SELECT #COLUMN# , COUNT(*) AS C
    FROM #TABLE# 
    GROUP BY #COLUMN#
    ORDER BY C DESC; ')
	,( 'Proc', 'EXEC #PROC# #CONTROLLER#; ')
	) AS o([Type],[Script])
	)
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.[BK_DE]
		,o.[BK_Database]
		,o.[BK_Schema]		
		,o.[TableType] AS [ObjectType]
		,o.[QN_Database]
		,o.[QN_Schema]
		,o.[QN_Table] AS [QN_Object]
		,o.[DatabaseName]
		,o.[DatabaseCode]
		,o.[DatabaseSeq]
		,o.[SchemaName]
		,o.[SchemaSeq]
		,o.[TableName] AS [ObjectName]      
		,o.[TableSeq] AS [ObjectSeq]
		/*#*---------- 📌 DETAIL ----------*#*/
		,CONCAT_WS('.', o.[SchemaName], o.[TableName]) AS [ObjectSearch]
		,CONCAT_WS('.', o.[SchemaName], o.[TableName]) AS [ObjectNameSearch]
		,[BaseQuery] = CONVERT(VARCHAR(1000), REPLACE(x.[Script], '#TABLE#', o.[BK_DE]))
		,[ExtenedQuery] = CONVERT(VARCHAR(1000), 'SELECT * FROM [SVC].[Table] WHERE [BK_DE] = ''' + o.[BK_DE] + ''';')
	FROM [SVC].[Meta_Table] AS o 
	LEFT JOIN cteQuery AS x ON x.[Type] = 'Table'
	/*#*---------- 📌 DETAIL ----------*#*/
	UNION
	SELECT o.[BK_DE]
		,o.[BK_Database]
		,o.[BK_Schema]  
		,CAST('Column' AS VARCHAR(50)) AS [ObjectType]
		,o.[QN_Database]
		,o.[QN_Schema]
		,o.[QN_Column] AS [QN_Object]
		,o.[DatabaseName]
		,o.[DatabaseCode]
		,o.[DatabaseSeq]
		,o.[SchemaName]
		,o.[SchemaSeq]
		,o.[ColumnName] AS [ObjectName]
		,o.[ColumnSeq] AS [ObjectSeq]
		/*#*---------- 📌 DETAIL ----------*#*/
		,CONCAT_WS('.', o.[SchemaName], o.[TableName], [ColumnName]) AS [ObjectSearch]
		,CONCAT_WS('.', o.[SchemaName], o.[ColumnType]) AS [ObjectNameSearch]
		,[BaseQuery] = CONVERT(VARCHAR(1000), REPLACE(REPLACE(x.[Script], '#TABLE#', o.[BK_Table]), '#COLUMN#', o.[QN_Column]))
		,[ExtenedQuery] = CONVERT(VARCHAR(1000), 'SELECT * FROM [SVC].[Column] WHERE [BK_DE] = ''' + o.[BK_DE] + ''';')
	FROM [SVC].[Meta_Column] AS o 
	LEFT JOIN cteQuery AS x ON x.[Type] = 'COLUMN'
	/*#*---------- 📌 DETAIL ----------*#*/
	UNION
	SELECT o.[BK_DE]
		,o.[BK_Database]
		,o.[BK_Schema] 
		,CAST('Proc' AS VARCHAR(50)) AS [ObjectType]
		,o.[QN_Database]
		,o.[QN_Schema]
		,o.[QN_Proc] AS [QN_Object]
		,o.[DatabaseName]
		,o.[DatabaseCode]
		,o.[DatabaseSeq]
		,o.[SchemaName]
		,o.[SchemaSeq]
		,o.[ProcName] AS [ObjectName]
		,o.[ProcSeq] AS [ObjectSeq]
		/*#*---------- 📌 DETAIL ----------*#*/
		,CONCAT_WS('.', o.[SchemaName], o.[ProcName]) AS [ObjectSearch]
		,CONCAT_WS('.', o.[SchemaName], o.[ProcName]) AS [ObjectNameSearch]
		,[BaseQuery] = CONVERT(VARCHAR(1000), CASE WHEN o.[ProcParamList] = '@Controller' 
												THEN REPLACE(REPLACE(x.[Script], '#PROC#', o.[BK_DE]), '#CONTROLLER#', '''Ad-hoc''')	
											WHEN o.[ProcParamCount] = 0 
												THEN REPLACE(REPLACE(x.[Script], '#PROC#', o.[BK_DE]), '#CONTROLLER#', '')	
								ELSE '--' + REPLACE(REPLACE(x.[Script], '#PROC#', o.[BK_DE]), '#CONTROLLER#', o.[ProcParamList])	 END)
		,[ExtenedQuery] = CONVERT(VARCHAR(1000), 'SELECT * FROM [SVC].[Proc] WHERE [BK_DE] = ''' + o.[BK_DE] + ''';')
	FROM [SVC].[Meta_ProcScript] AS o 
	LEFT JOIN cteQuery AS x ON x.[Type] = 'PROC'

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [UTL].[Variable]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO














/*			
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Variable%';
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * 
	FROM [UTL].[Variable]
	
	/*#*---------- 🔍 EXAMPLE ----------*#*/
	SELECT REPLACE(', o.[#C#] ,FORMAT(o.[#C#], o.[DateStrFormat]) AS [#C#_Str]', '#C#', o.COLUMN_NAME) AS SQL
	FROM INFORMATION_SCHEMA.[COLUMNS] AS o
	WHERE o.TABLE_SCHEMA = 'SVC' AND o.[TABLE_NAME] = 'zVariable' 
	AND o.COLUMN_NAME LIKE 'Current%' AND o.COLUMN_NAME  <> 'CurrentTime'
	ORDER BY o.ORDINAL_POSITION

	

*/
CREATE VIEW [UTL].[Variable]
AS	
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteCfg AS (
		SELECT o.[DefaultTimeZoneDisplayName]
		,o.[DefaultTimeZoneSystemName]
		,o.[DateStrFormat]
		,o.[TimeStrFormat]
		,o.[TimeStampFormat]
		,SYSDATETIMEOFFSET() AT TIME ZONE 'UTC' AS [UTC_Time]
		FROM [UTL].[Setting] AS o
	)
	,cteTime AS (
		SELECT o.*
		,DATEADD(DAY, DATEDIFF(DAY, 0, o.[UTC_Time]), 0)  AS [UTC_Date]
		,o.[UTC_Time] AT TIME ZONE o.[DefaultTimeZoneSystemName] AS [CUR_Time]		
		,DATEADD(DAY, DATEDIFF(DAY, 0, o.[UTC_Time] AT TIME ZONE o.[DefaultTimeZoneSystemName]), 0)  AS [CUR_Date]
		FROM cteCfg AS o
	)
	,cteCUR_Date AS (
		SELECT o.*		
		,DATETRUNC(ISO_WEEK, o.[CUR_Date]) AS [CUR_WK]
		,DATETRUNC(MONTH, o.[CUR_Date]) AS [CUR_MTH]
		,DATETRUNC(QUARTER, o.[CUR_Date]) AS [CUR_QTR]
		,DATETRUNC(YEAR, o.[CUR_Date]) AS [CUR_Y]
		,CONVERT(DATETIME, DATEFROMPARTS(CASE WHEN MONTH(o.[CUR_Date]) >= 7 THEN YEAR(o.[CUR_Date]) ELSE YEAR(o.[CUR_Date]) - 1 END, 7, 1 )) AS [CUR_FY]
		FROM cteTime AS o
	)
	,cteCA_DateRelative AS (
		SELECT o.*
		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[CUR_Date] AS [CurrentDate]
		,DATEADD(DAY, -30, [CUR_Date]) AS [CurrentDate-30]
		,DATEADD(DAY, -60, [CUR_Date]) AS [CurrentDate-60]
		,DATEADD(DAY, -90, [CUR_Date]) AS [CurrentDate-90]
		,DATEADD(DAY, 30, [CUR_Date]) AS [CurrentDate+30]
		,DATEADD(DAY, 60, [CUR_Date]) AS [CurrentDate+60]
		,DATEADD(DAY, 90, [CUR_Date]) AS [CurrentDate+90]
		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[CUR_WK] AS [CurrentWeek]
		,DATEADD(WEEK, -4, [CUR_WK]) AS [CurrentWeek-4]
		,DATEADD(WEEK, -8, [CUR_WK]) AS [CurrentWeek-8]
		,DATEADD(WEEK, -12, [CUR_WK]) AS [CurrentWeek-12]
		,DATEADD(WEEK, 4, [CUR_WK]) AS [CurrentWeek+4]
		,DATEADD(WEEK, 8, [CUR_WK]) AS [CurrentWeek+8]
		,DATEADD(WEEK, 12, [CUR_WK]) AS [CurrentWeek+12]
		/*#*---------- 📌 DETAIL ----------*#*/
		,DATEADD(MONTH, DATEDIFF(MONTH, 0, o.[CUR_Date]), 0) AS [CurrentMonth]
		,DATEADD(MONTH, DATEDIFF(MONTH, 0, o.[CUR_Date])-1, 0) AS [CurrentMonth-1]
		,DATEADD(MONTH, DATEDIFF(MONTH, 0, o.[CUR_Date])-3, 0) AS [CurrentMonth-3]
		,DATEADD(MONTH, DATEDIFF(MONTH, 0, o.[CUR_Date])-6, 0) AS [CurrentMonth-6]
		,DATEADD(MONTH, DATEDIFF(MONTH, 0, o.[CUR_Date])-12, 0) AS [CurrentMonth-12]
		,DATEADD(MONTH, DATEDIFF(MONTH, 0, o.[CUR_Date])-24, 0) AS [CurrentMonth-24]
		,DATEADD(MONTH, DATEDIFF(MONTH, 0, o.[CUR_Date])+1, 0) AS [CurrentMonth+1]
		,DATEADD(MONTH, DATEDIFF(MONTH, 0, o.[CUR_Date])+3, 0) AS [CurrentMonth+3]
		,DATEADD(MONTH, DATEDIFF(MONTH, 0, o.[CUR_Date])+6, 0) AS [CurrentMonth+6]
		,DATEADD(MONTH, DATEDIFF(MONTH, 0, o.[CUR_Date])+12, 0) AS [CurrentMonth+12]
		,DATEADD(MONTH, DATEDIFF(MONTH, 0, o.[CUR_Date])+24, 0) AS [CurrentMonth+24]
		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[CUR_FY] AS [CurrentFinancialYear]
		,DATEADD(YEAR, -1, o.[CUR_FY]) AS [CurrentFinancialYear-1]
		,DATEADD(YEAR, -3, o.[CUR_FY]) AS [CurrentFinancialYear-3]
		,DATEADD(YEAR, 1, o.[CUR_FY]) AS [CurrentFinancialYear+1]
		,DATEADD(YEAR, 3, o.[CUR_FY]) AS [CurrentFinancialYear+3]
		FROM cteCUR_Date AS o
	)

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.[DefaultTimeZoneDisplayName] AS [TimeZoneName]
		,CONVERT(DATETIME2(0), o.[CurrentDate]) AS [CurrentDate]
		,CONVERT(DATETIME2(0), o.[CurrentDate-30]) AS [CurrentDate-30]
		,CONVERT(DATETIME2(0), o.[CurrentDate-60]) AS [CurrentDate-60]
		,CONVERT(DATETIME2(0), o.[CurrentDate-90]) AS [CurrentDate-90]
		,CONVERT(DATETIME2(0), o.[CurrentDate+30]) AS [CurrentDate+30]
		,CONVERT(DATETIME2(0), o.[CurrentDate+60]) AS [CurrentDate+60]
		,CONVERT(DATETIME2(0), o.[CurrentDate+90]) AS [CurrentDate+90]
		/*#*---------- 📌 DETAIL ----------*#*/
		,CONVERT(DATETIME2(0), o.[CurrentWeek]) AS [CurrentWeek]
		,CONVERT(DATETIME2(0), o.[CurrentWeek-4]) AS [CurrentWeek-4]
		,CONVERT(DATETIME2(0), o.[CurrentWeek-8]) AS [CurrentWeek-8]
		,CONVERT(DATETIME2(0), o.[CurrentWeek-12]) AS [CurrentWeek-12]
		,CONVERT(DATETIME2(0), o.[CurrentWeek+4]) AS [CurrentWeek+4]
		,CONVERT(DATETIME2(0), o.[CurrentWeek+8]) AS [CurrentWeek+8]
		,CONVERT(DATETIME2(0), o.[CurrentWeek+12]) AS [CurrentWeek+12]
		/*#*---------- 📌 DETAIL ----------*#*/
		,CONVERT(DATETIME2(0), o.[CurrentMonth]) AS [CurrentMonth]
		,CONVERT(DATETIME2(0), o.[CurrentMonth-1]) AS [CurrentMonth-1]
		,CONVERT(DATETIME2(0), o.[CurrentMonth-3]) AS [CurrentMonth-3]
		,CONVERT(DATETIME2(0), o.[CurrentMonth-6]) AS [CurrentMonth-6]
		,CONVERT(DATETIME2(0), o.[CurrentMonth-12]) AS [CurrentMonth-12]
		,CONVERT(DATETIME2(0), o.[CurrentMonth-24]) AS [CurrentMonth-24]
		,CONVERT(DATETIME2(0), o.[CurrentMonth+1]) AS [CurrentMonth+1]
		,CONVERT(DATETIME2(0), o.[CurrentMonth+3]) AS [CurrentMonth+3]
		,CONVERT(DATETIME2(0), o.[CurrentMonth+6]) AS [CurrentMonth+6]
		,CONVERT(DATETIME2(0), o.[CurrentMonth+12]) AS [CurrentMonth+12]
		,CONVERT(DATETIME2(0), o.[CurrentMonth+24]		) AS [CurrentMonth+24]		
		/*#*---------- 📌 DETAIL ----------*#*/
		,CONVERT(DATETIME2(0), o.[CurrentFinancialYear]) AS [CurrentFinancialYear]
		,CONVERT(DATETIME2(0), o.[CurrentFinancialYear-1]) AS [CurrentFinancialYear-1]
		,CONVERT(DATETIME2(0), o.[CurrentFinancialYear-3]) AS [CurrentFinancialYear-3]
		,CONVERT(DATETIME2(0), o.[CurrentFinancialYear+1]) AS [CurrentFinancialYear+1]
		,CONVERT(DATETIME2(0), o.[CurrentFinancialYear+3]) AS [CurrentFinancialYear+3]
		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[DefaultTimeZoneSystemName] AS [TimeZoneSystemName]
		,o.[DateStrFormat]
		,o.[TimeStrFormat]
		,o.[TimeStampFormat]
		,CONVERT(DATETIME2(0), o.[CUR_Time]) AS [CurrentTime]
		,CONVERT(DATETIME2(0), o.[UTC_Time]) AS [UTC_Time]
		,CONVERT(DATETIME2(0), o.[UTC_Date]) AS [UTC_Date]
		,CONVERT(VARCHAR(50), FORMAT(o.[CUR_Time], o.[TimeStampFormat])) AS [TimeStampStr]
				
	FROM cteCA_DateRelative AS o

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [SVC].[Dev_CodeSnippet]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




















/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Dev%';

    /*#*---------- 🧪 VALIDATION ----------*#*/	
    SELECT  * 
	FROM [SVC].[Dev_CodeSnippet] AS o

*/
CREATE VIEW [SVC].[Dev_CodeSnippet]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

    /*#*========== 🧩 PREPARE ==========*#*/
	WITH cteConfig AS (
		SELECT o.[LakeName], o.[QN_Lake]
		,'MISC' AS [LakeSchemaName], '_TPL_REF' AS [LakeTableName]
		, o.[CoreName], o.[QN_Core]
		,'HUB' AS [HubSchemaName], '_TPL_REF' AS [HubTableName]
		,'MRT' AS [MartSchemaName], '_TPL_REF' AS [MartTableName]
		FROM [UTL].[Setting] AS o
	)
	,cteParam AS (
		SELECT o.*			
			,CONCAT_WS('.', QUOTENAME(o.[LakeName]), QUOTENAME(o.[LakeSchemaName]), QUOTENAME(o.[LakeTableName])) AS [BK_LakeTable]
            ,CONCAT_WS('.', QUOTENAME(o.[CoreName]), QUOTENAME(o.[HubSchemaName]), QUOTENAME(o.[HubTableName])) AS [BK_HubTable]
			,CONCAT_WS('.', QUOTENAME(o.[CoreName]), QUOTENAME(o.[MartSchemaName]), QUOTENAME(o.[MartTableName])) AS [BK_MartTable]
			,CONCAT_WS('.', QUOTENAME(o.[LakeSchemaName]), QUOTENAME(o.[LakeTableName])) AS [QN_LakeSchemaTable]
            ,CONCAT_WS('.', QUOTENAME(o.[HubSchemaName]), QUOTENAME(o.[HubTableName])) AS [QN_HubSchemaTable]
			,CONCAT_WS('.', QUOTENAME(o.[MartSchemaName]), QUOTENAME(o.[MartTableName])) AS [QN_MartSchemaTable]
		FROM cteConfig AS o
	)	
	/*#*---------- 📌 DETAIL  ----------*#*/
    ,cteCode AS (
	    SELECT CONVERT(VARCHAR(50), o.[Type]) AS [Type]
           ,CONVERT(VARCHAR(100), o.[Scope]) AS [Scope]
           ,CONVERT(VARCHAR(100), o.[Category]) AS [Category]
           ,CONVERT(VARCHAR(8000), o.[Content]) AS [Content]
           ,CONVERT(VARCHAR(500), o.[Desc]) AS [Desc]
           ,CONVERT(VARCHAR(500), o.[Notes]) AS [Notes]
        FROM (VALUES          	
			/*#*---------- 📌 DETAIL ----------*#*/
			(N'Code', N'SQL', N'Print', N'PRINT ''/*---------- 🔽 Prefix: '' + @_Variable + ''-- Postfix ----------*/''', N'Printing Begin', '')
			,(N'Code', N'SQL', N'Print', N'PRINT ''/*---------- 🔼 Prefix: '' + @_Variable + ''-- Postfix ----------*/''', N'Printing End', '')
            /*#*---------- 📌 DETAIL ----------*#*/
            ,(N'Code', N'SQL', N'Example', N'/*#*---------- 🔍 EXAMPLE ----------*#*/
	    DECLARE @DB VARCHAR(50) = DB_NAME();
	    EXEC #CORE#.[SVC].[FindX] @DB, #QN_MART_SCHEMA_TABLE#; 
            ', N'A small, reusable block of code', N'')

            /*#*---------- 📌 DETAIL ----------*#*/
            ,(N'Code', N'SQL', N'Validation', N'/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * 
	-- SELECT COUNT(*)
	FROM #QN_MART_SCHEMA_TABLE# AS o
	WHERE 1=1
	ORDER BY 4,5,6
            ', N'A small, reusable block of code', N'')

             /*#*---------- 📌 DETAIL ----------*#*/
            ,(N'Code', N'SQL', N'Loging', N'/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;	
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;
', N'A small, reusable block of code', N'')

            /*#*---------- 📌 DETAIL ----------*#*/
            ,(N'Code', N'SQL', N'Parameter', N'/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_DB NVARCHAR(50), @_Table NVARCHAR(500);
	SET @_DB = DB_NAME();
	SET @_Table = #QN_MART_SCHEMA_TABLE#;

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_UPD DATETIME2,@_SCHD DATE,@_SCHD_TIME DATETIME2(0); 
	SELECT TOP 1 @_UPD = o.[CurrentTime]
	,@_SCHD = o.[CurrentDate]
	,@_SCHD_TIME = o.[CurrentTime]		
	FROM [UTL].[Variable] AS o ;
            ', N'A small, reusable block of code', N'')

            /*#*---------- 📌 DETAIL ----------*#*/
            ,(N'Code', N'SQL', N'Empty Table', N'/*#*---------- ♻️ EMPTY ----------*#*/
	EXEC [UTL].[EmptyTable] @Controller, @_Table;
            ', N'A small, reusable block of code', N'')

            /*#*---------- 📌 DETAIL ----------*#*/
            ,(N'Code', N'SQL', N'Cleanup', N'/*#*---------- 🧹 CLEANUP ----------*#*/
	EXEC [UTL].[RemoveDuplication] @Controller, @_Table;
            ', N'A small, reusable block of code', N'')
            /*#*---------- 📌 DETAIL ----------*#*/
            ,(N'Code', N'SQL', N'Placeholder', N'/*#*########## 📚 SECTION ##########*#*/
	EXEC [UTL].[AddPlaceholder] @Controller, @_Table,''[UN]'';
            ', N'A small, reusable block of code', N'')

            /*#*---------- 📌 DETAIL ----------*#*/
            ,(N'Code', N'SQL', N'Proc Params', N'    @Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
    ,@Mode varchar(10) = ''EXE'' /*_*{Parameter},{@Mode},{Print or Exec}*_*/
            ', N'A small, reusable block of code', N'')
            
            /*#*---------- 📌 DETAIL ----------*#*/
            ,(N'Code', N'SQL', N'Action', N'/*#*========== 🧩 PREPARE ==========*#*/
	;WITH cteData AS (
		SELECT o.[TABLE_SCHEMA] AS [Code]
			,o.[TABLE_NAME] AS [Name]
		FROM INFORMATION_SCHEMA.TABLES AS o		
	)
    /*#*========== ✅ ACTION ==========*#*/
	INSERT [SVC].[_Template] ([zID],[zUPD]
		  ,[BK_DE]
		  ,[_TemplateCode]
		  ,[_TemplateName]
	  )
	SELECT TOP 10 NEWID() AS [zID], GETDATE() AS [zUPD]
		,CONCAT_WS(''+'', o.[Code], o.[Name] ) AS [BK_DE]
		,o.[Code] AS [_TemplateCode]
		,o.[Name] AS [_TemplateName]	
	FROM cteData AS o
	WHERE 1=1 ;
            ', N'A small, reusable block of code', N'')

			 /*#*---------- 📌 DETAIL ----------*#*/
            ,(N'Code', N'SQL', N'Snapshot', N'/*#*---------- ♻️ EMPTY ----------*#*/	
	
	/*#*########## 📚 SECTION ##########*#*/
	DECLARE @_ASAT DATETIME2(0), @_Frequency VARCHAR(20);
	SET @_ASAT = DATEADD(DAY, -1,@_SCHD);
	SET @_Frequency = ''Month'';
	EXEC [UTL].[SnapshotBegin] @_Controller, @_Table, @_ASAT, @SnapshotLimit = 12, @ExpiredSnapshotLimit = 1;

	SELECT NEWID() AS [zID], @_UPD AS [zUPD]
		,o.[BK_SRC]
		,o.[BK_DE] + ''@'' + FORMAT(@_ASAT, ''yyyy-MM-dd'') AS [BK_DE]
		,o.[BK_DE] AS [BK_DE_OG]		

    /*#*---------- 🧹 CLEANUP ----------*#*/
	EXEC [UTL].[RemoveDuplication] @Controller, @_Table;
	
	/*#*########## 📚 SECTION ##########*#*/
	EXEC [UTL].[SnapshotEnd] @_Controller, @_Table, @_Frequency;

            ', N'A small, reusable block of code', N'')

			/*#*---------- 📌 DETAIL ----------*#*/
            ,(N'Code', N'SQL', N'CREATE VIEW', N'/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/
	EXEC [SVC].[FindX] ''%#LAKE_TABLE#%'';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 50 * 
	FROM #QN_LAKE_SCHEMA_TABLE# AS o
	ORDER BY 2,3,4

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 10 * 
	,JSON_VALUE(o.[CX_DE], ''$.Lake.ExtA'') AS ExtA
	,JSON_MODIFY(o.[CX_DE], ''$.Hub'', JSON_OBJECT( 
			''Demo'': NULLIF(TRIM(''Test''), '''')			
			ABSENT ON NULL
			)) AS [CX_DE2]
	FROM #QN_LAKE_SCHEMA_TABLE# AS o

*/
CREATE VIEW #QN_LAKE_SCHEMA_TABLE#
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteREF AS (		
		SELECT TOP 100 [Id]
		,[RandomText] AS [Code]
		,[RandomText] AS [Name]		
		FROM #CORE#.[SVC].[Dev_RandomSample] AS o
	)
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT cfg.[BK_SRC]
		,CONCAT_WS(''+'', cfg.[BK_SRC], o.[Code]) AS [BK_DE]
		,o.[Code] AS [EntityCode]
		,o.[Name] AS [EntityName]		
		,CONVERT(VARCHAR(MAX), JSON_OBJECT(''Lake'':  JSON_OBJECT( 
			''ExtA'': NULLIF(TRIM(o.[Code]), '''')
			ABSENT ON NULL
			))) AS [CX_DE]
	FROM cteREF AS o
	CROSS JOIN [AAL].#QN_LAKE_SCHEMA_TABLE# AS cfg
	
/*#*==================== 🔚 ====================*#*/

            ', N'A small, reusable block of code', N'')

            /*#*---------- 📌 DETAIL ----------*#*/
            ,(N'Code', N'SQL', N'Create Table', N'CREATE TABLE #QN_MART_SCHEMA_TABLE#(
	[zID] [varchar](50) NOT NULL PRIMARY KEY,
	[zUPD] [datetime2](3) NULL,
	[BK_SRC] [varchar](20) NULL,
	[BK_DE] [varchar](100) NULL,
	[DV_A] [varchar](50) NULL,
	[DV_B] [varchar](50) NULL,
	[DV_C] [varchar](50) NULL,
	[EntityCode] [varchar](50) NULL,
	[EntityName] [varchar](100) NULL,
	[EntityDesc] [varchar](100) NULL,
	[EntityCategory] [varchar](50) NULL,
	[EntityType] [varchar](50) NULL,
	[EntityStatus] [varchar](50) NULL,
	[EntityNo] [varchar](50) NULL,
	[EntitySeq] [varchar](50) NULL,
	[CX_DE] [varchar](max) NULL,
	[CA_zStatus] [varchar](50) NULL,
	[CA_zFlag] [smallint] NULL,
	[CA_zLock] [varchar](500) NULL,
	[CA_zMemo] [varchar](500) NULL
) 
            ', N'A small, reusable block of code', N'')

            /*#*---------- 📌 DETAIL ----------*#*/
            ,(N'Code', N'SQL', N'Code Snippet', N'/*#*########## 📚 SECTION ##########*#*/
            ', N'A small, reusable block of code', N'')

        ) AS o([Type], [Scope], [Category], [Content], [Desc], [Notes])
    )
    /*#*========== ✅ OUTPUT ==========*#*/
    SELECT o.[Type]
        ,o.[Scope]
        ,o.[Category]
        /*#*---------- 📌 DETAIL  ----------*#*/
        ,REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(o.[Content], '#CORE#', x.[QN_Core])
			, '#LAKE#', x.[QN_Lake])
            , '#QN_MART_SCHEMA_TABLE#', x.[QN_MartSchemaTable]) 
			, '#QN_HUB_SCHEMA_TABLE#', x.[QN_HubSchemaTable]) 
			, '#QN_LAKE_SCHEMA_TABLE#', x.[QN_LakeSchemaTable]) 
			, '#MART_TABLE#', x.[MartTableName]) 
			, '#HUB_TABLE#', x.[MartTableName]) 
			, '#LAKE_TABLE#', x.[LakeTableName]) 
            AS [Content]
        /*#*---------- 📌 DETAIL  ----------*#*/
        ,o.[Desc]
        ,o.[Notes]
    FROM cteCode AS o
    CROSS JOIN cteParam AS x

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  UserDefinedFunction [UTL].[GetLakeQuery_PARTIAL]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





/*
    /*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT *
    FROM [UTL].[GetLakeQuery_PARTIAL]('Lake', 'APP', 'TranDetail'
    ,'MISC','[APP].[dbo].[TranDetail]'
    ,'PREPARATION'
    , 'CONDITION'
    ,'2026-01-01', '2026-01-31','2026-02-06T11:00:00');

	/*#*---------- 🧪 VALIDATION ----------*#*/
    SELECT TOP 10 x.*	
	FROM [UTL].[Setting] AS o 
    CROSS APPLY [UTL].[GetLakeQuery_PARTIAL]([LakeName], 'APP', 'TranDetail'
    ,'MISC', o.[QN_Core] + '.[SVC].[Sample_TranDetail]'
    ,'PREPARATION'
    , 'CONDITION'
    ,o.[CurrentTime], o.[CurrentTime], FORMAT([CurrentTime], [TimeStampFormat])
    ) AS x

*/
CREATE FUNCTION [UTL].[GetLakeQuery_PARTIAL]
(
    @Lake VARCHAR(100)
    ,@SchemaName VARCHAR(100)
    ,@TableName VARCHAR(100)
    ,@Source VARCHAR(100)
    ,@QN_SourceTable VARCHAR(500)
    ,@SourceTablePreparation VARCHAR(4000)
    ,@SourceTableCondidtion VARCHAR(4000)
    ,@StartDateStr VARCHAR(100)
    ,@EndDateStr VARCHAR(100)
    ,@TimeStampStr VARCHAR(100)
)
RETURNS TABLE
AS
RETURN
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
    WITH cteParam AS (
		SELECT [Lake] = @Lake
			,[SchemaName] = @SchemaName
			,[TableName]  = @TableName
			,[Source] = @Source
			,[QN_SourceTable] = @QN_SourceTable
			,[SourceTablePreparation]  = @SourceTablePreparation
			,[SourceTableCondidtion]  = @SourceTableCondidtion
			,[StartDateStr]= @StartDateStr
			,[EndDateStr]  = @EndDateStr
			,[TimeStampStr]  = @TimeStampStr
    )
	/*#*========== 🧩 PREPARE ==========*#*/
    ,cteTable AS (
		SELECT o.*
			/*#*---------- 📌 DETAIL ----------*#*/
			,[IngestionQuery_FULL_Template] = CONVERT(VARCHAR(4000), 'DELETE #LAKE#.#FULL# FROM #LAKE#.#FULL# AS o INNER JOIN #LAKE#.#OVERLAP# AS x ON x.[zID] = o.[zID]; 
			INSERT #LAKE#.#FULL# SELECT o.*  FROM #LAKE#.#PARTIAL# AS o; ') 

			/*#*---------- 📌 DETAIL ----------*#*/
			,[IngestionQuery_PARTIAL_Template] = CONVERT(VARCHAR(4000), 'TRUNCATE TABLE #LAKE#.#PARTIAL#; 
				#PREPARATION# 
			INSERT #LAKE#.#PARTIAL# 
			SELECT NEWID() AS zID, ''#SOURCE#@#TIMESTAMP#'' AS zSTMPz, o.*  FROM #SOURCE_TABLE# AS o 
				#CONDITION# ;')

			/*#*---------- 📌 DETAIL ----------*#*/
			,[ExtractionQuery_Template] = CONVERT(VARCHAR(4000), ' #PREPARATION# 
			SELECT NEWID() AS zID, ''#SOURCE#@#TIMESTAMP#'' AS zSTMPz, o.* FROM #SOURCE_TABLE# AS o 
				#CONDITION# ;')
			
			/*#*---------- 📌 DETAIL ----------*#*/
			,[ValidationQuery_Template] = CONVERT(VARCHAR(4000), 'SELECT * FROM  #LAKE#.#FULL#; 
			SELECT *  FROM #LAKE#.#PARTIAL#; 
			SELECT *  FROM #LAKE#.#OVERLAP#; ')
		FROM cteParam AS o
	)
	/*#*========== 🧩 PREPARE ==========*#*/
	, cteCN_Table AS (
		SELECT o.*
			,QUOTENAME(o.[Lake]) AS [LakeName_Qualified]
			,QUOTENAME(o.[SchemaName]) + '.' + QUOTENAME(o.[TableName] + '_FULL') AS [QN_Table_FULL]
			,QUOTENAME(o.[SchemaName]) + '.' + QUOTENAME(o.[TableName] + '_PARTIAL') AS [QN_Table_PARTIAL]
			,QUOTENAME(o.[SchemaName]) + '.' + QUOTENAME(o.[TableName] + '_OVERLAP') AS [QN_Table_OVERLAP]			
			--,o.[QN_SourceTable] AS [QN_SourceTable]
		FROM cteTable AS o
	)
	/*#*========== 🧩 PREPARE ==========*#*/
	,cteQuery AS (
		SELECT o.*
		/*#*---------- 📌 DETAIL ----------*#*/
		,[IngestionQuery_FULL] = REPLACE(REPLACE(REPLACE(REPLACE(o.[IngestionQuery_FULL_Template]
			, '#LAKE#', o.[LakeName_Qualified])
			, '#FULL#', o.[QN_Table_FULL])
			, '#OVERLAP#', o.[QN_Table_OVERLAP])
			, '#PARTIAL#', o.[QN_Table_PARTIAL])
		,[ValidationQuery] = REPLACE(REPLACE(REPLACE(REPLACE(o.[ValidationQuery_Template]
			, '#LAKE#', o.[LakeName_Qualified])
			, '#FULL#', o.[QN_Table_FULL])
			, '#OVERLAP#', o.[QN_Table_OVERLAP])
			, '#PARTIAL#', o.[QN_Table_PARTIAL]) 
		,[IngestionQuery_PARTIAL] = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(o.[IngestionQuery_PARTIAL_Template]
			, '#PARTIAL#', o.[QN_Table_PARTIAL])
			, '#LAKE#', o.[LakeName_Qualified]) 
			, '#SOURCE#', o.[Source]) 
			, '#SOURCE_TABLE#', o.[QN_SourceTable]) 
			, '#PREPARATION#', o.[SourceTablePreparation])
			, '#CONDITION#', o.[SourceTableCondidtion] ) 			
		/*------------------SOURCE------------------------*/		
		,[ExtractionQuery] = REPLACE(REPLACE(REPLACE(REPLACE([ExtractionQuery_Template]
			,'#SOURCE#', o.[Source])
			,'#SOURCE_TABLE#', o.[QN_SourceTable])
			, '#PREPARATION#', o.[SourceTablePreparation])
			, '#CONDITION#', o.[SourceTableCondidtion] ) 
		FROM cteCN_Table AS o
	)

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT CONVERT(VARCHAR(100), o.[SchemaName]) AS [SchemaName]
		,CONVERT(VARCHAR(100), o.[TableName]) AS [TableName]
		,CONVERT(VARCHAR(200), o.[QN_Table_FULL]) AS [QN_Table_FULL]
		,CONVERT(VARCHAR(200), o.[QN_Table_PARTIAL]) AS [QN_Table_PARTIAL]
		,CONVERT(VARCHAR(200), o.[QN_Table_OVERLAP]) AS [QN_Table_OVERLAP]
		,CONVERT(VARCHAR(4000), o.[QN_SourceTable]) AS [QN_SourceTable]
		,CONVERT(VARCHAR(4000), o.[ValidationQuery]) AS [ValidationQuery]
		,CONVERT(VARCHAR(4000), o.[IngestionQuery_FULL]) AS [IngestionQuery_FULL]
		,CONVERT(VARCHAR(4000), REPLACE(REPLACE(REPLACE(o.[IngestionQuery_PARTIAL]
			, '#TIMESTAMP#', o.[TimeStampStr])
			, '#START_DATE#', o.[StartDateStr])
			, '#END_DATE#', o.[EndDateStr])) 
			AS [IngestionQuery_PARTIAL]
		,CONVERT(VARCHAR(4000), REPLACE(REPLACE(REPLACE(o.[ExtractionQuery]
			, '#TIMESTAMP#', o.[TimeStampStr])
			, '#START_DATE#', o.[StartDateStr])
			, '#END_DATE#', o.[EndDateStr])) AS [ExtractionQuery]
	FROM cteQuery AS o

/*#*==================== 🔚 ====================*#*/

GO
/****** Object:  UserDefinedFunction [UTL].[GetLogParam]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
    /*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT *
    FROM [UTL].[GetLogParam]('', '[SVC].[ParentProc]')


*/
CREATE FUNCTION [UTL].[GetLogParam]
(
    @Controller VARCHAR(500) /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/    
    ,@Action VARCHAR(500) /*_*{Parameter},{@Action},{SP Id or Action Name}*_*/ 
)
RETURNS TABLE
AS
RETURN
(
    WITH cteParam AS (
        SELECT LEFT(REPLICATE('-', 10), 10) AS [Tag_Left]
        ,LEFT(REPLICATE('-', 10), 10) AS [Tag_Right]
        ,'' AS [Pretfix_BGN]
        ,' {BGN}' AS [Postfix_BGN]
        ,'' AS [Pretfix_END]
        ,' {END}' AS [Postfix_END]
        ,CASE WHEN ISNULL(@Controller,'') = '' THEN 'Ad-hoc' ELSE TRIM(@Controller) END  AS [Controller]
        ,ISNULL(TRIM(@Action), 'Unknown') AS [Action]
    )
    , cteProc AS (
        SELECT TOP (1)
         [ProcName] = QUOTENAME(OBJECT_SCHEMA_NAME(x.objectid, x.dbid))
                        + N'.'
                        + QUOTENAME(OBJECT_NAME(x.objectid, x.dbid))
        FROM sys.dm_exec_requests AS o
        CROSS APPLY sys.dm_exec_sql_text(o.sql_handle) AS x
        WHERE o.session_id = TRY_CONVERT(INT,@Action)
          AND x.objectid <> 0         
    )
    ,cteData AS (
        SELECT o.*
        ,CASE WHEN ISNULL(x.[ProcName], '') <> '' THEN x.[ProcName]
                   ELSE o.[Action] END AS [ActionX]
        FROM cteParam AS o
        LEFT JOIN cteProc AS x ON 1=1
    )
   /*#*========== ✅ OUTPUT ==========*#*/
   SELECT [Controller] = CASE WHEN o.[Controller] = 'Ad-hoc' 
                THEN o.[Controller] + FORMAT(GETDATE(), 'HHmmss') 
                ELSE @Controller END + '*' + ISNULL(o.[ActionX],'Unknown')
        ,o.[ActionX] AS [Action]
        ,[Message_BGN] = o.[Tag_Left] + o.[Pretfix_BGN] + o.[ActionX] + o.[Postfix_BGN] + o.[Tag_Right]
        ,[Message_END] = o.[Pretfix_END] + o.[ActionX] + o.[Postfix_END] 
   FROM cteData AS o
);
GO
/****** Object:  View [PAX].[KPI_Status]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





/*			
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%KPI_Status%';
	
	SELECT TOP 100 * 
	-- SELECT COUNT(*)
	FROM [PAX].[KPI_Status] AS o


*/
CREATE VIEW [PAX].[KPI_Status]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteData AS (
		SELECT o.*
        FROM (VALUES
                ('R', 'RED',     1.00,  '#FF0006', '#FF0006'),
                ('A', 'AMBER',   2.00,  '#FFBC00', '#FFBC00'),
                ('G', 'GREEN',   3.00,  '#00AA00', '#00AA00'),
                ('N', 'N.A.',    NULL,  '#76549F', '#76549F'),
                ('U', 'UNKNOWN', 0.00,  '#F2F2F2', '#F2F2F2')
        ) AS o ([Code], [Name], [Value], [BgColor], [TextColor] )
	)
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT CONVERT(VARCHAR(20), [Code]) AS [KPI_StatusCode]
        ,CONVERT(VARCHAR(20), [Name]) AS [KPI_StatusName]
        ,CONVERT(DECIMAL(18,4), [Value]) AS [KPI_StatusValue]
        ,CONVERT(VARCHAR(20), [BgColor]) AS [KPI_StatusBgColor]
        ,CONVERT(VARCHAR(20), [TextColor]) AS [KPI_StatusTextColor]
    FROM cteData AS o


/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [SVC].[_Template]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO















/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Template%';

	SELECT TOP 1000 * 
	-- SELECT * 
	FROM [SVC].[_Template] AS o
	ORDER BY 1,2,3

*/
CREATE VIEW [SVC].[_Template]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteData AS (
		SELECT *
		FROM (VALUES
			/*#*---------- 📌 DETAIL: Framework ----------*#*/
			('Subject', 'AXC', 'External Customer Related Informaiton', 'External Customer Related Information')
			,('Subject', 'UNC', 'Uncategorized or Others', 'Uncategorized or other subjects')
		) AS o ([Category], [Code], [Name], [Desc])
	)
	,cteTyped AS (	
		SELECT CONVERT(VARCHAR(50), o.[Category]) AS [Category]
			,CONVERT(VARCHAR(20), o.[Code]) AS [Code]
			,CONVERT(VARCHAR(100), o.[Name]) AS [Name]
			,CONVERT(VARCHAR(2000), o.[Desc]) AS [Desc]
		FROM cteData AS o
	)	

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.[Category]
		,o.[Code] AS [ConceptCode]
		,o.[Name] AS [ConceptName]		
		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[Desc] AS [ConceptDesc]
	FROM cteTyped AS o

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [SVC].[Dev_Concept]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Dev%';

	SELECT TOP 1000 * 
	-- SELECT * 
	FROM [SVC].[Dev_Concepts] AS o
	ORDER BY 1,2,3

*/
CREATE VIEW [SVC].[Dev_Concept]
AS
	/*#*========== 🎯 PURPOSE: Concepts ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteData AS (
		SELECT *
		FROM (VALUES
			/*#*---------- 📌 DETAIL: Framework ----------*#*/
			('Framework', 'TDAS', 'Transforming Data Analytics Solutions', 'Transforming Data Analytics Solutions (TDAS) means redefining how organizations turn data into actionable intelligence—by integrating modern technology, AI, and human expertise within a continuous Data–Knowledge–Action cycle to drive innovation and growth.')
			,('Framework', 'CTA', 'Cherry Tree Architecture', 'A cherry tree-inspired framework that depicts the evolution from raw data to actionable insights through five stages: roots (operational data), stem (harmonized repository), branches (analytical modeling), leaves (reports & dashboards), and cherries (high-value insights).')
			,('Framework', 'DKAS', 'Data–Knowledge Amplification Spiral', 'Describe how organisations become smarter through a continuous cycle of learning. Data is transformed into knowledge, knowledge is applied through action, and the outcomes of those actions generate new data that deepens understanding')
			,('Framework', 'MSF', 'Microsoft Fabric Data Platform', 'A unified analytics platform integrating data engineering, data science, real-time analytics, BI, and AI foundation models into a single SaaS solution—simplifying the entire data lifecycle.')
			,('Framework', 'FAT', 'Frontier Analytics Team', 'A specialized data professionals within an organization dedicated to pioneering advanced analytics and transforming how data is leveraged for business impact. Its mission is to push the boundaries of data-driven innovation by combining modern cloud technologies, automation, and artificial intelligence.')
			,('Framework', 'AIO', 'AI Insight Orchestrator', 'Blends deep Data & AI expertise with strong business understanding, using an experimental mindset to partner with stakeholders and deliver actionable insights.')
			,('Framework', 'UTL', 'The Execution Utility', 'A centralized orchestration framework that manages metadata, configuration, logging, reusable templates, shared functions, and core services to ensure consistency, scalability, and maintainability across the AI-driven analytics lifecycle.')
			,('Framework', 'BLM', 'Bloom AI Assistant', 'Bloom is an intelligent AI assistant that streamlines analytics workflows by orchestrating automation, guiding technical processes, and translating complex data into clear, business-friendly insights—empowering stakeholders to make informed decisions with confidence.')
			,('Framework', 'VST', 'Solution Template', 'A robust, scalable solution template that standardizes the architecture for AI-driven analytics, integrating core components like metadata management, configuration, logging, reusable templates, and shared services to ensure consistency and maintainability.')
			,('Framework', 'BH', 'Beehive', 'deep‑dive knowledge hub where data professionals access the concepts, skills, and frameworks that power transformative analytics.')
			,('Framework', 'TF', 'Transformation', 'Transformation is NOT about doing the same thing more or less — it is about doing things differently.')

			/*#*---------- 📌 DETAIL: Subject Area ----------*#*/
			,('Subject', 'MST', 'Master Data', 'Core data that is essential for operations, such as customer information, product details, and supplier records')
			,('Subject', 'SD', 'Sales and Distribution', 'Handles sales processes and distribution of products to customers.')
			,('Subject', 'INV', 'Inventory Management', 'Tracks inventory levels, orders, sales, and deliveries.')
			,('Subject', 'MFG', 'Manufacturing', 'Handles production planning, scheduling, and execution.')
			,('Subject', 'MRP', 'Material Requirements Planning', 'Manages inventory levels, production scheduling, and purchasing of materials.')
			,('Subject', 'SCM', 'Supply Chain Management', 'Manages the flow of goods, information, and finances through the supply chain.')
			,('Subject', 'PUR', 'Procurement and Purchasing', 'Manages the process of acquiring goods and services from external sources.')
			,('Subject', 'FIN', 'Financial Management', 'Manages financial accounting, controlling, and reporting.')
			,('Subject', 'PDM', 'Product Data Management', 'Manages product-related data and integrates it with other business processes.')
			,('Subject', 'QM', 'Quality Management', 'Ensures product quality by managing quality control processes.')
			,('Subject', 'PLM', 'Product Lifecycle Management', 'Manages the lifecycle of a product from inception through design and manufacturing.')
			,('Subject', 'CRM', 'Customer Relationship Management', 'Manages interactions with current and potential customers.')
			,('Subject', 'HR', 'Human Resources', 'Manages employee information, payroll, recruitment, and benefits.')
			,('Subject', 'EAM', 'Enterprise Asset Management', 'Manages the maintenance and lifecycle of physical assets.')
			,('Subject', 'PRJ', 'Project Management', 'Manages planning, executing, and closing of projects.')
			,('Subject', 'DMS', 'Document Management System', 'Handles the storage, management, and tracking of documents.')
			,('Subject', 'EHS', 'Environmental Health and Safety', 'Ensures compliance with environmental, health, and safety regulations.')
			,('Subject', 'WMS', 'Warehouse Management System', 'Manages warehouse operations like picking, packing, and shipping.')
			/*#*---------- 📌 DETAIL: More Subject Area ----------*#*/			
			,('Subject', 'AXC', 'External Customer Related Informaiton', 'External Customer Related Information')
			,('Subject', 'UNC', 'Uncategorized or Others', 'Uncategorized or other subjects')

		) AS o ([Category], [Code], [Name], [Desc])
	)
	,cteTyped AS (	
		SELECT CONVERT(VARCHAR(50), o.[Category]) AS [Category]
			,CONVERT(VARCHAR(20), o.[Code]) AS [Code]
			,CONVERT(VARCHAR(100), o.[Name]) AS [Name]
			,CONVERT(VARCHAR(2000), o.[Desc]) AS [Desc]
		FROM cteData AS o
	)
	

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.[Category]
		,o.[Code] AS [ConceptCode]
		,o.[Name] AS [ConceptName]		
		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[Desc] AS [ConceptDesc]
	FROM cteTyped AS o

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [SVC].[Dev_Convention]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
















/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Dev%';

    /*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT  * 
	FROM [SVC].[Dev_Convention] AS o
    WHERE o.[Type] = 'Name'
    
    /*#*---------- 🔍 EXAMPLE: Code ----------*#*/
    
    SELECT o.*
    FROM [SVC].[Dev_CodeSnippet] AS o


*/
CREATE VIEW [SVC].[Dev_Convention]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT CONVERT(VARCHAR(50), o.[Type]) AS [Type]
       ,CONVERT(VARCHAR(100), o.[Scope]) AS [Scope]
       ,CONVERT(VARCHAR(100), o.[Category]) AS [Category]
       ,CONVERT(VARCHAR(8000), o.[Content]) AS [Content]
       ,CONVERT(VARCHAR(500), o.[Desc]) AS [Desc]
       ,CONVERT(VARCHAR(500), o.[Notes]) AS [Notes]
    FROM (VALUES
      (N'Code', N'General',   N'Solution',              N'/*#*==================== 🔚 ====================*#*/', N'Marks the closing section', '')

        /* ---------- 📌 DETAIL: Code ---------- */
      , (N'Code', N'General',   N'Testing',               N'/*#*---------- 🧪 VALIDATION ----------*#*/',       N'Ensures the logic operates correctly and meets requirements', '')
      , (N'Code', N'General',   N'Use Case',              N'/*#*---------- 🔍 EXAMPLE ----------*#*/',          N'Provides examples of expected inputs, outputs, or usage patterns', '')
      , (N'Code', N'Proc',      N'Log',                   N'/*#*---------- 📝 LOGGING ----------*#*/',          N'Records key actions, results, and execution details', '')
      , (N'Code', N'Proc',      N'Initialisation',        N'/*#*========== 🎯 PURPOSE ==========*#*/',          N'Explains the intended function of this artefact', '')
      , (N'Code', N'Proc',      N'Config',                N'/*#*---------- 🔧 CONFIG ----------*#*/',           N'Contains adjustable settings and parameters', '')
      , (N'Code', N'Proc',      N'Deletion',              N'/*#*---------- ♻️ EMPTY ----------*#*/',            N'Deletes data from the target table as required', '')
      , (N'Code', N'General',   N'Detail Section',        N'/*#*---------- 📌 DETAIL ----------*#*/',           N'Describes this specific part of the code', '')
      , (N'Code', N'Proc',      N'Control',               N'/*#*########## 📚 SECTION ##########*#*/',          N'Represents a logical processing section', '')
      , (N'Code', N'General',   N'Control, Processing',   N'/*#*---------- 📄 PARAMETER ----------*#*/',        N'Defines values used to control or influence logic', '')
      , (N'Code', N'General',   N'Preparation',           N'/*#*========== 🧩 PREPARE ==========*#*/',          N'Provides intermediate structures for data processing', '')
      , (N'Code', N'Proc',      N'Function',              N'/*#*========== ✅ ACTION ==========*#*/',           N'Executes the primary operation', '')
      , (N'Code', N'View',      N'Query',                 N'/*#*========== ✅ OUTPUT ==========*#*/',           N'Produces the final query output', '')
      , (N'Code', N'Proc',      N'Cleanup',               N'/*#*---------- 🧹 CLEANUP ----------*#*/',          N'Performs cleanup and housekeeping tasks', '')
      , (N'Code', N'General',   N'Development',           N'/*#*---------- 🐌 SLOW ----------*#*/',             N'Requires extended processing time', '')

        /* ---------- 📌 DETAIL: Additional ---------- */
      , (N'Code', N'General',   N'Development',           N'/*#*---------- 🐱 MISC ----------*#*/',             N'Additional notes or supporting details', '')
      , (N'Code', N'General',   N'Development',           N'/*#*---------- 🐶 MISC ----------*#*/',             N'Additional notes or supporting details', '')
      , (N'Code', N'General',   N'Development',           N'/*#*---------- 🐰 MISC ----------*#*/',             N'Additional notes or supporting details', '')
      , (N'Code', N'General',   N'Development',           N'/*#*---------- 🐸 MISC ----------*#*/',             N'Additional notes or supporting details', '')
      , (N'Code', N'General',   N'Development',           N'/*#*---------- 🐹 MISC ----------*#*/',             N'Additional notes or supporting details', '')
      , (N'Code', N'General',   N'Development',           N'/*#*---------- 💬 NOTES ----------*#*/',            N'Additional notes or supporting details', '')
      , (N'Code', N'General',   N'Development',           N'/*#*---------- ⚠️ WARNING ----------*#*/',          N'Highlights important cautions or potential risks', '')
      , (N'Code', N'General',   N'Development',           N'/*#*---------- 🐞 NEW CODE ----------*#*/',         N'Indicates newly added or updated logic', '')

        /* ---------- 📌 DETAIL: Tags ---------- */
      , (N'Name', N'Universal', N'Unique ID',             N'zID',                         N'Global unique key at the storage layer',            N'GUID')
      , (N'Name', N'Universal', N'Updated Time',          N'zUPD',                        N'Last‑updated timestamp at the storage layer',       N'20260116T130521')
      , (N'Name', N'Object',    N'Unique GUID',           N'zIDz',                        N'Global unique key at the object level',             N'')
      , (N'Name', N'Object',    N'App & Timestamp',       N'zSTMPz',                      N'Identifies the source, system, and timestamp', N'ERP1.LIVE@0116T0204')

      /* ---------- 📌 DETAIL: Division Key & Business Key ---------- */
      , (N'Name', N'Key', N'Division A,B,C',                         N'DV_A/B/C',      N'Data segmentation classified from A to C',                                  N'DV_A: Group; DV_B: Country; DV_C: International/Domestic')
      , (N'Name', N'Key', N'Business Key of Data Entity',            N'BK_DE',         N'Business key for the current data entity',                                 N'Product: ALL+P100; Customer: CRM1+CUST-A')
      , (N'Name', N'Key', N'Business Key of Data Source',            N'BK_SRC',        N'Business key for the source system',                                       N'EPR1, CRM1, MISC')
      , (N'Name', N'Key', N'Business Key of Reference Entity',       N'BK_?',          N'Business key for the reference entity',                                     N'BK_Product, BK_Invoice, BK_OrderLine')

      /* ---------- 📌 DETAIL: Automation Control ---------- */
      , (N'Name', N'Automation', N'Schedule Job',          N'SYS_ASCH_?',         N'Automated scheduled job identifier',                   N'SYS_ASCH_MAIN')
      , (N'Name', N'Automation', N'Manual Job',            N'SYS_MAN_?',          N'Manual execution step or job',                         N'SYS_MAN_Config')
      , (N'Name', N'Automation', N'Step',                  N'SYS_[...pattern]',   N'Action classified by relevance, stage, app, and type', N'Example included in original comment')
      , (N'Name', N'Automation', N'Schedule Instance',     N'AC_SCH',            N'An automated process run at scheduled times',          N'SYS*MAIN@0115T0536')
      , (N'Name', N'Automation', N'Schedule Time',         N'AC_SCHD',           N'The scheduled execution time in the selected timezone', '')

      /* ---------- 📌 DETAIL: Offset ---------- */
      , (N'Name', N'Offset', N'As at Date',                N'OF_ASAT', N'Date the data is effective as of',                                     N'Day prior to scheduled date')
      , (N'Name', N'Offset', N'Offset',                    N'OF_ALL',  N'How far a subset is shifted back in time from its As At Date',          N'0=current, –1=prior, –2=earlier')
      , (N'Name', N'Offset', N'Offset by Day',             N'OF_DAY',  N'Subset indicator for multiple same-day versions',                       N'Multiple subsets on same day')
      , (N'Name', N'Offset', N'Offset by Month',           N'OF_MTH',  N'Subset indicator for multiple same-month versions',                     N'Multiple subsets in same month')

      /* ---------- 📌 DETAIL: Attribute & Metric ---------- */
      , (N'Name', N'Attribute', N'Critical Attribute',     N'EntityAttribute_Qualifier',   N'Business‑critical attribute',                                            N'')
      , (N'Name', N'Attribute', N'Quote Name',             N'QN_Entity',                   N'Indicates a Quote Name attribute',                                       N'QN_Table: [Log]; QN_SchemaTable: [SVC].[Log]')
      , (N'Name', N'Attribute', N'Capsule',                N'CX_DE',                       N'Additional attributes stored in JSON format',                            N'{"Utility":{"ExtA":"Demo","ExtB":"Data"}}')
      , (N'Name', N'Attribute', N'Deeplink',               N'DL_DE',                       N'Deep link into a specific location of an application',                   N'https://URL/?Param=1234')
      , (N'Name', N'Attribute', N'Derived Attribute',      N'CA_Attribute',                N'Attribute derived from business rules',                                   N'CA_Status')
      , (N'Name', N'Metric',    N'Derived Metric',         N'CA_Metric_Qualifier',         N'Metric derived from business rules',                                      N'CA_Value_USD, CA_UnitCost_AUD_KG')

      , (N'Name', N'Attribute', N'Model', N'CA_Status/zStatus', N'Indicates record validity state',                                      N'Active, Inactive, Valid, Invalid')
      , (N'Name', N'Attribute', N'Model', N'CA_Flag/zFlag',     N'Integer indicator representing record conditions',                       N'-1, 0, 1, 10')
      , (N'Name', N'Attribute', N'Model', N'CA_Lock/zLock',     N'Lock combination accessible only with proper role permissions',         N'Lock: G1/AU/DOM, G2/NZ/INT')
      , (N'Name', N'Attribute', N'Model', N'CA_Memo',           N'Notes describing applied business rules',                               N'Using monthly exchange rates from Finance')

      /* ---------- 📌 DETAIL: Workspace ---------- */
      , (N'Name', N'Workspace', N'Solution', N'CORE',       N'Core platform components including storage, scheduling, and processing',      N'Storage, Pipeline, Notebook and more')
      , (N'Name', N'Workspace', N'Solution', N'MODEL',      N'Data models for reporting and analytics',                                    N'M900 - Template')
      , (N'Name', N'Workspace', N'Solution', N'EXCHANGE',   N'Shared storage for internal/external data exchange',                         N'EXCHANGE')
      , (N'Name', N'Workspace', N'Solution', N'Business Function?', N'Reports tailored to specific business functions',                        N'Marketing; Sales; Supply Chain')

      /* ---------- 📌 DETAIL: Database ---------- */
      , (N'Name', N'Database', N'Lake/Root',    N'Lake',   N'Raw data preserved exactly as received',                            N'Original Data Object (ODO)')
      , (N'Name', N'Database', N'Core/Crew',    N'Core',    N'Harmonised, standardised, denormalised, analytics‑ready core data with supporting functions',                N'Harmonized Data Entity (HDE), Analytical Data Entity (ADE)')
      
      /* ---------- 📌 DETAIL: Framework ---------- */
      , (N'Name', N'Framework', N'Relevance',  N'A, B, C, S, U',     N'Describes how central an artefact is to delivering the solution',          N'A‑Primary; B‑Supporting; C‑Supplemental; S‑Services; U‑Unclassified')
      , (N'Name', N'Framework', N'Stage',      N'1–6; 0, 9',         N'Shows where the artefact sits in the data lifecycle',                     N'1‑Extract & Ingest; 2‑Load; 3‑Refresh; 4‑Update; 5‑Query; 6‑Cache; 0‑Prepare; 9‑Finalize')
      , (N'Name', N'Framework', N'Depth',      N'S, F, C',           N'Indicates scope of system impact',                                        N'S‑Structural; F‑Functional; C‑Cosmetic')
      , (N'Name', N'Framework', N'Scope',      N'U, G, S',           N'Indicates breadth of applicability',                                      N'U‑Universal; G‑General; S‑Specific')
      , (N'Name', N'Framework', N'Approach',   N'E, B, S',           N'Progressive approach to analytics maturity',                              N'Easier > Better > Smarter')
      , (N'Name', N'Framework', N'Artifact Quality Score (AQS)', N'AQS1‑5', N'Evaluates deliverable completeness, robustness, and usability',       N'1‑Weak; 2‑Fair; 3‑Good; 4‑Strong; 5‑Excellent')
      , (N'Name', N'Framework', N'Logic Complexity Level (LCL)', N'LCL1‑5', N'Measures complexity of business or transformation logic',             N'1‑Direct; 2‑Basic; 3‑Complex; 4‑Aggregated; 5‑Multi‑stage')

      /* ---------- 📌 DETAIL: Actions ---------- */
      , (N'Name', N'Verb', N'Lake/Root',     N'Extract',   N'Pull data from source systems',                              N'_XTR')
      , (N'Name', N'Verb', N'Lake/Root',     N'Ingest',    N'Store raw data into the lake',                               N'_ING')
      , (N'Name', N'Verb', N'Hub/Steam',     N'Load',      N'Move data from Lake to Hub',                                 N'_MST_Load')
      , (N'Name', N'Verb', N'Mart/Branch',   N'Refresh',   N'Transfer data from Hub to Mart',                             N'_MST_Refresh; _MST_Refresh_C2; _MST_Refresh_MEG')
      , (N'Name', N'Verb', N'Mart/Branch',   N'Update',    N'Apply business rules within the Mart',                        N'_TRN_Update; _TRN_Update_C2; _TRN_Update_END')
      , (N'Name', N'Verb', N'Query/Leaf',    N'Query',     N'Extract data using defined logic',                            N'AVQ.GetTemplate')
      , (N'Name', N'Verb', N'Query/Leaf',    N'Reload',    N'Retrieve and cache data for consumption',                     N'SalesSummary_CurrentFY_Reload')
      , (N'Name', N'Verb', N'Query/Leaf',    N'Refine',    N'Enhance results via further logic or transformations',         N'PMF.AGG_Template_Reload; PMF.KPI_Update')
      , (N'Name', N'Verb', N'Service',       N'Prepare',   N'Set up required conditions or inputs',                        N'X050_Prepare')
      , (N'Name', N'Verb', N'Service',       N'Finalize',  N'Complete the workflow',                                      N'X900_Finalize')
      , (N'Name', N'Verb', N'Service',       N'Reload',    N'Retrieve and cache data for platform functions',              N'ReloadProc')
      , (N'Name', N'Verb', N'Service',       N'Prune',     N'Remove obsolete or unnecessary data',                         N'SVC.Prune')
      , (N'Name', N'Verb', N'Service',       N'Config',    N'Adjust settings and parameters',                              N'')
      , (N'Name', N'Verb', N'Service',       N'Add',       N'Add new data or values',                                     N'AddColumnProperity')
      , (N'Name', N'Verb', N'Service',       N'Insert',    N'Insert new record',                                          N'InsertProperity')
      , (N'Name', N'Verb', N'Utility',       N'Empty',     N'Clear all records from a table',                              N'EmptyTable')
      , (N'Name', N'Verb', N'Utility',       N'Remove',    N'Remove specific record(s)',                                  N'RemoveDuplication')
      , (N'Name', N'Verb', N'Service',       N'Get',       N'Retrieve a specific value or record',                         N'GetLog')
      , (N'Name', N'Verb', N'Service',       N'List',      N'Retrieve a set of records',                                  N'FindX')
      , (N'Name', N'Verb', N'Service',       N'Set',       N'Assign a specific value',                                     N'SetOffset')
      , (N'Name', N'Verb', N'Service',       N'Discover',  N'Identify patterns or insights',                               N'X101_Run; X101 - TopSales')

      /* ---------- 📌 DETAIL: Schema ---------- */
      , (N'Name', N'Schema', N'Component Code',   N'L, H, M, Q, U',   N'Letter identifying type of data layer',                             N'L=Lake, H=Hub, M=Mart, Q=Query, U=Utility')
      , (N'Name', N'Schema', N'Storage',          N'ZL, ZH, ZM, ZQ, ZU', N'Physical storage layer for data',                              N'Tables and Procs')
      , (N'Name', N'Schema', N'Accessible View',  N'AVL, AVH, AVM, AVQ', N'Views for accessing platform data',                           N'Views')
      , (N'Name', N'Schema', N'View Pointer',     N'VPL, VPH, VPM, VPQ, VPU', N'Views pointing back to raw or upstream sources',        N'Views')
      , (N'Name', N'Schema', N'Automation Control', N'ACH, ACM, ACQ, ACU', N'Controls and manages automated actions',                   N'Procs')

      , (N'Name', N'Schema', N'Utility',      N'UTL',    N'Shared or supporting functions',                N'Tables, Views, Procs')
      , (N'Name', N'Schema', N'Services',     N'SVC',    N'Platform, System, or solution-level services', N'Tables, Views, Funcs, Procs')
      , (N'Name', N'Schema', N'Miscellaneous',N'MISC',   N'General storage not fitting other categories',     N'Tables, Views, Funcs, Procs')

      /* ---------- 📌 DETAIL: Concepts ---------- */
      , (N'Name', N'Concept', N'Template',     N'TPL',   N'Reusable development template',                    N'_TPL_REF; _TPL_TRN; _Template')
      , (N'Name', N'Concept', N'Reference',    N'REF',   N'Reference data entities',                          N'_Refresh_REF; _Update_REF')
      , (N'Name', N'Concept', N'Transaction',  N'TRN',   N'Event‑based data entities',                        N'_Refresh_TRN; _Update_TRN')
      , (N'Name', N'Concept', N'Master Data',  N'MST',   N'Master / reference entities',                      N'MST_Product; MST_Customer')
      , (N'Name', N'Concept', N'Application',  N'APP',   N'Source system identifier',                         N'ERP1; CRM1; MISC')
      , (N'Name', N'Concept', N'Subject',      N'ABC',   N'High‑level business or functional domain',         N'Examples: SD, INV, PUR')

    ) AS o([Type], [Scope], [Category], [Content], [Desc], [Notes]);

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [SVC].[Dev_Emoji]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/*			
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Dev%';
	
	SELECT TOP 10 * 
	-- SELECT COUNT(*)
	FROM [SVC].[Dev_Emoji]
	Order by CodePointHex

*/
CREATE VIEW [SVC].[Dev_Emoji]
AS
	/*#*========== 🎯 PURPOSE: List all emoji block ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteRanges AS (
		SELECT *
		FROM (VALUES
			(CAST(0x1F300 AS INT), CAST(0x1F5FF AS INT), 'Misc Symbols & Pictographs'),
			(CAST(0x1F600 AS INT), CAST(0x1F64F AS INT), 'Emoticons'),
			(CAST(0x1F680 AS INT), CAST(0x1F6FF AS INT), 'Transport & Map'),
			(CAST(0x1F900 AS INT), CAST(0x1F9FF AS INT), 'Supplemental Symbols & Pictographs'),
			(CAST(0x1FA70 AS INT), CAST(0x1FAFF AS INT), 'Symbols & Pictographs Extended-A'),
			(CAST(0x2600  AS INT), CAST(0x26FF  AS INT), 'Miscellaneous Symbols'),
			(CAST(0x2700  AS INT), CAST(0x27BF  AS INT), 'Dingbats')
		) AS o(StartCP, EndCP, BlockName)
	)
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.BlockName
    ,CONVERT(VARCHAR(50),CONCAT('U+', FORMAT(x.[value], 'X'))) AS CodePointHex
    ,x.[value] AS CodePointDec
    ,NCHAR(x.[value]) COLLATE Latin1_General_100_CI_AS_SC AS Glyph
	FROM cteRanges AS o
	CROSS APPLY GENERATE_SERIES(o.StartCP, o.EndCP, 1) AS x

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [SVC].[Timezone]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


















/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Time%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 1000 * 
	-- SELECT COUNT(*)
	FROM [SVC].[Timezone]
	ORDER BY 1,2,3

*/
CREATE VIEW [SVC].[Timezone]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
    WITH cteVariable AS (
            SELECT CONVERT(DATETIME, '2025-01-15') AS [Season1]
            , CONVERT(DATETIME, '2025-07-15') AS [Season3]            
    )
    ,cteData AS (
        SELECT *
        FROM (VALUES 
            ('Standard', 'UTC', 'Z00', 'Universal', 'Active')
            ,('Default', 'Cen. Australia Standard Time', 'ZA1', 'Adelaide', 'Active')
            ,('Standard', 'AUS Eastern Standard Time', 'ZA2', 'Melbourne, Sydney', 'Active')
            ,('Standard', 'China Standard Time', 'ZC1', 'Beijing, Shanghai, Hong Kong, Singapore, Kuala Lumpur, Perth', 'Active')
            ,('Standard', 'Romance Standard Time', 'ZE1', 'Paris, Madrid, Monaco', 'Active')
            ,('Standard', 'Arabian Standard Time', 'ZM1', 'Dubai, Muscat', 'Active')
            ,('Standard', 'New Zealand Standard Time', 'ZN1', 'Wellington', 'Active')
            ,('Standard', 'India Standard Time', 'ZS1', 'New Delhi', 'Active')
            ,('Standard', 'SE Asia Standard Time', 'ZS2', 'Bangkok, Jakarta', 'Inactive')
            ,('Standard', 'US Eastern Standard Time', 'ZU1', 'New York, Boston, Washington D.C.', 'Active')
            ,('Standard', 'Central Standard Time', 'ZU2', 'Chicago', 'Active')
            ,('Standard', 'Pacific Standard Time', 'ZU3', 'Los Angeles', 'Active')
        ) AS o ([Category], [Name], [Code], [LocationList], [Status])
        
    )
    ,cteTyped AS (
       SELECT CONVERT(VARCHAR(50), o.[Category]) AS [Category]
            ,CONVERT(VARCHAR(50), o.[Code]) AS [Code]
			,CONVERT(VARCHAR(200), o.[Name]) AS [Name]			
			,CONVERT(VARCHAR(500), o.[LocationList]) AS [LocationList]
            ,CONVERT(VARCHAR(50), o.[Status]) AS [Status]
		FROM cteData AS o
    )
	
    /*#*========== ✅ ACTION ==========*#*/   
    SELECT CONVERT(VARCHAR(100), CONCAT_WS('+'
            ,'Z' + FORMAT(ROW_NUMBER() OVER (ORDER BY o.[current_utc_offset], o.[name]), '000') 
            ,o.[name]
            ,QUOTENAME(o.[current_utc_offset])            
        )) AS [BK_DE]
        ,x.[Code] AS [ZoneCode]
        ,x.[Name] AS [ZoneName]
        ,x.[Category] AS [ZoneCategory]
        ,x.[Status] AS [ZoneStatus]
        /*#*---------- 📌 DETAIL ----------*#*/
        ,CONVERT(VARCHAR(100), CASE WHEN DATEPART(TZOFFSET, v.[Season1] AT TIME ZONE o.[name]) <> DATEPART(TZOFFSET, v.[Season3] AT TIME ZONE o.[name])
            THEN 'Daylight Saving' ELSE 'No Daylight Saving' END) AS [DaylightSavingStatus]
        ,CONVERT(VARCHAR(20), o.[current_utc_offset]) AS [TimeOffset]
        ,CONVERT(VARCHAR(100), o.[name]) AS [DatabaseTimezoneName]
        ,x.[LocationList] AS [LocationList]        
    FROM sys.time_zone_info AS o
    INNER JOIN cteTyped AS x ON x.[Name] = o.[name]
    CROSS JOIN cteVariable AS v

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [VPL].[AUT_IngestionParam]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO












/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Ingestion%';

	SELECT  * 
	FROM [VPL].[AUT_IngestionParam]
    ORDER BY [SourceApp], [ScheduleName],[ProcessCode], [IngestionSeq]


*/
CREATE VIEW [VPL].[AUT_IngestionParam]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/
	
    /*#*========== 🧩 PREPARE ==========*#*/	
    WITH cteRaw AS (
        SELECT o.[ScheduleList]
        ,o.[ProcessNo]        
        ,o.[LakeSchemaName]
        ,o.[LakeTableName]
        ,o.[SourceApp]
        ,o.[QN_SourceTable]
        ,o.[Pattern]
        ,[ProcessCode] = 'P1' + FORMAT(o.[ProcessNo], '00')
        FROM [V90_Lake].[AAL].[IngestionParam] AS o
    )
    ,ctePattern AS (
        SELECT o.*
            ,[LakeTableName_WithPattern] = CASE WHEN o.[Pattern] = 'Partial' THEN [LakeTableName] + '_PARTIAL' ELSE [LakeTableName] END
            ,[StepName] = 'Standard'
            ,[StepSeq] = 1
        FROM cteRaw AS o
        UNION 
        SELECT o.*
            ,[LakeTableName_WithPattern] = [LakeTableName] + '_FULL'
            ,[StepName] = 'Delayed'
            ,[StepSeq] = 2
        FROM cteRaw AS o
        WHERE o.[Pattern] = 'Partial'
    )
    ,cteData AS (
        SELECT o.*
            ,[ScheduleName] = TRIM(x.[Value])            
        FROM ctePattern AS o
        CROSS APPLY STRING_SPLIT(o.[ScheduleList], ',') AS x        
    )
    /*#*========== ✅ OUTPUT ==========*#*/
    SELECT CONCAT_WS('+', o.[LakeTableName_WithPattern], o.[ScheduleName], o.[StepName], o.[ProcessCode]) AS [BK_DE]
        ,o.[SourceApp]
        ,o.[ScheduleName]
        ,o.[ProcessCode]
        ,o.[StepName]
        ,o.[StepSeq]        
        ,o.[LakeSchemaName]
        ,[LakeTableName] = o.[LakeTableName_WithPattern]
        ,[QN_LakeTable] = QUOTENAME(o.[LakeSchemaName]) + '.' + QUOTENAME(o.[LakeTableName_WithPattern])
        ,[QN_LakeTable_Group] = QUOTENAME(o.[LakeSchemaName]) + '.' + QUOTENAME(o.[LakeTableName])
        ,o.[QN_SourceTable]          
        ,o.[Pattern]
        ,[IngestionSeq] = ROW_NUMBER() OVER (PARTITION BY o.[ScheduleName], o.[SourceApp], o.[ProcessCode] ORDER BY o.[StepSeq], o.[QN_SourceTable] )
        ,o.[ScheduleList]
    FROM cteData AS o


/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [VPL].[KPI_Definition]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO














/*	
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%KPI%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT  * 
	FROM [VPL].[KPI_Definition]
	ORDER BY 3,4,5

*/
CREATE VIEW [VPL].[KPI_Definition]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/
	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteDefinition AS (	
		SELECT [KPI_Code] = '101'
			,[KPI_Name] = N'Total Value'
			,[KPI_Description] = N'Total value in consolidated currency by group'
			,[KPI_Seq] = '1010'
			,[KPI_StatusCode_Default] = N'U'
			,[KPI_StatusName_Default] = N'UNKNOWN'
			,[KPI_StatusValue_Default] = 0.00
			/*#*---------- 📌 DETAIL ----------*#*/
			,[KPI_CategoryCode] = '1'
			,[KPI_CategoryName] = N'Revenue'
			,[KPI_CategoryGroup] = N'General'
			,[KPI_CategorySeq] = '10'
			/*#*---------- 📌 DETAIL ----------*#*/
			,[KPI_Format] = N'Thousand', [KPI_FormatString] = N'#,0,.0K'
			--,[KPI_Format] = N'Million', [KPI_FormatString] = N'#,0,,.0M'
			,[DrillThroughLink] = N''
			,[DrillThroughReport] = N'N.A.'	
	)	
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT [KPI_Code] = CONVERT(VARCHAR(50), o.[KPI_Code])
      ,[KPI_Name] = CONVERT(VARCHAR(100), o.[KPI_Name])
      ,[KPI_Description] = CONVERT(VARCHAR(500), o.[KPI_Description])
      ,[KPI_Seq] = CONVERT(VARCHAR(10), o.[KPI_Seq])
      ,[KPI_StatusCode_Default] = CONVERT(VARCHAR(50), o.[KPI_StatusCode_Default])
      ,[KPI_StatusName_Default] = CONVERT(VARCHAR(50), o.[KPI_StatusName_Default])
      ,[KPI_StatusValue_Default] = CONVERT(VARCHAR(50), o.[KPI_StatusValue_Default])
      ,[KPI_CategoryCode] = CONVERT(VARCHAR(50), o.[KPI_CategoryCode])
      ,[KPI_CategoryName] = CONVERT(VARCHAR(50), o.[KPI_CategoryName])
      ,[KPI_CategoryGroup] = CONVERT(VARCHAR(50), o.[KPI_CategoryGroup])
	  ,[KPI_CategorySeq] = CONVERT(VARCHAR(10), o.[KPI_CategorySeq])
      ,[KPI_Format] = CONVERT(VARCHAR(50), o.[KPI_Format])
      ,[KPI_FormatString] = CONVERT(VARCHAR(50), o.[KPI_FormatString])
      ,[DrillThroughLink] = CONVERT(VARCHAR(500), o.[DrillThroughLink])
      ,[DrillThroughReport] = CONVERT(VARCHAR(50), o.[DrillThroughReport])
	FROM cteDefinition AS o
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [VPL].[KPI_Target]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO














/*	
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%KPI%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT  * 
	FROM [VPL].[KPI_Target]
	ORDER BY 3,4,5

*/
CREATE VIEW [VPL].[KPI_Target]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/
	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteOrg AS (
		SELECT [OrgCode] = 'G1'
		,[OrgName] = 'Group 1'
	)
	,cteTarget AS (	
		SELECT [KPI_Code] = '101'
			,[OrgCode] = 'G1'
			/*#*---------- 📌 DETAIL ----------*#*/
			,[Green_State] = N'>= Target'
			,[Amber_State] = N'>=95% of Target'
			,[Red_State] = N'< 95% of Target'
			/*#*---------- 📌 DETAIL ----------*#*/
			,[StartDate] = '2024-07-01'
			,[EndDate] = '2026-01-31'
			/*#*---------- 📌 DETAIL ----------*#*/
			,[KPI_TargetValue] = 1.0
			,[KPI_TargetValue_Left] = 0.95
			,[KPI_TargetValue_Right] = 1.0
			/*#*---------- 📌 DETAIL ----------*#*/			
			,[KPI_TargetType] = N'Higher is better'
		UNION 
		SELECT [KPI_Code] = '101'
			,[OrgCode] = 'G1'
			/*#*---------- 📌 DETAIL ----------*#*/
			,[Green_State] = N'>= Target'
			,[Amber_State] = N'>=97% of Target'
			,[Red_State] = N'< 97% of Target'
			/*#*---------- 📌 DETAIL ----------*#*/
			,[StartDate] = '2026-02-01'
			,[EndDate] = NULL
			/*#*---------- 📌 DETAIL ----------*#*/
			,[KPI_TargetValue] = 1.0
			,[KPI_TargetValue_Left] = 0.97
			,[KPI_TargetValue_Right] = 1.0
			/*#*---------- 📌 DETAIL ----------*#*/			
			,[KPI_TargetType] = N'Higher is better'
	)
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT [KPI_Code] = CONVERT(VARCHAR(50), o.[KPI_Code])
      ,[OrgCode] = CONVERT(VARCHAR(50), o.[OrgCode])
	  ,[OrgName] = CONVERT(VARCHAR(50), rOrg.[OrgName])
      ,[Green_State] = CONVERT(VARCHAR(50), o.[Green_State])
      ,[Amber_State] = CONVERT(VARCHAR(50), o.[Amber_State])
      ,[Red_State] = CONVERT(VARCHAR(50), o.[Red_State])
      ,[StartDate] = CONVERT(DATETIME2(0), o.[StartDate])
      ,[EndDate] = CONVERT(DATETIME2(0), o.[EndDate])
      ,[KPI_TargetValue] = CONVERT(DECIMAL(18,6), o.[KPI_TargetValue])
      ,[KPI_TargetValue_Left] = CONVERT(DECIMAL(18,6), o.[KPI_TargetValue_Left])
      ,[KPI_TargetValue_Right] = CONVERT(DECIMAL(18,6), o.[KPI_TargetValue_Right])
      ,[KPI_TargetType] = CONVERT(VARCHAR(50), o.[KPI_TargetType])
	FROM cteTarget AS o
	INNER JOIN cteOrg AS rOrg ON rOrg.[OrgCode] = o.[OrgCode]

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [VPL].[Meta_ViewScript]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


















/*	
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%Meta%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT  * 
	FROM [VPL].[Meta_ViewScript]
	ORDER BY 3

*/
CREATE VIEW [VPL].[Meta_ViewScript]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT CONVERT(VARCHAR(50), 'V90_Lake') AS [DatabaseName]
		,s.[name] AS [SchemaName]
		,v.[name] AS [TableName]
		,m.[definition] AS [ViewScript]
	FROM [V90_Lake].[sys].[views] AS v
	INNER JOIN [V90_Lake].[sys].[schemas] AS s ON v.[schema_id] = s.[schema_id]
	INNER JOIN [V90_Lake].[sys].[sql_modules] AS m ON v.[object_id] = m.[object_id]

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [VPL].[MISC_TPL_REF]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









/*	
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%MISC%' , 'View';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT  * 
	FROM [VPL].[MISC_TPL_REF]
	ORDER BY 3,4,5

*/
CREATE VIEW [VPL].[MISC_TPL_REF]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/
	
	/*#*========== 🧩 PREPARE ==========*#*/	
	WITH cteData AS
	(
		SELECT
			 cfg.[BK_SRC_MISC] AS [BK_SRC]
			,o.[RefCode]
			,o.[RefName]
			,o.[RefDesc]
			,o.[RefSeq]
			,o.[RefNo]
			,o.[RefStatus]
			,o.[RefCategory]
			,o.[RefType]
		FROM [V90_Lake].[MISC].[_TPL_REF] AS o
		CROSS JOIN [V90_Lake].[AAL].[Setting] AS cfg
	)

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.[BK_SRC]
		,CONCAT_WS('+', o.[BK_SRC], o.[RefCode]) AS [BK_DE]		
      ,o.[RefCode] AS [EntityCode]
      ,o.[RefName] AS [EntityName]
	  ,o.[RefDesc] AS [EntityDesc]
      ,o.[RefSeq] AS [EntitySeq]
	  ,o.[RefNo] AS [EntityNo]
	  ,o.[RefStatus] AS [EntityStatus]
	  ,o.[RefCategory] AS [EntityCategory]
	  ,o.[RefType] AS [EntityType]
	  /*#*---------- 📌 DETAIL ----------*#*/
	  ,CONVERT(VARCHAR(MAX), JSON_OBJECT('Lake':  JSON_OBJECT( 
			'ExtA': NULLIF(TRIM(o.[RefCode]), '')
			,'ExtB': NULLIF(TRIM(o.[RefName]), '')
			ABSENT ON NULL
			))) AS [CX_DE]
		,CONVERT(VARCHAR(500), 'https://www.wikipedia.org') AS [DL_DE]
	FROM cteData AS o

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  View [VPL].[MISC_TPL_TRN]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*	
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%MISC%' , 'View';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT  * 
	FROM [VPL].[MISC_TPL_TRN]
	ORDER BY 3,4,5

*/
CREATE VIEW [VPL].[MISC_TPL_TRN]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/
	
	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteData AS (
        SELECT cfg.[BK_SRC_MISC] AS [BK_SRC]
        ,o.[TranNo]
        ,o.[TranLineNo]
        ,o.[RefCode]
        ,o.[RefName]
        ,o.[TranDate]
        ,o.[TUOM]
        ,o.[DUOM]
        ,o.[CurrCode_TRN]
        ,o.[CurrCode_BASE]
        ,o.[CurrCode_CON]
        ,o.[UC_TUOM_TO_DUOM]
        ,o.[Qty_TUOM]
        ,o.[Qty_DUOM]
        ,o.[UnitCost_TRN_TUOM]
        ,o.[UnitPrice_TRN_TUOM]
        ,o.[UnitCost_BASE_DUOM]
        ,o.[UnitPrice_BASE_DUOM]
    FROM [V90_Lake].[MISC].[_TPL_TRN] AS o
    CROSS JOIN [V90_Lake].[AAL].[Setting] AS cfg

	)
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.[BK_SRC]
		,CONCAT_WS('+', o.[BK_SRC], [TranNo], [TranLineNo]) AS [BK_DE]
		,CONCAT_WS('+', o.[BK_SRC], o.[TranNo]) AS [BK_Tran]
		,CONCAT_WS('+', o.[BK_SRC], o.[RefCode]) AS [BK_Entity]
      ,o.[RefCode] AS [EntityCode]
      ,o.[RefName] AS [EntityName]
      ,o.[TranNo]
	  ,o.[TranLineNo]
      ,o.[TranDate]
      ,o.[TUOM]
      ,o.[DUOM]
      ,o.[CurrCode_TRN]
      ,o.[CurrCode_BASE]
      ,o.[CurrCode_CON]
      ,o.[UC_TUOM_TO_DUOM]
      ,o.[Qty_TUOM]
      ,o.[Qty_DUOM]
      ,o.[UnitCost_TRN_TUOM]
      ,o.[UnitPrice_TRN_TUOM]
      ,o.[UnitCost_BASE_DUOM]
      ,o.[UnitPrice_BASE_DUOM]
      /*#*---------- 📌 DETAIL ----------*#*/
	  ,CONVERT(VARCHAR(MAX), JSON_OBJECT('Lake':  JSON_OBJECT( 
			'ExtA': NULLIF(TRIM(o.[RefCode]), '')
			,'ExtB': NULLIF(TRIM(o.[RefName]), '')
			ABSENT ON NULL
			))) AS [CX_DE]
		,CONVERT(VARCHAR(500), 'https://www.wikipedia.org') AS [DL_DE]
  FROM cteData AS o

/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  Table [AAC].[_TPL_Result]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [AAC].[_TPL_Result](
	[zID] [varchar](50) NOT NULL,
	[zUPD] [datetime2](3) NULL,
	[DV_A] [varchar](50) NULL,
	[DV_B] [varchar](50) NULL,
	[DV_C] [varchar](50) NULL,
	[TranDate] [datetime2](0) NULL,
	[Qty_DUOM] [decimal](18, 6) NULL,
	[Value_CON] [decimal](18, 6) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [HUB].[_TPL_REF]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HUB].[_TPL_REF](
	[zID] [varchar](50) NOT NULL,
	[zUPD] [datetime2](3) NULL,
	[BK_SRC] [varchar](20) NULL,
	[BK_DE] [varchar](100) NULL,
	[EntityCode] [varchar](50) NULL,
	[EntityName] [varchar](100) NULL,
	[EntityDesc] [varchar](100) NULL,
	[EntityCategory] [varchar](50) NULL,
	[EntityType] [varchar](50) NULL,
	[EntityStatus] [varchar](50) NULL,
	[EntityNo] [varchar](50) NULL,
	[EntitySeq] [varchar](50) NULL,
	[CX_DE] [varchar](max) NULL,
	[DL_DE] [varchar](500) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [HUB].[_TPL_REF_SNP]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HUB].[_TPL_REF_SNP](
	[zID] [varchar](50) NOT NULL,
	[zUPD] [datetime2](3) NULL,
	[BK_SRC] [varchar](20) NULL,
	[BK_DE] [varchar](100) NULL,
	[BK_DE_OG] [varchar](100) NULL,
	[OF_ASAT] [datetime2](0) NULL,
	[OF_ALL] [smallint] NULL,
	[EntityCode] [varchar](50) NULL,
	[EntityName] [varchar](100) NULL,
	[EntityStatus] [varchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [HUB].[_TPL_TRN]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HUB].[_TPL_TRN](
	[zID] [varchar](50) NOT NULL,
	[zUPD] [datetime2](3) NULL,
	[BK_SRC] [varchar](20) NULL,
	[BK_DE] [varchar](100) NULL,
	[BK_Tran] [varchar](100) NULL,
	[BK_Entity] [varchar](100) NULL,
	[EntityCode] [varchar](50) NULL,
	[EntityName] [varchar](100) NULL,
	[TranNo] [varchar](100) NULL,
	[TranLineNo] [varchar](20) NULL,
	[TranDate] [datetime2](0) NULL,
	[TUOM] [varchar](50) NULL,
	[DUOM] [varchar](50) NULL,
	[CurrCode_TRN] [varchar](50) NULL,
	[CurrCode_BASE] [varchar](50) NULL,
	[CurrCode_CON] [varchar](50) NULL,
	[UC_TUOM_TO_DUOM] [decimal](18, 6) NULL,
	[Qty_TUOM] [decimal](18, 6) NULL,
	[Qty_DUOM] [decimal](18, 6) NULL,
	[UnitCost_TRN_TUOM] [decimal](18, 6) NULL,
	[UnitPrice_TRN_TUOM] [decimal](18, 6) NULL,
	[UnitCost_BASE_DUOM] [decimal](18, 6) NULL,
	[UnitPrice_BASE_DUOM] [decimal](18, 6) NULL,
	[CX_DE] [varchar](max) NULL,
	[DL_DE] [varchar](500) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [PAX].[AGG_0Template]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [PAX].[AGG_0Template](
	[zID] [varchar](50) NOT NULL,
	[zUPD] [datetime2](3) NULL,
	[BK_DE] [varchar](100) NULL,
	[BK_Org] [varchar](50) NULL,
	[BK_Date] [datetime2](0) NULL,
	[BK_Misc] [varchar](200) NULL,
	[BK_Year] [datetime2](0) NULL,
	[BK_Period] [smallint] NULL,
	[Value_Actual] [decimal](18, 4) NULL,
	[Value_Target] [decimal](18, 4) NULL,
	[Value_Actual_YTD] [decimal](18, 4) NULL,
	[Value_Target_YTD] [decimal](18, 4) NULL,
	[CA_Memo] [varchar](500) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [PAX].[KPI_Detail]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [PAX].[KPI_Detail](
	[zID] [varchar](50) NOT NULL,
	[zUPD] [datetime2](3) NULL,
	[BK_DE] [varchar](100) NULL,
	[BK_Org] [varchar](50) NULL,
	[BK_KPI] [varchar](50) NULL,
	[BK_Date] [datetime2](0) NULL,
	[OrgCode] [varchar](50) NULL,
	[OrgName] [varchar](100) NULL,
	[OrgName_OG] [varchar](100) NULL,
	[KPI_CategoryGroup] [varchar](50) NULL,
	[KPI_CategoryCode] [varchar](50) NULL,
	[KPI_CategoryName] [varchar](100) NULL,
	[KPI_CategorySeq] [varchar](10) NULL,
	[KPI_Code] [varchar](50) NULL,
	[KPI_Name] [varchar](100) NULL,
	[KPI_Name_OG] [varchar](100) NULL,
	[KPI_Seq] [varchar](10) NULL,
	[KPI_Description] [varchar](500) NULL,
	[KPI_Format] [varchar](50) NULL,
	[KPI_FormatString] [varchar](50) NULL,
	[KPI_StatusCode_Default] [varchar](50) NULL,
	[KPI_StatusName_Default] [varchar](50) NULL,
	[KPI_TargetType] [varchar](50) NULL,
	[Green_State] [varchar](100) NULL,
	[Amber_State] [varchar](100) NULL,
	[Red_State] [varchar](100) NULL,
	[StartDate] [datetime2](0) NULL,
	[EndDate] [datetime2](0) NULL,
	[KPI_TargetValue] [decimal](18, 6) NULL,
	[KPI_TargetValue_Left] [decimal](18, 6) NULL,
	[KPI_TargetValue_Right] [decimal](18, 6) NULL,
	[CA_StatusCode_Left] [varchar](10) NULL,
	[CA_StatusCode_Middle] [varchar](10) NULL,
	[CA_StatusCode_Right] [varchar](10) NULL,
	[CA_StartDate] [datetime2](0) NULL,
	[CA_EndDate] [datetime2](0) NULL,
	[CA_StatusName] [varchar](50) NULL,
	[CA_StatusCode] [varchar](50) NULL,
	[CA_StatusValue] [decimal](18, 2) NULL,
	[CA_Target_Display] [varchar](100) NULL,
	[CA_Actual_Display] [varchar](100) NULL,
	[CA_Value_Display] [varchar](100) NULL,
	[CA_Memo] [varchar](500) NULL,
	[DrillThroughLink] [varchar](500) NULL,
	[DrillThroughReport] [varchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [AAC].[_TPL_Result_Reload]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%AUT%', 'Proc';
	EXEC [SVC].[FindX] '%TPL_Result%', 'Proc';

    EXEC [AAC].[_TPL_Result_Reload];
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * 
	-- SELECT COUNT(*)
	FROM [AAC].[_TPL_Result] AS o
	WHERE 1=1
	ORDER BY 4,5,6

*/
CREATE PROC [AAC].[_TPL_Result_Reload]
    @Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/    
AS
BEGIN
	SET NOCOUNT ON;    
    /*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_DB NVARCHAR(50), @_Table NVARCHAR(500);
	SET @_DB = DB_NAME();
	SET @_Table = '[AAC].[_TPL_Result]';

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_UPD DATETIME2,@_SCHD DATE,@_SCHD_TIME DATETIME2(0); 
	SELECT TOP 1 @_UPD = o.[CurrentTime]
	,@_SCHD = o.[CurrentTime]
	,@_SCHD_TIME = o.[CurrentTime]		
	FROM [UTL].[Variable] AS o ;

	/*#*---------- ♻️ EMPTY ----------*#*/
	EXEC [UTL].[EmptyTable] @Controller, @_Table;

	/*#*========== 🧩 PREPARE ==========*#*/
	;WITH cteData AS (
		SELECT o.[DV_A]
			,o.[DV_B]
			,o.[DV_C]
			,o.[TranDate]
			,SUM([CA_Qty_DUOM]) AS [Qty_DUOM]
			,SUM([CA_Value_CON]) AS [Value_CON]			
		FROM [AAM].[_TPL_TRN] AS o
		WHERE o.[DV_A] = 'G1'
		AND  o.[DV_B] = 'AU'
		AND  o.[DV_C] = 'DOM'
		GROUP BY o.[DV_A]
		,o.[DV_B]
		,o.[DV_C]
		,o.[TranDate]
	
	)
	
    /*#*========== ✅ ACTION ==========*#*/
	INSERT [AAC].[_TPL_Result] ([zID],[zUPD]
		,[DV_A]
		,[DV_B]
		,[DV_C]
		,[TranDate]
		,[Qty_DUOM]
		,[Value_CON]
	  )
	SELECT NEWID() AS [zID], @_UPD AS [zUPD]
		,o.[DV_A]
		,o.[DV_B]
		,o.[DV_C]
		,o.[TranDate]
		,o.[Qty_DUOM]
		,o.[Value_CON]		
	FROM cteData AS o



    /*#*---------- 🧹 CLEANUP ----------*#*/

	/*#*---------- 📝 LOGGING ----------*#*/	
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[_TPL_Action]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



















/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [AUT].[_TPL_Action];


*/
CREATE PROC [AUT].[_TPL_Action]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Orignal job or schedueler}*_*/    
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	
	/*#*---------- 📄 PARAMETER ----------*#*/
	
	/*#*========== 🧩 PREPARE ==========*#*/

	/*#*========== ✅ ACTION ==========*#*/
	
END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A000_Setup_ALL]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

















/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';
	EXEC [SVC].[FindX] 'AUT%_ALL', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	 EXEC [UTL].[GetLog];
	 -- TRUNCATE TABLE [UTL].[Log]

*/
CREATE PROC [AUT].[A000_Setup_ALL]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*########## 📚 SECTION ##########*#*/
	PRINT '/*#*---------- 🧪 Validations ----------*#*/'	
	PRINT 'EXEC [AUT].[_GetCreationScript]; ';
	PRINT 'EXEC [SVC].[Validate]; ';
	PRINT 'SELECT * FROM [AAC].[_TPL_Result]; ';
	PRINT 'EXEC [AUT].[GetIngestionList]; ';

	/*#*########## 📚 SECTION ##########*#*/
	EXEC [AUT].[IngestionParam_Reload] @_Controller;
	EXEC [AUT].[IngestionPartialQuery_Reload] @_Controller;

		
	/*#*########## 📚 SECTION ##########*#*/
	EXEC [AUT].[AddSampleData] @_Controller;

	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A050_Prepare_ALL]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

















/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [AUT].[A050_Prepare];

*/
CREATE PROC [AUT].[A050_Prepare_ALL]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o;	
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*########## 📚 SECTION ##########*#*/	
	IF NOT EXISTS(	SELECT 1 FROM [UTL].[Calendar])
	BEGIN
		EXEC [UTL].[SeedCalendar];
	END

	EXEC [UTL].[UpdateCalendar] @_Controller;

		
	/*#*########## 📚 SECTION ##########*#*/


	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A200_Load_BGN]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A200_Load_BGN]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/


	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A201_Load_REF]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A201_Load_REF]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/


	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A205_Load_REF]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [AUT].[A205_Load_REF];

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A205_Load_REF]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	EXEC [HUB].[_TPL_REF_Load] @_Controller;
	EXEC [HUB].[_TPL_REF_SNP_Load] @_Controller;

	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A250_Load_MRG]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A250_Load_MRG]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/


	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A251_Load_TRN]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A251_Load_TRN]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/


	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A255_Load_TRN]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A255_Load_TRN]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	EXEC [HUB].[_TPL_TRN_Load] @_Controller;

	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A290_Load_END]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A290_Load_END]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/


	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A300_Refresh_BGN]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A300_Refresh_BGN]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/


	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A301_Refresh_REF]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A301_Refresh_REF]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/


	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A305_Refresh_REF]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A305_Refresh_REF]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	EXEC [MRT].[_TPL_REF_Refresh] @_Controller;
	EXEC [MRT].[_TPL_REF_Refresh_C2] @_Controller;

	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A350_Refresh_MRG]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A350_Refresh_MRG]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/


	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A351_Refresh_TRN]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A351_Refresh_TRN]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/


	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A355_Refresh_TRN]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A355_Refresh_TRN]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	EXEC [MRT].[_TPL_TRN_Refresh] @_Controller;
	EXEC [MRT].[_TPL_TRN_Refresh_C2] @_Controller;

	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A390_Refresh_END]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A390_Refresh_END]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/


	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A400_Update_BGN]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A400_Update_BGN]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/


	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A401_Update_REF]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A401_Update_REF]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/


	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A405_Update_REF]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A405_Update_REF]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	EXEC [MRT].[_TPL_REF_Update] @Controller;
	EXEC [MRT].[_TPL_REF_Update_C2] @Controller;
	

	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A450_Update_MRG]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A450_Update_MRG]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/


	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A451_Update_TRN]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A451_Update_TRN]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/


	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A455_Update_TRN]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A455_Update_TRN]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	EXEC [MRT].[_TPL_TRN_Update] @_Controller;
	EXEC [MRT].[_TPL_TRN_Update_C2] @_Controller;

	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A490_Update_END]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A490_Update_END]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	EXEC [MRT].[_TPL_TRN_Update_END] @_Controller;

	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A600_Reload_AAC]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';
	EXEC [SVC].[FindX] 'PAX%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [AUT].[A600_Reload_AAC];

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A600_Reload_AAC]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@_Controller, @@SPID) AS o ;	
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/

	/*#*########## 📚 SECTION ##########*#*/
	EXEC [AAC].[_TPL_Result_Reload] @_Controller;

	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A650_Reload_PAX]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';
	EXEC [SVC].[FindX] 'PAX%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [AUT].[A600_Reload_PAX];

	 EXEC [UTL].[GetLog];

*/
CREATE PROC [AUT].[A650_Reload_PAX]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@_Controller, @@SPID) AS o ;	
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;


	/*#*########## 📚 SECTION ##########*#*/
	

	/*#*########## 📚 SECTION ##########*#*/
	EXEC [PAX].[KPI_Detail_Reload] @_Controller;
	EXEC [PAX].[AGG_0Template_Reload] @_Controller;
	EXEC [PAX].[KPI_101_Update] @_Controller;

	/*#*########## 📚 SECTION ##########*#*/
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[A999_Finalize_ALL]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

















/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [AUT].[A900_Prepare];

*/
CREATE PROC [AUT].[A999_Finalize_ALL]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*########## 📚 SECTION ##########*#*/

	
	/*#*########## 📚 SECTION ##########*#*/
	EXEC [SVC].[Prune];


	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[AddPipelineLog]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


















/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [AUT].[AddPipelineLog] 'MAIN@0316T0934', '{CRITICAL}MAIN SCHEDULE-A', '{CRITICAL}MAIN SCHEDULE{INITIAL}';
	EXEC [AUT].[AddPipelineLog] 'MAIN@0316T0934', '{CRITICAL}MAIN SCHEDULE-B', '{CRITICAL}MAIN SCHEDULE{BGN}';
	EXEC [AUT].[AddPipelineLog] 'MAIN@0316T0934', '{CRITICAL}MAIN SCHEDULE-B', '{CRITICAL}MAIN SCHEDULE{END}';
	EXEC [AUT].[AddPipelineLog] 'MAIN@0316T0934', '{CRITICAL}MAIN SCHEDULE-A', '{CRITICAL}MAIN SCHEDULE{FINAL}';

	SELECT o.* 
	FROM [UTL].[LogPaired] AS o
	ORDER BY RunTime DESC
	-- TRUNCATE TABLE [UTL].[Log]

	SELECT o.* 
	FROM [UTL].[Log] AS o
	WHERE ID_Paired = 'F12202D4-FECF-4677-B674-DD85ECD160E7'
	ORDER BY RunTime

*/
CREATE PROC [AUT].[AddPipelineLog]
	@Controller varchar(500)/*_*{Parameter},{@Controller},{Orignal job or schedueler}*_*/
    ,@Action varchar(500)/*_*{Parameter},{@Action},{Current process}*_*/	
    ,@Message varchar(500)/*_*{Parameter},{@Message},{The message stored}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message NVARCHAR(500)
	, @_Component NVARCHAR(500), @_Tag NVARCHAR(20);	
	/*#*---------- 📄 PARAMETER ----------*#*/
	SET @_LogID = NEWID();
	SET @_Controller = TRIM(@Controller);
	SET @_Action = TRIM(@Action);
	SET @_Message = @Message;
	SET @_Component = 'Pipeline';	
	SET @_Tag = CASE WHEN CHARINDEX('{INITIAL}', UPPER(@Message)) > 0 THEN '🔽'
										WHEN CHARINDEX('{FINAL}', UPPER(@Message)) > 0 THEN '🔼'
										WHEN CHARINDEX('{BGN}', UPPER(@Message)) > 0 THEN '⬇️'
										WHEN CHARINDEX('{END}', UPPER(@Message)) > 0 THEN '⬆️'
										ELSE '' END;	

	/*#*========== ✅ ACTION ==========*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message, @_LogID, @_LogID, @_Tag, @_Component;

	/*#*========== ✅ ACTION ==========*#*/
	UPDATE o
	SET [ID_Paired] = @_LogID
	FROM [UTL].[Log] AS o
	WHERE o.[Controller] = @_Controller
	AND o.[Action] = @_Action


END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[AddSampleData]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [AUT].[AddSampleData];

	
*/
CREATE PROC [AUT].[AddSampleData]
	@Controller varchar(500) = NULL/*_*{Parameter},{@Controller},{Orignal job or schedueler}*_*/    
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	
	/*#*---------- 📄 PARAMETER ----------*#*/	
	DECLARE @_SQL VARCHAR(8000), @_QN_Lake VARCHAR(50), @_BK_Lake_REF VARCHAR(500), @_BK_Lake_TRN VARCHAR(500)
	, @_QN_Core VARCHAR(50), @_BK_Sample_REF VARCHAR(500), @_BK_Sample_TRN VARCHAR(500);
	SELECT @_QN_Lake = o.[QN_Lake]
	,@_BK_Lake_REF = o.[QN_Lake] + '.[MISC].[_TPL_REF]'
	,@_BK_Lake_TRN = o.[QN_Lake] + '.[MISC].[_TPL_TRN]'
	,@_QN_Core = o.[QN_Core]
	,@_BK_Sample_REF = o.[QN_Core] + '.[SVC].[Sample_Ref]'
	,@_BK_Sample_TRN = o.[QN_Core] + '.[SVC].[Sample_TranDetail]'
	FROM [UTL].[Setting] AS o

	/*#*########## 📚 SECTION: Data ##########*#*/
	IF OBJECT_ID(@_BK_Lake_REF, 'U') IS NOT NULL	AND OBJECT_ID(@_BK_Lake_TRN, 'U') IS NOT NULL
	BEGIN
		SET @_SQL = '	TRUNCATE TABLE #BK_LAKE_REF#; 

	INSERT #BK_LAKE_REF#
	SELECT NEWID() AS zID, ''Sample@'' + FORMAT(GETDATE(), ''yyyyMMddTHHmmss'') AS zSTMPz, o.*  FROM #BK_SAMPLE_REF# AS o ;
 
	TRUNCATE TABLE #BK_LAKE_TRN#;

	INSERT #BK_LAKE_TRN#
	SELECT NEWID() AS zID, ''Sample@'' + FORMAT(GETDATE(), ''yyyyMMddTHHmmss'') AS zSTMPz, o.*  FROM #BK_SAMPLE_TRN# AS o ; 	
		';
		SET @_SQL = REPLACE(REPLACE(REPLACE(REPLACE(@_SQL, '#BK_LAKE_REF#', @_BK_Lake_REF)
		, '#BK_LAKE_TRN#', @_BK_Lake_TRN)
		, '#BK_SAMPLE_REF#', @_BK_Sample_REF)
		, '#BK_SAMPLE_TRN#', @_BK_Sample_TRN)
		
		EXEC (@_SQL);
		
		PRINT '/*#*---------- 🧪 Validations ----------*#*/'
		PRINT 'SELECT * FROM ' + @_BK_Lake_REF;
		PRINT 'SELECT * FROM ' + @_BK_Lake_TRN;
		PRINT '/*---------- 🔼 Template Data Updated in Lake ----------*/'

		

	END
END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[GetCurrentTimezone]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



















/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [AUT].[GetCurrentTimezone];


*/
CREATE PROC [AUT].[GetCurrentTimezone]
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteParam AS (
		SELECT SYSDATETIMEOFFSET() AS [UTC_Time]
		,[MinuteOffsetThreshold] = 30
	 )
	, cteZoneTime AS (
		SELECT o.[BK_DE]
			,o.[ZoneCode]
			,o.[ZoneName]
			,o.[ZoneCategory]
			,o.[ZoneStatus]
			,o.[DaylightSavingStatus]
			,o.[TimeOffset]
			,o.[DatabaseTimezoneName]
			,o.[LocationList]
			,x.[MinuteOffsetThreshold]
			,x.[UTC_Time]
			,[ZoneTime] = CONVERT(DATETIME2(0), x.[UTC_Time] AT TIME ZONE o.[DatabaseTimezoneName])			
		FROM [SVC].[Timezone] AS o
		CROSS JOIN cteParam AS x 
		WHErE o.[ZoneStatus] = 'Active'
	)
	,cteData AS (
		SELECT o.* 
		,CAST ([ZoneTime] AS DATE) AS [ZoneDate]
		,DATEDIFF(MINUTE, CAST ([ZoneTime] AS DATE), [ZoneTime]) AS [MinuteOffset]
		FROM cteZoneTime AS o
	)
	/*#*========== ✅ ACTION ==========*#*/
	SELECT TOP 1 o.[ZoneCode], o.[ZoneName], o.[DatabaseTimezoneName], o.[ZoneTime], o.[MinuteOffset]
	FROM cteData AS o
	WHERE o.[MinuteOffset] <= [MinuteOffsetThreshold]
	OR o.[ZoneCategory] = 'Default'
	ORDER BY [MinuteOffset]

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[GetIngestionList]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO











/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [AUT].[GetIngestionList];

	EXEC [AUT].[GetIngestionList] 'Demo App', 'Main', 'P101';
	EXEC [AUT].[GetIngestionList] 'Demo App', 'Main', 'P105';
	EXEC [AUT].[GetIngestionList] 'Demo App', 'Zoned';
	EXEC [AUT].[GetIngestionList] 'Template', 'Upstream';
	EXEC [AUT].[GetIngestionList] 'Template', 'Downstream';

*/
CREATE PROC [AUT].[GetIngestionList]
	@Source VARCHAR(50) = NULL /*_*{Parameter},{@Source},{Source: App}*_*/
	,@Schedule VARCHAR(50) = NULL /*_*{Parameter},{@Schedule},{Main,Zoned,Downstream,Upstream}*_*/
	,@Process VARCHAR(50) = NULL /*_*{Parameter},{@Process},{Main,Zoned,}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	
	/*#*---------- 📄 PARAMETER ----------*#*/
	DECLARE @_Source VARCHAR(50), @_Schedule VARCHAR(50), @_MutipleProcessFlag SMALLINT, @_Process VARCHAR(50);
	SET @_Source = CASE WHEN ISNULL(@Source,'') = '' THEN '*' ELSE TRIM(@Source) END;
	SET @_Schedule = CASE WHEN ISNULL(@Schedule,'') = '' THEN '*' ELSE TRIM(@Schedule) END;
	SET @_MutipleProcessFlag = CASE WHEN @_Schedule = 'Main' THEN 1 ELSE 0 END;
	SET @_Process = CASE WHEN @_MutipleProcessFlag = 0 THEN '*'
										  WHEN ISNULL(@Process,'') = '' THEN '*'
										ELSE @Process END;

	/*#*========== 🧩 PREPARE ==========*#*/
	SELECT [SourceApp]
		,[ScheduleName]
		,[IngestionSeq]
		,[StepName]
		,[ProcessCode]
		,[QN_LakeTable]
		,[IngestionQuery]
		,[ExtractionQuery]
		,[CreationQuery]
	FROM [AUT].[IngestionList] AS o
	WHERE ([SourceApp] = @_Source OR @_Source = '*')
	AND ([ScheduleName] = @_Schedule OR @_Schedule = '*')
	AND ( [ProcessCode] = @_Process OR @_Process = '*')
	ORDER BY [SourceApp]
		,[ScheduleName]
		,[ProcessCode]
		,[IngestionSeq]

	/*#*========== ✅ OUTPUT ==========*#*/
	
END
/*#*==================== 🔚 ====================*#*/



GO
/****** Object:  StoredProcedure [AUT].[GetSuccessEmail]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [AUT].[GetVariable] 'MAIN', '8aaf91ae-b48d-4c2d-95c0-166e761d98e6', 'V90_ASCH_aMAIN', '240d75a6-ae13-490a-950c-91f9c744a42d';

	DECLARE @Controller VARCHAR(50);
	SET @Controller = 'MAIN@0316T0934'
	EXEC [AUT].[AddPipelineLog] @Controller, '{CRITICAL}Main', '{CRITICAL}Main{PREPARE}';
	WAITFOR DELAY '00:00:02';
	EXEC [AUT].[AddPipelineLog] @Controller, '{CRITICAL}Hub Load', '{CRITICAL}Hub Load{BGN}';
	WAITFOR DELAY '00:00:02';
	EXEC [AUT].[AddPipelineLog] @Controller, '{CRITICAL}Hub Load', '{CRITICAL}Hub Load{END}';
	WAITFOR DELAY '00:00:02';
	EXEC [AUT].[AddPipelineLog] @Controller, '{CRITICAL}Mart Refresh', '{CRITICAL}Mart Refresh{BGN}';
	WAITFOR DELAY '00:00:02';
	EXEC [AUT].[AddPipelineLog] @Controller, '{CRITICAL}Mart Refresh', '{CRITICAL}Mart Refresh{END}';
	WAITFOR DELAY '00:00:02';
	EXEC [AUT].[AddPipelineLog] @Controller, '{CRITICAL}Query Reload', '{CRITICAL}Query Reload{BGN}';
	WAITFOR DELAY '00:00:02';
	EXEC [AUT].[AddPipelineLog] @Controller, '{CRITICAL}Query Reload', '{CRITICAL}Query Reload{END}';
	WAITFOR DELAY '00:00:02';
	EXEC [AUT].[AddPipelineLog] @Controller, '{CRITICAL}Dataset Refresh', '{CRITICAL}Dataset Refresh{BGN}';
	WAITFOR DELAY '00:00:02';
	EXEC [AUT].[AddPipelineLog] @Controller, '{CRITICAL}Dataset Refresh', '{CRITICAL}Dataset Refresh{END}';
	WAITFOR DELAY '00:00:02';
	EXEC [AUT].[AddPipelineLog] @Controller, '{CRITICAL}Main', '{CRITICAL}Main{FINAL}';

	SET @Controller = 'INGEST@0316T0934'
	EXEC [AUT].[AddPipelineLog] @Controller, '{CRITICAL}ERP1', '{CRITICAL}ERP1{BGN}';
	WAITFOR DELAY '00:00:02';
	EXEC [AUT].[AddPipelineLog] @Controller, '{CRITICAL}ERP1', '{CRITICAL}ERP1{END}';
	WAITFOR DELAY '00:00:02';
	EXEC [AUT].[AddPipelineLog] @Controller, '{CRITICAL}CRM1', '{CRITICAL}CRM1{BGN}';
	WAITFOR DELAY '00:00:02';
	EXEC [AUT].[AddPipelineLog] @Controller, '{CRITICAL}CRM1', '{CRITICAL}CRM1{END}';
	

	EXEC [AUT].[GetSuccessEmail] 'MAIN@0316T0934', '8aaf91ae-b48d-4c2d-95c0-166e761d98e6', 'V90_ASCH_aMAIN', '240d75a6-ae13-490a-950c-91f9c744a42d';
	
	SELECT o.* 
	FROM [UTL].[LogPaired] AS o
	ORDER BY RunTime DESC
	-- TRUNCATE TABLE [UTL].[Log]

	SELECT o.* 
	FROM [UTL].[Log] AS o
	WHERE ID_Paired = 'CAA38746-790A-485F-93B8-810C45647766'

*/
CREATE PROC [AUT].[GetSuccessEmail]
	@Controller varchar(500) /*_*{Parameter},{@Controller},{Orignal job or schedueler}*_*/
    ,@WorkspaceId varchar(500) = NULL /*_*{Parameter},{@WorkspaceId},{WorkspaceId:8aaf91ae-b48d-4c2d-95c0-166e761d98e6}*_*/	
	,@PipelineName varchar(500) = NULL /*_*{Parameter},{@PipelineName},{PipelineName:zR2_0SCH}*_*/	
	,@PipelineRunId varchar(500) = NULL /*_*{Parameter},{@PipelineRunId},{PipelineRunId:240d75a6-ae13-490a-950c-91f9c744a42d}*_*/	
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_Time DATETIME2(0),@_Recipient VARCHAR(4000),@_Subject VARCHAR(500), @_EmailContent VARCHAR(8000)
	,@_TB VARCHAR(4000) ,@_TD VARCHAR(500), @_Main VARCHAR(8000), @_Ingest VARCHAR(8000);

	/*#*---------- 📄 PARAMETER ----------*#*/
	SELECT @_Subject = o.[System] + '*' + @Controller 
		,@_Recipient = o.[AdminEmail]
		,@_Time = o.[CurrentTime]
		,@_EmailContent = REPLACE(REPLACE(REPLACE(o.[EmailBodyTemplate], '#WORKSPACE_ID#', @WorkspaceId)
										, '#PIPELINE_NAME#', @PipelineName)
										, '#PIPELINE_RUN_ID#', @PipelineRunId)
	FROM [UTL].[Setting] AS o	

	/*#*---------- 📄 PARAMETER ----------*#*/
	SET @_TD = '<div class="rw #CLASS#"><div class="col col1">#ACTION#</div><div class="col">#TIME#</div><div class="col">#DURATION#</div></div>' ;
	SET @_TB = '<div class="tb"><div class="rw"><div class="col col1 hd">🗓️ Schedule (#DATE#)</div><div class="col hd">Time</div><div class="col hd">Mins</div></div>
#MAIN#
</div><br/><div class="tb">
<div class="col col1 hd">🌐 Ingestion (Past 12 hours)</div>
#INGEST#
</div><!--etb-->';

	/*#*---------- 📄 PARAMETER ----------*#*/
	;WITH cteMain AS (
		SELECT o.[Action_NoTag] AS [Action]
			,[Time] = FORMAT(o.[RunTime], 'HH:mm:ss')
			,[Duration] = FORMAT(o.[DurationSeconds]  * 60 /60.0, 'N0')
			,[Seq] = ROW_NUMBER() OVER (ORDER BY [StartTime])
		FROM [UTL].[LogPaired] AS o
		WHERE [Priority] = 'Critical' 
		AND o.[Controller] = @Controller
	)
	SELECT @_Main = STRING_AGG(REPLACE(REPLACE(REPLACE(REPLACE(@_TD, '#ACTION#', o.[Action])
	, '#TIME#', o.[Time])
	, '#DURATION#', o.[Duration])
	, '#CLASS#', CASE WHEN [Seq]%2 = 0 THEN 'rw2' ELSE '' END), '')
		WITHIN GROUP ( ORDER BY [Seq])
	FROM cteMain AS o

	/*#*---------- 📄 PARAMETER ----------*#*/
	;WITH cteIngest AS (
		SELECT o.[Action_NoTag] AS [Action]
			,[Time] = FORMAT(o.[RunTime], 'HH:mm:ss')
			,[Duration] = FORMAT(o.[DurationSeconds]  * 60 /60.0, 'N0')
			,[Seq] = ROW_NUMBER() OVER (ORDER BY [StartTime])
		FROM [UTL].[LogPaired] AS o
		WHERE [Priority] = 'Critical' 
		AND o.[Controller] LIKE 'INGEST%'
		AND o.[RunTime] > DATEADD(HOUR, -12, @_Time)
	)
	SELECT @_Ingest = STRING_AGG(REPLACE(REPLACE(REPLACE(REPLACE(@_TD, '#ACTION#', o.[Action])
	, '#TIME#', o.[Time])
	, '#DURATION#', o.[Duration])
	, '#CLASS#', CASE WHEN [Seq]%2 = 0 THEN 'rw2' ELSE '' END), '')
		WITHIN GROUP ( ORDER BY [Seq])
	FROM cteIngest AS o


	/*#*========== ✅ Action ==========*#*/
	SET @_TB = REPLACE(REPLACE(@_TB, '#MAIN#', ISNULL(@_Main,''))
	, '#INGEST#', ISNULL(@_Ingest, ''));
	SET @_EmailContent = REPLACE(@_EmailContent, '.more{}'
	, '.tb{width:500px;border-collapse:collapse}.rw{display:flex;border:1px solid #e3e7e8}.rw2{background-color:#e3e7e8}.col{font-size:18px;flex:1;padding:5px;text-align:center;border:1px solid #e3e7e8;color:#003380}.col1{flex:0 0 45%;text-align:left;color:#003380}.hd{background:#e3e7e8;font-size:16px;color:#000}'
	);	
	SET @_EmailContent = REPLACE(@_EmailContent, '#CONTENT#', @_TB);
	SET @_EmailContent = REPLACE(@_EmailContent, '#DATE#', FORMAT(@_Time, 'ddd, dd MMM'));

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT @_Recipient AS [AdminEmail]
	  ,@_Subject AS [SuccessEmailSubject]
	  ,@_EmailContent AS [SuccessEmailContent]

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[GetVariable]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [AUT].[GetVariable] 'MAIN', '8aaf91ae-b48d-4c2d-95c0-166e761d98e6', 'V90_ASCH_aMAIN', '240d75a6-ae13-490a-950c-91f9c744a42d';


*/
CREATE PROC [AUT].[GetVariable]
	@Controller varchar(500) /*_*{Parameter},{@Controller},{Orignal job or schedueler}*_*/
    ,@WorkspaceId varchar(500) = NULL /*_*{Parameter},{@WorkspaceId},{WorkspaceId:8aaf91ae-b48d-4c2d-95c0-166e761d98e6}*_*/	
	,@PipelineName varchar(500) = NULL /*_*{Parameter},{@PipelineName},{PipelineName:zR2_0SCH}*_*/	
	,@PipelineRunId varchar(500) = NULL /*_*{Parameter},{@PipelineRunId},{PipelineRunId:240d75a6-ae13-490a-950c-91f9c744a42d}*_*/	
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_System VARCHAR(500), @_Time_UTC DATETIME2(3), @_Time DATETIME2(3),@_Date DATE, @_DateTimeStr VARCHAR(50), @_DateTimeStrForFile VARCHAR(50), @_TimeStr VARCHAR(50),@_DateStr  VARCHAR(50),@_Timezone  VARCHAR(100)
	, @_Controller VARCHAR(500), @_Controller_Thread VARCHAR(500), @_ControllerPostfix VARCHAR(50)
	, @_AdminEmail VARCHAR(500),@_FailureEmailSubject VARCHAR(500),@_FailureEmailContent VARCHAR(8000)
	,@_EmailContent VARCHAR(4000)

	/*#*---------- 📄 PARAMETER ----------*#*/
	SELECT @_System = o.[System]		
		,@_AdminEmail = o.[AdminEmail]
		,@_Time = o.[CurrentTime]
		,@_Date = o.[CurrentTime]
		,@_DateStr = FORMAT(o.[CurrentTime], 'yyyyMMdd')
		,@_TimeStr = FORMAT(o.[CurrentTime], 'HHmmss')
		,@_DateTimeStr = FORMAT(o.[CurrentTime], o.[TimeStampFormat])
		,@_DateTimeStrForFile = '_' + FORMAT(o.[CurrentTime], o.[TimeStampFormat])
		,@_ControllerPostfix = FORMAT(@_Time, 'MMddTHHmm')
		/*#*---------- 📌 DETAIL ----------*#*/
		,@_EmailContent = REPLACE(REPLACE(REPLACE(o.[EmailBodyTemplate], '#WORKSPACE_ID#', @WorkspaceId)
										, '#PIPELINE_NAME#', @PipelineName)
										, '#PIPELINE_RUN_ID#', @PipelineRunId)
	FROM [UTL].[Setting] AS o	

	
	/*#*---------- 📄 PARAMETER ----------*#*/
	SET @_Controller = CASE WHEN CHARINDEX('@', @Controller) > 0 THEN TRIM(@Controller)
									ELSE ISNULL(TRIM(@Controller), 'Ad-hoc')  + '@' + @_ControllerPostfix END;
	SET @_Controller_Thread = @_Controller + '*[P#N#]';

	/*#*---------- 📄 PARAMETER ----------*#*/
	SELECT TOP 1 @_Timezone = o.[DatabaseTimezoneName]
	FROM [SVC].[Timezone] AS o
	WHERE o.[ZoneCategory] = 'Default';


	/*#*---------- 📄 PARAMETER ----------*#*/
	SET @_FailureEmailSubject = '{Failed} ' + @_System+ @_Controller + ''  ;	
	SET @_FailureEmailContent = REPLACE(@_EmailContent,'#CONTENT#', '<div class="failed">' + @_FailureEmailSubject + '</div>');

	/*#*========== 🧩 PREPARE ==========*#*/

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT @_Controller AS [Controller]
	,@_DateTimeStr AS [DateTimeStr]
	,@_TimeStr AS [TimeStr]
	,@_DateStr AS [DateStr]
	,@_Timezone AS [TimeZone]
	,@_Date AS [DateValue]
	,@_Time AS [DateTimeValue]
	,@_DateTimeStrForFile AS [DateTimeStrForFile]

	/*#*---------- Email--------------------*#*/
	,@_AdminEmail AS [SupportEmail]	
	,@_FailureEmailSubject AS [FailureEmailSubject]
	,@_FailureEmailContent AS [FailureEmailContent]
	
	/*#*----------Zoned--------------------*#*/

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[IngestionParam_Reload]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





/*
    /*#*---------- 🔍 EXAMPLE ----------*#*/
	EXEC [SVC].[FindX] '%CFG%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [AUT].[IngestionParam_Reload];
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * 
	FROM [AUT].[IngestionParam] AS o
	ORDER BY 5,4

	DECLARE @a VARCHAR(50) = FORMAT(DATEADD(MONTH, -2, GETDATE()), 'yyyy-MM-dd')
	, @d VARCHAR(50) = FORMAT(DATEADD(DAY, -1, GETDATE()), 'yyyy-MM-dd')
	UPDATE [AUT].[IngestionParam] 
	SET OF_ASAT = @a, BK_DE = REPLACE(BK_DE, @d, @a)
	WHERE OF_ASAT = @d;
	
	-- TRUNCATE TABLE [AUT].[IngestionParam];

*/
CREATE PROC [AUT].[IngestionParam_Reload]
    @Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/    
AS
BEGIN
	SET NOCOUNT ON;    
    /*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_DB NVARCHAR(50), @_Table NVARCHAR(500), @_Condition NVARCHAR(500);
	SET @_DB = DB_NAME();
	SET @_Table = '[AUT].[IngestionParam]';

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_UPD DATETIME2,@_SCHD DATE,@_SCHD_TIME DATETIME2(0);
	SELECT TOP 1 @_UPD = o.[CurrentTime]
	,@_SCHD = o.[CurrentTime]
	,@_SCHD_TIME = o.[CurrentTime]
	FROM [UTL].[Variable] AS o;

	/*#*########## 📚 SECTION ##########*#*/
	DECLARE @_ASAT DATETIME2(0), @_Frequency VARCHAR(20);
	SET @_ASAT = DATEADD(DAY, -1,@_SCHD);
	SET @_Frequency = 'Day';	
	EXEC [UTL].[SnapshotBegin] @Controller, @_Table, @_ASAT, @SnapshotLimit = 12;

    /*#*========== ✅ ACTION ==========*#*/
	INSERT [AUT].[IngestionParam] ([zID],[zUPD]
		  ,[OF_ASAT]
		  ,[BK_DE]
		  ,[BK_DE_OG]
		  ,[ScheduleName]
		  ,[IngestionSeq]
		  ,[StepName]
		  ,[StepSeq]
		  ,[ProcessCode]
		  ,[LakeSchemaName]
		  ,[LakeTableName]
		  ,[QN_LakeTable]
		  ,[QN_LakeTable_Group]
		  ,[SourceApp]
		  ,[QN_SourceTable]
		  ,[ScheduleList]
		  ,[Pattern]
	  )
	SELECT NEWID() AS [zID], @_UPD AS [zUPD]
		,@_ASAT AS [OF_ASAT]
		,o.[BK_DE] + '@' + FORMAT(@_ASAT, 'yyyy-MM-dd') AS [BK_DE]
		,o.[BK_DE] AS [BK_DE_OG]
		,o.[ScheduleName]
		,o.[IngestionSeq]
		,o.[StepName]
		,o.[StepSeq]
		,o.[ProcessCode]
		,o.[LakeSchemaName]
		,o.[LakeTableName]
		,o.[QN_LakeTable]
		,o.[QN_LakeTable_Group]
		,o.[SourceApp]
		,o.[QN_SourceTable]
		,o.[ScheduleList]
		,o.[Pattern]
	FROM [VPL].[AUT_IngestionParam] AS o


    /*#*---------- 🧹 CLEANUP ----------*#*/
	EXEC [UTL].[RemoveDuplication] @Controller, @_Table;

	/*#*########## 📚 SECTION ##########*#*/
	EXEC [UTL].[SnapshotEnd] @Controller, @_Table, @_Frequency;


	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;
END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [AUT].[IngestionPartialQuery_Reload]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO











/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/
	EXEC [SVC].[FindX] '%CFG%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [AUT].[IngestionPartialQuery_Reload];
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * 
	FROM [AUT].[IngestionPartialQuery] AS o
	ORDER BY 3,4

*/
CREATE PROC [AUT].[IngestionPartialQuery_Reload]
    @Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/    
AS
BEGIN
	SET NOCOUNT ON;
    /*#*========== 🎯 PURPOSE ==========*#*/    
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*---------- 📄 PARAMETER ----------*#*/
	DECLARE @_Table VARCHAR(50),  @_BK_Category VARCHAR(50);	
	SET @_BK_Category = 'Query';

	/*#*---------- ♻️ EMPTY ----------*#*/
    SET @_Table = '[AUT].[IngestionPartialQuery]';
    EXEC [UTL].[EmptyTable] @Controller, @_Table;

	/*#*========== 🧩 PREPARE ==========*#*/
	CREATE TABLE #Query ([BK_DE] VARCHAR(50), [IngestionQuery_FULL] VARCHAR(MAX),[IngestionQuery_PARTIAL]  VARCHAR(MAX), [ExtractionQuery] VARCHAR(MAX));

	DECLARE curDB CURSOR LOCAL FAST_FORWARD FOR
	WITH cteTable AS (
		SELECT o.[DatabaseName], o.[BK_DE] AS [BK_Table]
		, REPLACE('SELECT NEWID() AS zID, GETDATE() AS zUPD
      ,[SchemaName]
      ,[TableName]
      ,[QN_Table_FULL]
      ,[QN_Table_PARTIAL]
      ,[QN_Table_OVERLAP]
      ,[QN_SourceTable]
      ,[ValidationQuery]
      ,[IngestionQuery_FULL]
      ,[IngestionQuery_PARTIAL]
      ,[ExtractionQuery]
FROM #TABLE# 
', '#TABLE#', o.[BK_DE] ) AS PARTIAL_QUERY
		FROM [SVC].[Meta_Table] AS o
		WHERE o.[TablePattern] = 'PARTIAL_QUERY'
	)
	/*#*========== ✅ OUTPUT ==========*#*/
    SELECT o.[DatabaseName], o.[BK_Table], o.[PARTIAL_QUERY]
    FROM cteTable AS o;

	/*#*========== ✅ ACTION ==========*#*/
	DECLARE @_DB VARCHAR(50), @_DB_Qualified VARCHAR(50), @_TableName_Qualified VARCHAR(200), @_Query VARCHAR(MAX);
	OPEN curDB;
	FETCH NEXT FROM curDB INTO @_DB, @_TableName_Qualified, @_Query

	WHILE @@FETCH_STATUS = 0
    BEGIN
			SET @_DB_Qualified = QUOTENAME(@_DB);			
			/*#*---------- 📌 DETAIL ----------*#*/
			INSERT [AUT].[IngestionPartialQuery]( [zID], [zUPD]
				,[SchemaName]
				,[TableName]
				,[QN_Table_FULL]
				,[QN_Table_PARTIAL]
				,[QN_Table_OVERLAP]
				,[QN_SourceTable]
				,[ValidationQuery]
				,[IngestionQuery_FULL]
				,[IngestionQuery_PARTIAL]
				,[ExtractionQuery])
			EXEC (@_Query);

			/*#*---------- 📌 DETAIL ----------*#*/
            FETCH NEXT FROM curDB INTO @_DB, @_TableName_Qualified, @_Query
    END

	/*#*========== ✅ ACTION ==========*#*/
	UPDATE o
	SET [BK_DE] = QUOTENAME([SchemaName]) + '.' + QUOTENAME([TableName])
	, [QN_TableGroup] = QUOTENAME([SchemaName]) + '.' + QUOTENAME([TableName])
	FROM [AUT].[IngestionPartialQuery] AS o

	/*#*---------- 🧹 CLEANUP ----------*#*/
    CLOSE curDB;
    DEALLOCATE curDB;	

	/*#*---------- 🧹 CLEANUP ----------*#*/
	EXEC [UTL].[RemoveDuplication] @Controller, @_Table;

	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [HUB].[_TPL_REF_Load]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%TPL%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/
    EXEC [HUB].[_TPL_REF_Load];
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * 
	-- SELECT COUNT(*)
	FROM [HUB].[_TPL_REF] AS o
	WHERE 1=1
	ORDER BY 4,5,6

*/
CREATE PROC [HUB].[_TPL_REF_Load]
    @Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/    
AS
BEGIN
	SET NOCOUNT ON;    
    /*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_DB NVARCHAR(50), @_Table NVARCHAR(500);
	SET @_DB = DB_NAME();
	SET @_Table = '[HUB].[_TPL_REF]';

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_UPD DATETIME2,@_SCHD DATE,@_SCHD_TIME DATETIME2(0); 
	SELECT TOP 1 @_UPD = o.[CurrentTime]
	,@_SCHD = o.[CurrentTime]
	,@_SCHD_TIME = o.[CurrentTime]		
	FROM [UTL].[Variable] AS o ;

	/*#*---------- ♻️ EMPTY ----------*#*/
	EXEC [UTL].[EmptyTable] @Controller, @_Table;

	/*#*========== 🧩 PREPARE ==========*#*/

    /*#*========== ✅ ACTION ==========*#*/
	INSERT [HUB].[_TPL_REF] ([zID],[zUPD]
		,[BK_SRC]
		,[BK_DE]
		,[EntityCode]
		,[EntityName]
		,[EntityDesc]
		,[EntityCategory]
		,[EntityType]
		,[EntityStatus]
		,[EntityNo]
		,[EntitySeq]
		,[CX_DE]
		,[DL_DE]
	  )
	SELECT NEWID() AS [zID], @_UPD AS [zUPD]
		,o.[BK_SRC]
		,o.[BK_DE]
		,o.[EntityCode]
		,o.[EntityName]
		,o.[EntityDesc]
		,o.[EntityCategory]
		,o.[EntityType]
		,o.[EntityStatus]
		,o.[EntityNo]
		,o.[EntitySeq]
		,o.[CX_DE]
		,o.[DL_DE]
	FROM [VPL].[MISC_TPL_REF] AS o
	WHERE 1=1 ;


    /*#*---------- 🧹 CLEANUP ----------*#*/
	EXEC [UTL].[RemoveDuplication] @Controller, @_Table;


	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [HUB].[_TPL_REF_SNP_Load]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%TPL%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/
    EXEC [HUB].[_TPL_REF_SNP_Load];
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * 
	-- SELECT COUNT(*)
	FROM [HUB].[_TPL_REF_SNP] AS o
	WHERE 1=1
	ORDER BY 4,5,6

	-- TRUNCATE TABLE [HUB].[_TPL_REF_SNP]

*/
CREATE PROC [HUB].[_TPL_REF_SNP_Load]
    @Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/    
AS
BEGIN
	SET NOCOUNT ON;    
    /*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_DB NVARCHAR(50), @_Table NVARCHAR(500);
	SET @_DB = DB_NAME();
	SET @_Table = '[HUB].[_TPL_REF_SNP]';

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_UPD DATETIME2,@_SCHD DATE,@_SCHD_TIME DATETIME2(0); 
	SELECT TOP 1 @_UPD = o.[CurrentTime]
	,@_SCHD = o.[CurrentTime]
	,@_SCHD_TIME = o.[CurrentTime]		
	FROM [UTL].[Variable] AS o ;

	/*#*---------- ♻️ EMPTY ----------*#*/	
	
	/*#*########## 📚 SECTION ##########*#*/
	DECLARE @_ASAT DATETIME2(0), @_Frequency VARCHAR(20);
	SET @_ASAT = DATEADD(DAY, -1,@_SCHD);
	SET @_Frequency = 'Month';
	EXEC [UTL].[SnapshotBegin] @_Controller, @_Table, @_ASAT, @SnapshotLimit = 3, @ExpiredSnapshotLimit = 1;

    /*#*========== ✅ ACTION ==========*#*/
	INSERT [HUB].[_TPL_REF_SNP] ([zID],[zUPD]
		,[BK_SRC]
		,[BK_DE]
		,[BK_DE_OG]		
		,[OF_ASAT]
		,[EntityCode]
		,[EntityName]
		,[EntityStatus]
	  )
	SELECT NEWID() AS [zID], @_UPD AS [zUPD]
		,o.[BK_SRC]
		,o.[BK_DE] + '@' + FORMAT(@_ASAT, 'yyyy-MM-dd') AS [BK_DE]
		,o.[BK_DE] AS [BK_DE_OG]		
		,[OF_ASAT] = @_ASAT 
		,o.[EntityCode]
		,o.[EntityName]
		,o.[EntityStatus]
	FROM [HUB].[_TPL_REF] AS o
	

    /*#*---------- 🧹 CLEANUP ----------*#*/
	EXEC [UTL].[RemoveDuplication] @Controller, @_Table;
	
	/*#*########## 📚 SECTION ##########*#*/
	EXEC [UTL].[SnapshotEnd] @_Controller, @_Table, @_Frequency;

	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [HUB].[_TPL_TRN_Load]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%TPL%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/
    EXEC [HUB].[_TPL_TRN_Load];
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * 
	-- SELECT COUNT(*)
	FROM [HUB].[_TPL_TRN] AS o
	WHERE 1=1
	ORDER BY 4,5,6

*/
CREATE PROC [HUB].[_TPL_TRN_Load]
    @Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/    
AS
BEGIN
	SET NOCOUNT ON;    
    /*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_DB NVARCHAR(50), @_Table NVARCHAR(500);
	SET @_DB = DB_NAME();
	SET @_Table = '[HUB].[_TPL_TRN]';

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_UPD DATETIME2,@_SCHD DATE,@_SCHD_TIME DATETIME2(0); 
	SELECT TOP 1 @_UPD = o.[CurrentTime]
	,@_SCHD = o.[CurrentTime]
	,@_SCHD_TIME = o.[CurrentTime]		
	FROM [UTL].[Variable] AS o ;

	/*#*---------- ♻️ EMPTY ----------*#*/
	EXEC [UTL].[EmptyTable] @Controller, @_Table;

	/*#*========== 🧩 PREPARE ==========*#*/

    /*#*========== ✅ ACTION ==========*#*/
	INSERT [HUB].[_TPL_TRN] ([zID],[zUPD]
		,[BK_SRC]
		,[BK_DE]
		,[BK_Tran]
		,[BK_Entity]
		,[EntityCode]
		,[EntityName]
		,[TranNo]
		,[TranLineNo]
		,[TranDate]
		,[TUOM]
		,[DUOM]
		,[CurrCode_TRN]
		,[CurrCode_BASE]
		,[CurrCode_CON]
		,[UC_TUOM_TO_DUOM]
		,[Qty_TUOM]
		,[Qty_DUOM]
		,[UnitCost_TRN_TUOM]
		,[UnitPrice_TRN_TUOM]
		,[UnitCost_BASE_DUOM]
		,[UnitPrice_BASE_DUOM]
		,[CX_DE]
		,[DL_DE]
	  )
	SELECT NEWID() AS [zID], @_UPD AS [zUPD]
		,o.[BK_SRC]
		,o.[BK_DE]
		,o.[BK_Tran]
		,o.[BK_Entity]
		,o.[EntityCode]
		,o.[EntityName]
		,o.[TranNo]
		,o.[TranLineNo]
		,o.[TranDate]
		,o.[TUOM]
		,o.[DUOM]
		,o.[CurrCode_TRN]
		,o.[CurrCode_BASE]
		,o.[CurrCode_CON]
		,o.[UC_TUOM_TO_DUOM]
		,o.[Qty_TUOM]
		,o.[Qty_DUOM]
		,o.[UnitCost_TRN_TUOM]
		,o.[UnitPrice_TRN_TUOM]
		,o.[UnitCost_BASE_DUOM]
		,o.[UnitPrice_BASE_DUOM]
		,o.[CX_DE]
		,o.[DL_DE]
	FROM [VPL].[MISC_TPL_TRN] AS o
	WHERE 1=1 ;


    /*#*---------- 🧹 CLEANUP ----------*#*/
	EXEC [UTL].[RemoveDuplication] @Controller, @_Table;

	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [MRT].[_TPL_REF_Refresh]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





















/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%TPL_REF%', 'Proc';

    EXEC [MRT].[_TPL_REF_Refresh];
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * 
	-- SELECT COUNT(*)
	FROM [MRT].[_TPL_REF] AS o
	WHERE 1=1
	ORDER BY 4,5,6

*/
CREATE PROC [MRT].[_TPL_REF_Refresh]
    @Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/    
AS
BEGIN
	SET NOCOUNT ON;    
    /*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_DB NVARCHAR(50), @_Table NVARCHAR(500);
	SET @_DB = DB_NAME();
	SET @_Table = '[MRT].[_TPL_REF]';

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_UPD DATETIME2,@_SCHD DATE,@_SCHD_TIME DATETIME2(0); 
	SELECT TOP 1 @_UPD = o.[CurrentTime]
	,@_SCHD = o.[CurrentTime]
	,@_SCHD_TIME = o.[CurrentTime]		
	FROM [UTL].[Variable] AS o ;

	/*#*---------- ♻️ EMPTY ----------*#*/
	EXEC [UTL].[EmptyTable] @Controller, @_Table;

	
    /*#*========== ✅ ACTION ==========*#*/
	INSERT [MRT].[_TPL_REF] ([zID],[zUPD]
		,[BK_SRC]
		,[BK_DE]
		,[BK_DE_OG]
		,[DV_A]
		,[DV_B]
		,[DV_C]
		,[EntityCode]
		,[EntityName]
		,[EntityDesc]
		,[EntityCategory]
		,[EntityType]
		,[EntityStatus]
		,[EntityNo]
		,[EntitySeq]
		,[CX_DE]
		,[DL_DE]
	  )
	SELECT NEWID() AS [zID], @_UPD AS [zUPD]
		,o.[BK_SRC]
		,o.[BK_DE]
		,o.[BK_DE] AS [BK_DE_OG]
		/*#*---------- 📌 DETAIL ----------*#*/ -- SELECT TOP 10 *
		,'G1' AS [DV_A], 'AU' AS [DV_B], 'DOM' AS [DV_C]
		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[EntityCode]
		,o.[EntityName]
		,o.[EntityDesc]
		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[EntityCategory]
		,o.[EntityType]
		,o.[EntityStatus]
		,o.[EntityNo]
		,o.[EntitySeq]
		,o.[CX_DE]
		,o.[DL_DE]
	FROM [HUB].[_TPL_REF] AS o
	WHERE 1=1 ;


    /*#*---------- 🧹 CLEANUP ----------*#*/
	EXEC [UTL].[RemoveDuplication] @Controller, @_Table;

	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [MRT].[_TPL_REF_Refresh_C2]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





















/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%TPL_REF%', 'Proc';

    EXEC [MRT].[_TPL_REF_Refresh];
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * 
	-- SELECT COUNT(*)
	FROM [MRT].[_TPL_REF] AS o
	WHERE 1=1
	ORDER BY 4,5,6

*/
CREATE PROC [MRT].[_TPL_REF_Refresh_C2]
    @Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/    
AS
BEGIN
	SET NOCOUNT ON;    
    /*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_DB NVARCHAR(50), @_Table NVARCHAR(500);
	SET @_DB = DB_NAME();
	SET @_Table = '[MRT].[_TPL_REF]';

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_UPD DATETIME2,@_SCHD DATE,@_SCHD_TIME DATETIME2(0); 
	SELECT TOP 1 @_UPD = o.[CurrentTime]
	,@_SCHD = o.[CurrentTime]
	,@_SCHD_TIME = o.[CurrentTime]		
	FROM [UTL].[Variable] AS o ;

	/*#*########## 📚 SECTION: Placeholder ##########*#*/
	EXEC [UTL].[AddPlaceholder] @Controller, @_Table,'[UN-TPL]', '[UN]';


    /*#*---------- 🧹 CLEANUP ----------*#*/
	

	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [MRT].[_TPL_REF_Update]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





















/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%TPL_REF%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [V90_Core].[HUB].[_TPL_REF_Load] 'Ad-hoc'; 
	EXEC [V90_Core].[MRT].[_TPL_REF_Refresh] 'Ad-hoc'; 
	EXEC [V90_Core].[MRT].[_TPL_REF_Refresh_C2] 'Ad-hoc'; 
	EXEC [V90_Core].[MRT].[_TPL_REF_Update] 'Ad-hoc'; 
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * 
	-- SELECT COUNT(*)
	FROM [MRT].[_TPL_REF] AS o
	WHERE 1=1
	ORDER BY 4,5,6

*/
CREATE PROC [MRT].[_TPL_REF_Update]
    @Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/    
AS
BEGIN
	SET NOCOUNT ON;    
    /*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;	
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_DB NVARCHAR(50), @_Table NVARCHAR(500);
	SET @_DB = DB_NAME();
	SET @_Table = '[MRT].[_TPL_REF]';

	/*#*========== 🧩 PREPARE ==========*#*/
	;WITH cteBase AS (
		SELECT o.[zID]
		  ,[CA_zStatus] = CASE WHEN o.[EntityStatus] ='Active' THEN 'Valid' ELSE 'Invalid' END
		  ,[CA_zLock] = CONCAT_WS('/', o.[DV_A], o.[DV_B], o.[DV_C]) 
		  ,[CA_zMemo] = CONCAT_WS(';', o.[CA_zMemo], 'Update')
		FROM [MRT].[_TPL_REF] AS o
	)
	/*#*---------- 📌 DETAIL ----------*#*/
	,cteExtA AS (
		SELECT o.[zID]
		,[CA_Flag] = 1
		FROM [MRT].[_TPL_REF] AS o
	)
	/*#*---------- 📌 DETAIL ----------*#*/
	,cteStage10 AS (
		SELECT o.[zID]		  
		FROM [MRT].[_TPL_REF] AS o
	)
	/*#*---------- 📌 DETAIL ----------*#*/
	,cteStage20 AS (
		SELECT o.* 
		FROM cteStage10 AS o
	)

	/*#*========== ✅ ACTION ==========*#*/	
	UPDATE [MRT].[_TPL_REF]
	SET [CA_zStatus] = x.[CA_zStatus]
		,[CA_zLock] = x.[CA_zLock]
		,[CA_zMemo] = x.[CA_zMemo]
		/*#*---------- 📌 DETAIL ----------*#*/
		,[CA_zFlag] = extA.[CA_Flag]
		/*#*---------- 📌 DETAIL ----------*#*/

    FROM [MRT].[_TPL_REF] AS o
	LEFT JOIN cteBase AS x ON x.[zID] = o.[zID]
	LEFT JOIN cteExtA AS extA ON extA.[zID] = o.[zID]
	LEFT JOIN cteStage20 AS stg ON stg.[zID] = o.[zID]
	WHERE o.[BK_SRC] <> 'PLH'

	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [MRT].[_TPL_REF_Update_C2]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






















/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/
	EXEC [SVC].[FindX] '%TPL_REF%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [MRT].[_TPL_REF_Refresh]; 
	EXEC [MRT].[_TPL_REF_Refresh_C2]; 
	EXEC [MRT].[_TPL_REF_Update]; 
	EXEC [MRT].[_TPL_REF_Update_C2]; 
	EXEC [MRT].[_TPL_REF_Update_END]; 
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 100 * 
	-- SELECT COUNT(*) 
	FROM [MRT].[_TPL_REF]
	ORDER BY 4,5,6
	
*/
CREATE PROC [MRT].[_TPL_REF_Update_C2]
	@Controller varchar(500) = 'Ad-hoc' /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@_Controller, @@SPID) AS o ;	
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_UPD DATETIME2,@_SCHD DATE,@_SCHD_TIME DATETIME2(0),@_TABLE VARCHAR(500);
	SELECT TOP 1 @_UPD = o.[CurrentTime]
	,@_SCHD = o.[CurrentTime]
	,@_SCHD_TIME = o.[CurrentTime]
	FROM [UTL].[Variable] AS o;

	SET @_TABLE = '[MRT].[_TPL_REF]';

	/*#*========== 🧩 PREPARE ==========*#*/
	;WITH cteBase AS (
		SELECT o.[zID]
		  ,[CA_zMemo] = CONCAT_WS(';', o.[CA_zMemo], 'Update_C2')
		FROM [MRT].[_TPL_REF] AS o
	)
	/*#*---------- 📌 DETAIL ----------*#*/
	,cteExtA AS (
		SELECT o.[zID]		
		FROM [MRT].[_TPL_REF] AS o
	)
	/*#*---------- 📌 DETAIL ----------*#*/
	,cteStage10 AS (
		SELECT o.[zID]		
		FROM [MRT].[_TPL_REF] AS o
	)
	/*#*---------- 📌 DETAIL ----------*#*/
	,cteStage20 AS (
		SELECT o.*		  
		FROM cteStage10 AS o
	)
	

	/*#*========== ✅ ACTION ==========*#*/	
	UPDATE o
	SET [CA_zMemo] = x.[CA_zMemo]
		/*#*---------- 📌 DETAIL ----------*#*/		
		/*#*---------- 📌 DETAIL ----------*#*/
		
    FROM [MRT].[_TPL_REF] AS o
	LEFT JOIN cteBase AS x ON x.[zID] = o.[zID]
	LEFT JOIN cteExtA AS extA ON extA.[zID] = o.[zID]
	LEFT JOIN cteStage20 AS stg ON stg.[zID] = o.[zID]
  

	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [MRT].[_TPL_TRN_Refresh]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






















/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%TPL_TRN%', 'Proc';

    EXEC [MRT].[_TPL_TRN_Refresh];
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * 
	-- SELECT COUNT(*)
	FROM [MRT].[_TPL_TRN] AS o
	WHERE 1=1
	ORDER BY 4,5,6

*/
CREATE PROC [MRT].[_TPL_TRN_Refresh]
    @Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/    
AS
BEGIN
	SET NOCOUNT ON;    
    /*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_DB NVARCHAR(50), @_Table NVARCHAR(500);
	SET @_DB = DB_NAME();
	SET @_Table = '[MRT].[_TPL_TRN]';

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_UPD DATETIME2,@_SCHD DATE,@_SCHD_TIME DATETIME2(0); 
	SELECT TOP 1 @_UPD = o.[CurrentTime]
	,@_SCHD = o.[CurrentTime]
	,@_SCHD_TIME = o.[CurrentTime]		
	FROM [UTL].[Variable] AS o ;

	/*#*---------- ♻️ EMPTY ----------*#*/
	EXEC [UTL].[EmptyTable] @Controller, @_Table;

	
    /*#*========== ✅ ACTION ==========*#*/
	INSERT [MRT].[_TPL_TRN] ([zID],[zUPD]
		,[BK_SRC]
		,[BK_DE]
		,[BK_DE_OG]
		,[BK_Tran]
		,[BK_Entity]
		,[BK_Entity_OG]
		,[DV_A]
		,[DV_B]
		,[DV_C]
		,[EntityCode]
		,[EntityName]
		,[TranNo]
		,[TranDate]
		,[TUOM]
		,[DUOM]
		,[CurrCode_TRN]
		,[CurrCode_BASE]
		,[CurrCode_CON]
		,[UC_TUOM_TO_DUOM]
		,[Qty_TUOM]
		,[Qty_DUOM]
		,[UnitCost_TRN_TUOM]
		,[UnitPrice_TRN_TUOM]
		,[UnitCost_BASE_DUOM]
		,[UnitPrice_BASE_DUOM]
	  )
	SELECT NEWID() AS [zID], @_UPD AS [zUPD]
		,o.[BK_SRC]
		,o.[BK_DE]
		,o.[BK_DE] AS [BK_DE_OG]
		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[BK_Tran]
		,ISNULL(rREF.[BK_DE], '[UN]') AS [BK_Entity]
		,o.[BK_Entity] AS [BK_Entity_OG]
		/*#*---------- 📌 DETAIL ----------*#*/ -- SELECT TOP 10 *
		,'G1' AS [DV_A], 'AU' AS [DV_B], 'DOM' AS [DV_C]	
		,rREF.[EntityCode]
		,rREF.[EntityName]
		,o.[TranNo]
		,o.[TranDate]
		,o.[TUOM]
		,o.[DUOM]
		,o.[CurrCode_TRN]
		,o.[CurrCode_BASE]
		,o.[CurrCode_CON]
		,o.[UC_TUOM_TO_DUOM]
		,o.[Qty_TUOM]
		,o.[Qty_DUOM]
		,o.[UnitCost_TRN_TUOM]
		,o.[UnitPrice_TRN_TUOM]
		,o.[UnitCost_BASE_DUOM]
		,o.[UnitPrice_BASE_DUOM]
	FROM [HUB].[_TPL_TRN] AS o
	LEFT JOIN [HUB].[_TPL_REF] AS rREF ON rREF.[BK_DE] = o.[BK_Entity]
	WHERE 1=1 ;


    /*#*---------- 🧹 CLEANUP ----------*#*/
	EXEC [UTL].[RemoveDuplication] @Controller, @_Table;

	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [MRT].[_TPL_TRN_Refresh_C2]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






















/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%TPL_TRN%', 'Proc';

    EXEC [MRT].[_TPL_TRN_Refresh_C2];
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * 
	-- SELECT COUNT(*)
	FROM [MRT].[_TPL_TRN] AS o
	WHERE 1=1
	ORDER BY 4,5,6

*/
CREATE PROC [MRT].[_TPL_TRN_Refresh_C2]
    @Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/    
AS
BEGIN
	SET NOCOUNT ON;    
    /*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_DB NVARCHAR(50), @_Table NVARCHAR(500);
	SET @_DB = DB_NAME();
	SET @_Table = '[MRT].[_TPL_TRN]';

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_UPD DATETIME2,@_SCHD DATE,@_SCHD_TIME DATETIME2(0); 
	SELECT TOP 1 @_UPD = o.[CurrentTime]
	,@_SCHD = o.[CurrentTime]
	,@_SCHD_TIME = o.[CurrentTime]		
	FROM [UTL].[Variable] AS o ;

	/*#*########## 📚 SECTION ##########*#*/


	/*#*########## 📚 SECTION ##########*#*/


	/*#*########## 📚 SECTION ##########*#*/


    /*#*---------- 🧹 CLEANUP ----------*#*/
	

	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [MRT].[_TPL_TRN_Update]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] '%TPL_TRN%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [MRT].[_TPL_TRN_Refresh];
	EXEC [MRT].[_TPL_TRN_Refresh_C2];
	EXEC [MRT].[_TPL_TRN_Update];
	EXEC [MRT].[_TPL_TRN_Update_C2];
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 100 * 
	-- SELECT COUNT(*) 
	FROM [MRT].[_TPL_TRN]
	ORDER BY 4,5,6
	
*/
CREATE PROC [MRT].[_TPL_TRN_Update]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_UPD DATETIME2,@_SCHD DATE,@_SCHD_TIME DATETIME2(0),@_TABLE VARCHAR(500);
	SELECT TOP 1 @_UPD = o.[CurrentTime]
	,@_SCHD = o.[CurrentTime]
	,@_SCHD_TIME = o.[CurrentTime]
	FROM [UTL].[Variable] AS o;

	SET @_TABLE = '[MRT].[_TPL_TRN]';

	/*#*========== 🧩 PREPARE ==========*#*/
	;WITH cteBase AS (
		SELECT o.[zID]
		  ,[CA_zStatus] = 'Valid'
		  ,[CA_zLock] = CONCAT_WS('/', o.[DV_A], o.[DV_B], o.[DV_C]) 
		  ,[CA_zMemo] = CONCAT_WS(';', o.[CA_zMemo], 'Update')
		FROM [MRT].[_TPL_TRN] AS o
	)
	/*#*---------- 📌 DETAIL ----------*#*/
	,cteExtA AS (
		SELECT o.[zID]
		,[CA_zFlag] = 1
		,[CA_BK_Date] = ISNULL(o.[TranDate], '2000-01-01')
		FROM [MRT].[_TPL_TRN] AS o
	)
	/*#*---------- 📌 DETAIL ----------*#*/
	,cteStage10 AS (
		SELECT o.[zID]
		  ,[CA_Qty_DUOM]  = o.[Qty_DUOM]      
		  ,o.[UnitCost_BASE_DUOM]
		  ,o.[UnitPrice_BASE_DUOM]
		FROM [MRT].[_TPL_TRN] AS o
	)
	/*#*---------- 📌 DETAIL ----------*#*/
	,cteStage20 AS (
		SELECT o.*
		  ,[CA_Cost_BASE] = o.[UnitCost_BASE_DUOM] * o.[CA_Qty_DUOM]
		  ,[CA_Value_BASE] = o.[UnitPrice_BASE_DUOM] * o.[CA_Qty_DUOM]
		  ,[CA_Cost_CON] = o.[UnitCost_BASE_DUOM]  * o.[CA_Qty_DUOM] -- * Exchange Rate
		  ,[CA_Value_CON] = o.[UnitPrice_BASE_DUOM] * o.[CA_Qty_DUOM] -- * Exchange Rate      
		FROM cteStage10 AS o
	)
	/*#*---------- 📌 DETAIL ----------*#*/
    ,cteStage30 AS (
		SELECT o.*
			,[CA_Margin_BASE] = o.[CA_Value_BASE] - o.[CA_Cost_BASE]
			,[CA_Margin_CON] = o.[CA_Value_CON] - o.[CA_Cost_CON]
			,[CA_MarginRatio] = (o.[CA_Value_CON] - o.[CA_Cost_CON]) / NULLIF(o.[CA_Value_CON], 0)
		FROM cteStage20 AS o
	)
	/*#*---------- 📌 DETAIL ----------*#*/
	,cteStage40 AS (
		SELECT o.*
		,[CA_MarginBand] = CASE WHEN o.[CA_MarginRatio] < 0  THEN 'Negative'
										  ELSE 'Positive' END
		FROM cteStage30 AS o
	)

	/*#*========== ✅ ACTION ==========*#*/	
	UPDATE o
	SET [CA_zStatus] = x.[CA_zStatus]
		,[CA_zLock] = x.[CA_zLock]
		,[CA_zMemo] = x.[CA_zMemo]
		/*#*---------- 📌 DETAIL ----------*#*/
		,[CA_zFlag] = extA.[CA_zFlag]
		,[CA_BK_Date] = extA.[CA_BK_Date]
		/*#*---------- 📌 DETAIL ----------*#*/
		,[CA_Qty_DUOM] = stg.[CA_Qty_DUOM]
		,[CA_Cost_BASE] = stg.[CA_Cost_BASE]
		,[CA_Value_BASE] = stg.[CA_Value_BASE]
		,[CA_Margin_BASE] = stg.[CA_Margin_BASE]
		,[CA_Cost_CON] = stg.[CA_Cost_CON]
		,[CA_Value_CON] = stg.[CA_Value_CON]
		,[CA_Margin_CON] = stg.[CA_Margin_CON]
		,[CA_MarginRatio] = stg.[CA_MarginRatio]
		,[CA_MarginBand] = stg.[CA_MarginBand]
    FROM [MRT].[_TPL_TRN] AS o
	LEFT JOIN cteBase AS x ON x.[zID] = o.[zID]
	LEFT JOIN cteExtA AS extA ON extA.[zID] = o.[zID]
	LEFT JOIN cteStage40 AS stg ON stg.[zID] = o.[zID]
	

	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [MRT].[_TPL_TRN_Update_C2]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






















/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/
	EXEC [SVC].[FindX] '%TPL_TRN%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [MRT].[_TPL_TRN_Refresh]; 
	EXEC [MRT].[_TPL_TRN_Refresh_C2]; 
	EXEC [MRT].[_TPL_TRN_Update]; 
	EXEC [MRT].[_TPL_TRN_Update_C2]; 
	EXEC [MRT].[_TPL_TRN_Update_END]; 
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 100 * 
	-- SELECT COUNT(*) 
	FROM [MRT].[_TPL_TRN]
	ORDER BY 4,5,6
	
*/
CREATE PROC [MRT].[_TPL_TRN_Update_C2]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_UPD DATETIME2,@_SCHD DATE,@_SCHD_TIME DATETIME2(0),@_TABLE VARCHAR(500);
	SELECT TOP 1 @_UPD = o.[CurrentTime]
	,@_SCHD = o.[CurrentTime]
	,@_SCHD_TIME = o.[CurrentTime]
	FROM [UTL].[Variable] AS o;

	SET @_TABLE = '[MRT].[_TPL_TRN]';

	/*#*========== 🧩 PREPARE ==========*#*/
	;WITH cteBase AS (
		SELECT o.[zID]
		  ,[CA_zMemo] = CONCAT_WS(';', o.[CA_zMemo], 'Update_C2')
		FROM [MRT].[_TPL_TRN] AS o
	)
	/*#*---------- 📌 DETAIL ----------*#*/
	,cteExtA AS (
		SELECT o.[zID]		
		FROM [MRT].[_TPL_TRN] AS o
	)
	/*#*---------- 📌 DETAIL ----------*#*/
	,cteStage10 AS (
		SELECT o.[zID]		
		FROM [MRT].[_TPL_TRN] AS o
	)
	/*#*---------- 📌 DETAIL ----------*#*/
	,cteStage20 AS (
		SELECT o.*		  
		FROM cteStage10 AS o
	)
	

	/*#*========== ✅ ACTION ==========*#*/	
	UPDATE o
	SET [CA_zMemo] = x.[CA_zMemo]
		/*#*---------- 📌 DETAIL ----------*#*/		
		/*#*---------- 📌 DETAIL ----------*#*/
		
    FROM [MRT].[_TPL_TRN] AS o
	LEFT JOIN cteBase AS x ON x.[zID] = o.[zID]
	LEFT JOIN cteExtA AS extA ON extA.[zID] = o.[zID]
	LEFT JOIN cteStage20 AS stg ON stg.[zID] = o.[zID]
  

	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [MRT].[_TPL_TRN_Update_END]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/
	EXEC [SVC].[FindX] '%TPL_TRN%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [MRT].[_TPL_TRN_Update_END];
	
	SELECT TOP 100 * 
	-- SELECT COUNT(*) 
	FROM [MRT].[_TPL_TRN]
	ORDER BY 4,5,6
	
*/
CREATE PROC [MRT].[_TPL_TRN_Update_END]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_UPD DATETIME2,@_SCHD DATE,@_SCHD_TIME DATETIME2(0),@_TABLE VARCHAR(500);
	SELECT TOP 1 @_UPD = o.[CurrentTime]
	,@_SCHD = o.[CurrentTime]
	,@_SCHD_TIME = o.[CurrentTime]
	FROM [UTL].[Variable] AS o;

	SET @_TABLE = '[MRT].[_TPL_TRN]';
	
	/*#*========== 🧩 PREPARE ==========*#*/
	;WITH cteBase AS (
		SELECT o.[zID]
		  ,[CA_zMemo] = CONCAT_WS(';', o.[CA_zMemo], 'Update_END')
		FROM [MRT].[_TPL_TRN] AS o
	)
	/*#*---------- 📌 DETAIL ----------*#*/
	,cteExtA AS (
		SELECT o.[zID]		
		FROM [MRT].[_TPL_TRN] AS o
	)
	/*#*---------- 📌 DETAIL ----------*#*/
	,cteStage10 AS (
		SELECT o.[zID]		
		FROM [MRT].[_TPL_TRN] AS o
	)
	/*#*---------- 📌 DETAIL ----------*#*/
	,cteStage20 AS (
		SELECT o.*		  
		FROM cteStage10 AS o
	)
	

	/*#*========== ✅ ACTION ==========*#*/	
	UPDATE o
	SET [CA_zMemo] = x.[CA_zMemo]
		/*#*---------- 📌 DETAIL ----------*#*/		
		/*#*---------- 📌 DETAIL ----------*#*/
		
    FROM [MRT].[_TPL_TRN] AS o
	LEFT JOIN cteBase AS x ON x.[zID] = o.[zID]
	LEFT JOIN cteExtA AS extA ON extA.[zID] = o.[zID]
	LEFT JOIN cteStage20 AS stg ON stg.[zID] = o.[zID]
    

	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [PAX].[AGG_0Template_Reload]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%TPL%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/
    EXEC [PAX].[AGG_0Template_Reload];
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * 
	-- SELECT COUNT(*)
	FROM [PAX].[AGG_0Template] AS o
	WHERE 1=1
	ORDER BY 4,5,6

*/
CREATE PROC [PAX].[AGG_0Template_Reload]
    @Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/    
AS
BEGIN
	SET NOCOUNT ON;  SET ANSI_WARNINGS OFF;
    /*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_DB NVARCHAR(50), @_Table NVARCHAR(500);
	SET @_DB = DB_NAME();
	SET @_Table = '[PAX].[AGG_0Template]';

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_UPD DATETIME2, @_StartDate DATETIME2(0),@_EndDate DATETIME2(0); 
	SELECT TOP 1 @_UPD = o.[CurrentTime]
	,@_StartDate = o.[CurrentFinancialYear-1]
	,@_EndDate = DATEADD(DAY, -1, DATEADD(YEAR, 1, o.[CurrentFinancialYear]))
	FROM [UTL].[Variable] AS o;

	/*#*---------- ♻️ EMPTY ----------*#*/
	EXEC [UTL].[EmptyTable] @Controller, @_Table;

	/*#*========== 🧩 PREPARE ==========*#*/
	;WITH cteSum AS (
		SELECT [BK_Org] = o.[DV_A]
			,[BK_Date] = CONVERT(DATE,DATETRUNC(MONTH, o.[BK_Date]))
			,[BK_Misc] = CONCAT_WS('+', o.[DV_B], o.[DV_C])		
			,[Value] = SUM(o.[CA_Value_CON])
			,[Target] = SUM(o.[CA_Value_CON]) * (1 + ABS(CHECKSUM(NEWID())) % 100 /100.0)
		FROM [AAM].[_TPL_TRN] AS o
		WHERE o.[zStatus] = 'Valid'
		AND o.[BK_Date] BETWEEN @_StartDate AND @_EndDate
		GROUP BY o.[DV_A], o.[DV_B], o.[DV_C], DATETRUNC(MONTH, o.[BK_Date])
	)
	,cteData AS (
		SELECT [BK_Org], [BK_Date], [BK_Misc], [Value], [Target]
		FROM cteSum
		UNION
		SELECT [BK_Org], [BK_Date], '*' AS [BK_Misc], SUM([Value]) AS [Value], SUM([Target]) AS [Target]
		FROM cteSum
		GROUP BY [BK_Org], [BK_Date]
	)
	/*#*---------- 📌 DETAIL ----------*#*/
	,cteMonth AS (
		SELECT [BK_Date] = [Day]
		,[BK_Year] = o.[FinancialYearKey]
		,[BK_Period] = o.[MonthOfFinancialYearKey]
		FROM [AAM].[Calendar] AS o
		WHERE o.[DayOfMonthKey] = 1
		AND o.[Day] BETWEEN @_StartDate AND @_EndDate
	)
	,cteFrame AS (		
		SELECT o.[BK_Org]
			,o.[BK_Misc]
			,x.[BK_Date]
			,x.[BK_Year]
			,x.[BK_Period]
		FROM ( SELECT [BK_Org], [BK_Misc] FROM cteData GROUP BY [BK_Org], [BK_Misc] ) AS o
		CROSS JOIN cteMonth AS x 
	)
    /*#*========== ✅ ACTION ==========*#*/	
	INSERT [PAX].[AGG_0Template] ([zID],[zUPD]
		,[BK_DE]
		,[BK_Org]
		,[BK_Date]
		,[BK_Misc]
		,[BK_Year]
		,[BK_Period]
		,[Value_Actual]
		,[Value_Target]
		,[CA_Memo]
	  )
	SELECT NEWID() AS [zID], @_UPD AS [zUPD]
		,[BK_DE] = CONCAT_WS('+', o.[BK_Org], o.[BK_Misc], FORMAT(DATETRUNC(MONTH, o.[BK_Date]), 'yyyy-MM-dd'))
		,o.[BK_Org]
		,o.[BK_Date]
		,o.[BK_Misc]
		,o.[BK_Year]
		,o.[BK_Period]
		,[Value_Actual] = x.[Value]
		,[Value_Target] = x.[Target]		
		,[CA_Memo] = 'Aggregated'	
	FROM cteFrame AS o
	LEFT JOIN cteData AS x ON x.[BK_Org] = o.[BK_Org] AND x.[BK_Misc] = o.[BK_Misc] AND x.[BK_Date] = o.[BK_Date]

	/*#*########## 📚 SECTION ##########*#*/

	/*#*########## 📚 SECTION ##########*#*/
	;WITH cteYTD AS (
		SELECT o.[BK_DE]
		,SUM(x.[Value_Actual]) AS [Value_Actual_YTD]
		,SUM(x.[Value_Target]) AS [Value_Target_YTD]
		FROM [PAX].[AGG_0Template] AS o
		LEFT JOIN [PAX].[AGG_0Template] AS x ON x.[BK_Org] = o.[BK_Org] AND x.[BK_Misc] = o.[BK_Misc] AND x.[BK_Year] = o.[BK_Year] AND x.[BK_Period] <= o.[BK_Period]
		GROUP BY o.[BK_DE]
	)
	UPDATE o
	SET [Value_Actual_YTD] = x.[Value_Actual_YTD]
	, [Value_Target_YTD] = x.[Value_Target_YTD]
	FROM [PAX].[AGG_0Template]  AS o
	LEFT JOIN cteYTD AS x ON x.[BK_DE] = o.[BK_DE]

    /*#*---------- 🧹 CLEANUP ----------*#*/
	EXEC [UTL].[RemoveDuplication] @Controller, @_Table;



	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [PAX].[KPI_101_Update]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%PAX%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [PAX].[KPI_Detail_Reload]; 
    EXEC [PAX].[KPI_101_Update];
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * 
	-- SELECT COUNT(*)
	FROM [PAX].[KPI_Detail] AS o
	WHERE BK_KPI = '101'
	ORDER BY 4,5,6

*/
CREATE PROC [PAX].[KPI_101_Update]
    @Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/    
AS
BEGIN
	SET NOCOUNT ON;    
    /*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*---------- 📄 PARAMETER ----------*#*/
	DECLARE @_BK_KPI NVARCHAR(50), @_SQL VARCHAR(4000);	
	SET @_BK_KPI = '101';
	SET @_SQL = 'SELECT [BK_Org], [BK_Date], [BK_Misc], [Value_Actual], [Value_Target] 
FROM [PAX].[AGG_0Template] 
WHERE [BK_Misc] = ''*''';

	/*#*========== ✅ ACTION ==========*#*/
    EXEC [PAX].[KPI_Detail_Update] @Controller, @_BK_KPI, @_SQL;


	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [PAX].[KPI_Detail_Reload]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%TPL%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/
    EXEC [PAX].[KPI_Detail_Reload];
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * 
	-- SELECT COUNT(*)
	FROM [PAX].[KPI_Detail] AS o
	WHERE 1=1
	ORDER BY 4,5,6

*/
CREATE PROC [PAX].[KPI_Detail_Reload]
    @Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/    
AS
BEGIN
	SET NOCOUNT ON;    
    /*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_LogID NVARCHAR(50), @_Controller NVARCHAR(500), @_Action NVARCHAR(500), @_Message_BGN NVARCHAR(500), @_Message_END NVARCHAR(500);	
	SELECT @_LogID = NEWID(), @_Controller = o.[Controller], @_Action = o.[Action], @_Message_BGN = o.[Message_BGN], 	@_Message_END = o.[Message_END]		
	FROM [UTL].[GetLogParam](@Controller, @@SPID) AS o ;
	
	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_BGN, @_LogID, @_LogID;

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_DB NVARCHAR(50), @_Table NVARCHAR(500);
	SET @_DB = DB_NAME();
	SET @_Table = '[PAX].[KPI_Detail]';

	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_UPD DATETIME2, @_StartDate DATETIME2(0),@_EndDate DATETIME2(0); 
	SELECT TOP 1 @_UPD = o.[CurrentTime]
	,@_StartDate = o.[CurrentFinancialYear-1]
	,@_EndDate = DATEADD(DAY, -1, DATEADD(YEAR, 1, o.[CurrentFinancialYear]))
	FROM [UTL].[Variable] AS o;

	/*#*---------- ♻️ EMPTY ----------*#*/
	EXEC [UTL].[EmptyTable] @Controller, @_Table;

	/*#*========== 🧩 PREPARE ==========*#*/
	;WITH cteMonth AS (
		SELECT [BK_Date] = [Day]
		,[BK_Year] = o.[FinancialYearKey]
		,[BK_Period] = o.[MonthOfFinancialYearKey]
		FROM [AAM].[Calendar] AS o
		WHERE o.[DayOfMonthKey] = 1
		AND o.[Day] BETWEEN @_StartDate AND @_EndDate
	)
    /*#*========== ✅ ACTION ==========*#*/	
	INSERT [PAX].[KPI_Detail] ([zID],[zUPD]
		,[BK_DE]
		,[BK_Org]
		,[BK_KPI]
		,[BK_Date]
		,[OrgCode]
		,[OrgName]
		,[OrgName_OG]
		/*#*---------- 📌 DETAIL ----------*#*/
		,[KPI_CategoryGroup]
		,[KPI_CategoryCode]
		,[KPI_CategoryName]
		,[KPI_CategorySeq]
		,[KPI_Code]
		,[KPI_Name]
		,[KPI_Name_OG]
		,[KPI_Seq]
		,[KPI_Description]
		,[KPI_Format]
		,[KPI_FormatString]
		,[KPI_StatusCode_Default]
		,[KPI_StatusName_Default]
		/*#*---------- 📌 DETAIL ----------*#*/
		,[KPI_TargetType]		
		,[Green_State]
		,[Amber_State]
		,[Red_State]
		,[StartDate]
		,[EndDate]
		/*#*---------- 📌 DETAIL ----------*#*/
		,[KPI_TargetValue]
		,[KPI_TargetValue_Left]
		,[KPI_TargetValue_Right]
		/*#*---------- 📌 DETAIL ----------*#*/
		,[CA_StatusCode_Left]
		,[CA_StatusCode_Middle]
		,[CA_StatusCode_Right]
		,[CA_StartDate]
		,[CA_EndDate]
		,[CA_StatusName]
		,[CA_StatusCode]
		,[CA_StatusValue]
		/*#*---------- 📌 DETAIL ----------*#*/
		,[CA_Target_Display]
		,[CA_Actual_Display]
		,[CA_Value_Display]
		,[CA_Memo]
		/*#*---------- 📌 DETAIL ----------*#*/
		,[DrillThroughLink]
		,[DrillThroughReport]
	  )
	SELECT NEWID() AS [zID], @_UPD AS [zUPD]
		,[BK_DE] = CONCAT_WS('+', o.[OrgCode], o.[KPI_Code], FORMAT(DATETRUNC(MONTH, rMonth.[BK_Date]), 'yyyy-MM-dd'))
		,[BK_Org] = o.[OrgCode]
		,[BK_KPI] = o.[KPI_Code]
		,[BK_Date] = rMonth.[BK_Date]
		,o.[OrgCode]
		,o.[OrgName]
		,o.[OrgName] AS [OrgName_OG]
		/*#*---------- 📌 DETAIL ----------*#*/
		,rKPI.[KPI_CategoryGroup]
		,rKPI.[KPI_CategoryCode]
		,rKPI.[KPI_CategoryName]
		,rKPI.[KPI_CategorySeq]
		,rKPI.[KPI_Code]
		,rKPI.[KPI_Name]
		,rKPI.[KPI_Name] AS [KPI_Name_OG]
		,rKPI.[KPI_Seq]
		,rKPI.[KPI_Description]
		,rKPI.[KPI_Format]
		,rKPI.[KPI_FormatString]
		,rKPI.[KPI_StatusCode_Default]
		,rKPI.[KPI_StatusName_Default]
		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[KPI_TargetType]
		,o.[Green_State]
		,o.[Amber_State]
		,o.[Red_State]
		,o.[StartDate]
		,o.[EndDate]
		/*#*---------- 📌 DETAIL ----------*#*/
		,o.[KPI_TargetValue]
		,o.[KPI_TargetValue_Left]
		,o.[KPI_TargetValue_Right]
		/*#*---------- 📌 DETAIL ----------*#*/
		,[CA_StatusCode_Left] = CASE WHEN [KPI_TargetType] = 'Higher is better' THEN 'R' ELSE 'G' END
		,[CA_StatusCode_Middle] = 'A'
		,[CA_StatusCode_Right] = CASE WHEN [KPI_TargetType] = 'Higher is better' THEN 'G' ELSE 'R' END
		,o.[StartDate] AS [CA_StartDate]
		,ISNULL(o.[EndDate], @_EndDate) AS [CA_EndDate]
		,[CA_StatusName] = rKPI.[KPI_StatusName_Default]
		,[CA_StatusCode] = rKPI.[KPI_StatusCode_Default]
		,[CA_StatusValue] = rKPI.[KPI_StatusValue_Default]
		/*#*---------- 📌 DETAIL ----------*#*/
		,[CA_Target_Display] = NULL
		,[CA_Actual_Display] = NULL
		,[CA_Value_Display] = NULL
		,[CA_Memo] = 'Default'
		/*#*---------- 📌 DETAIL ----------*#*/
		,rKPI.[DrillThroughLink]
		,rKPI.[DrillThroughReport]
	FROM [VPL].[KPI_Target] AS o
	INNER JOIN [VPL].[KPI_Definition] AS rKPI ON rKPI.[KPI_Code] = o.[KPI_Code]
	INNER JOIN cteMonth AS rMonth ON rMonth.[BK_Date] BETWEEN o.[StartDate] AND ISNULL(o.[EndDate], @_EndDate)

    /*#*---------- 🧹 CLEANUP ----------*#*/
	EXEC [UTL].[RemoveDuplication] @Controller, @_Table;



	/*#*---------- 📝 LOGGING ----------*#*/
	EXEC [UTL].[AddLog] @_Controller, @_Action, @_Message_END, NULL,@_LogID;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [PAX].[KPI_Detail_Update]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [SVC].[FindX] '%PAX%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [PAX].[KPI_Detail_Reload]; 
    EXEC [PAX].[KPI_Detail_Update] 'Ad-hoc', '101', 'SELECT [BK_Org], [BK_Date], [BK_Misc], [Value_Actual], [Value_Target] FROM [PAX].[AGG_0Template] WHERE [BK_Misc] = ''*''';
	
	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT BK_DE, o.KPI_TargetType, CA_StatusName, CA_Target_Display, CA_Actual_Display, CA_Value_Display
	,o.[KPI_TargetValue] AS [T_Value]
			,o.[KPI_TargetValue_Left] AS [TL_Value]
			,o.[KPI_TargetValue_Right] AS [TR_Value]
			,o.[CA_StatusCode_Left] AS [L_Status]
			,o.[CA_StatusCode_Middle] AS [M_Status]
			,o.[CA_StatusCode_Right] AS [R_Status]
	--SELECT * 
	-- SELECT COUNT(*)	
	FROM [PAX].[KPI_Detail] AS o
	WHERE BK_KPI = '101'
	ORDER BY 1

*/
CREATE PROC [PAX].[KPI_Detail_Update]
    @Controller VARCHAR(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/    
	,@BK_KPI VARCHAR(10) = NULL /*_*{Parameter},{@BK_KPI},{BK_KPI: 101, 102}*_*/	
	,@Script VARCHAR(4000) = NULL /*_*{Parameter},{@Script},{AGG_Query to get the actual}*_*/
AS
BEGIN
	SET NOCOUNT ON;    
    /*#*========== 🎯 PURPOSE ==========*#*/

	/*#*---------- 📄 PARAMETER ----------*#*/
	DECLARE @_UPD DATETIME2, @_BK_KPI NVARCHAR(50), @_CutoffDate DATETIME2(0), @_Script VARCHAR(4000);	
	SELECT @_BK_KPI = @BK_KPI
		,@_CutoffDate = DATEADD(DAY, 0, DATEADD(MONTH, 1, o.[CurrentMonth-1]))
		,@_UPD = o.[CurrentTime]
		,@_Script = TRIM(@Script)
	FROM [UTL].[Variable] AS o;

	
	/*#*========== 🧩 PREPARE ==========*#*/
	DECLARE @Actual TABLE ([BK_Org] VARCHAR(50), [BK_Date] DATETIME2(0), [BK_Misc] VARCHAR(50), [Value_Actual] DECIMAL(18,6), [Value_Target] DECIMAL(18,6));
	/*#*========== ✅ ACTION ==========*#*/
	INSERT @Actual
	EXEC(@Script);

	/*#*========== 🧩 PREPARE ==========*#*/
	;WITH cteActual AS (
		SELECT  o.[BK_Org], o.[BK_Date]
			,@_BK_KPI AS [BK_KPI]			
			,o.[Value_Actual] AS [A_Value]
			,o.[Value_Target] AS [T_Value]	
		FROM @Actual AS o
	)
	, cteTarget AS (
		SELECT o.[BK_Org], o.[BK_Date], [BK_KPI]
			,o.[KPI_TargetValue] AS [T_Value]
			,o.[KPI_TargetValue_Left] AS [TL_Value]
			,o.[KPI_TargetValue_Right] AS [TR_Value]
			,o.[CA_StatusCode_Left] AS [L_Status]
			,o.[CA_StatusCode_Middle] AS [M_Status]
			,o.[CA_StatusCode_Right] AS [R_Status]
		FROM [PAX].[KPI_Detail] AS o
		WHERE o.[BK_KPI] = @_BK_KPI
	)
	,cteActualWithTarget AS (
		SELECT	o.[BK_Org], o.[BK_KPI], o.[BK_Date]
		,o.[A_Value]
		,o.[T_Value] * x.[T_Value] AS [T_Value]
		,o.[T_Value] * x.[TL_Value] AS [TL_Value]
		,o.[T_Value] * x.[TR_Value] AS [TR_Value]
		,x.[L_Status], x.[M_Status], x.[R_Status]
		FROM cteActual AS o
		INNER JOIN cteTarget AS x ON x.[BK_Org] = o.[BK_Org] AND x.[BK_KPI] = o.[BK_KPI] AND x.[BK_Date] = o.[BK_Date]
		WHERE o.[A_Value] IS NOT NULL
	)	
	,cteKPI AS (
		SELECT o.[BK_DE]
			,[CA_StatusCode] = CASE WHEN o.[BK_Date] <= @_CutoffDate 
											THEN CASE WHEN x.[A_Value] < x.[TL_Value] THEN x.[L_Status]
													WHEN x.[A_Value] >= x.[TL_Value] AND x.[A_Value] < x.[TR_Value] THEN x.[M_Status]
													WHEN x.[A_Value] >= x.[TR_Value] THEN x.[R_Status]
													ELSE o.[KPI_StatusCode_Default] END								
											ELSE o.[KPI_StatusCode_Default] END
			,[CA_Target_Display] =  'Amber' + ': ' + FORMAT(x.[TL_Value], o.[KPI_FormatString]) + '' + ' to ' +  FORMAT(x.[TR_Value], o.[KPI_FormatString])  + ''
			,[CA_Actual_Display] = '' + FORMAT(x.[A_Value], o.[KPI_FormatString])  + ''
			,[CA_Value_Display] = CASE WHEN o.[BK_Date] <= @_CutoffDate THEN  FORMAT(x.[A_Value], o.[KPI_FormatString]) 
													ELSE FORMAT(x.[T_Value], o.[KPI_FormatString]) END
		FROM [PAX].[KPI_Detail] AS o
		INNER JOIN cteActualWithTarget AS x ON x.[BK_Org] = o.[BK_Org] AND x.[BK_KPI] = o.[BK_KPI] AND x.[BK_Date] = o.[BK_Date]		
	)
	/*#*========== ✅ ACTION ==========*#*/
	UPDATE o
	SET [zUPD] = @_UPD
		,[CA_StatusCode] = x.[CA_StatusCode]
		,[CA_Target_Display] = ISNULL(x.[CA_Target_Display], '')
		,[CA_Actual_Display] = ISNULL(x.[CA_Actual_Display], '')
		,[CA_Value_Display] = ISNULL(x.[CA_Value_Display], '')
		,[CA_StatusName] = s.[KPI_StatusName]
		,[CA_StatusValue] = s.[KPI_StatusValue]
		,[CA_Memo] = CONCAT_WS(';', o.[CA_Memo], 'Calculated')
	FROM [PAX].[KPI_Detail] AS o
	INNER JOIN cteKPI AS x ON x.[BK_DE] = o.[BK_DE]
	LEFT JOIN [PAX].[KPI_Status] AS s ON s.[KPI_StatusCode] = x.[CA_StatusCode]

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [SVC].[FindX]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







/*    
    /*#*---------- 🔍 EXAMPLE: Type ----------*#*/
    EXEC [SVC].[FindX] 'AC%', 'Proc';
	EXEC [SVC].[FindX] '%CFG%', 'Proc';
    EXEC [SVC].[FindX] '%','Column';
    EXEC [SVC].[FindX] '%','View';
    EXEC [SVC].[FindX] '%Log%','Table';
   

*/
CREATE PROC [SVC].[FindX]
    @Keyword VARCHAR(500) = NULL /*_*{Parameter},{@Keyword},{Table Name}*_*/
    ,@Type VARCHAR(50) = '*' /*_*{Parameter},{@Type},{Seaching Scope: Column, Table, Proc or Global }*_*/
    ,@DB VARCHAR(500) = '*' /*_*{Parameter},{@DB},{Database Name}*_*/	
	,@Extra VARCHAR(500) = '' /*_*{Parameter},{@Extra},{Additional Information BK, Reference and more }*_*/
AS
BEGIN
	SET NOCOUNT ON;
    
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_DB_Count SMALLINT, @_Level SMALLINT , @_Scope SMALLINT, @_ObjectType VARCHAR(50), @_Keyword VARCHAR(200);

    /*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_DB_List TABLE ([BK_Database] VARCHAR(50), [DatabaseName] VARCHAR(50));

    /*#*========== 🧩 PREPARE ==========*#*/
    ;WITH cteDB AS (    
        SELECT DISTINCT TRIM(value) AS DB
        FROM STRING_SPLIT(@DB, N',')
        WHERE TRIM(value) <> N''
    )
    INSERT @_DB_List
    SELECT o.[BK_DE], o.[DatabaseName]
    FROM [SVC].[Meta_Database] AS o
    WHERE @DB = '*'
    OR ( o.[BK_DE] IN (SELECT DB FROM cteDB)    )
    OR ( o.DatabaseName IN (SELECT DB FROM cteDB)  )
    ;
    /*#*---------- 📄 PARAMETER ----------*#*/
    SET @_DB_Count = (SELECT COUNT(*) FROM @_DB_List);

    /*#*---------- 📄 PARAMETER ----------*#*/	
    SET @_ObjectType = TRIM(@Type);
    SET @_Scope = CASE WHEN CHARINDEX('Global', @_ObjectType) > 0 THEN 1 
                                        WHEN @_DB_Count > 1 THEN 1 
                              ELSE 0 END;

    SET @_Level = (SELECT COUNT(*)
        FROM (VALUES
            (PARSENAME(@Keyword, 1)),
            (PARSENAME(@Keyword, 2)),
            (PARSENAME(@Keyword, 3)),
            (PARSENAME(@Keyword, 4))
        ) AS o (v)
        WHERE v IS NOT NULL
    ); 
    /*#*---------- 📄 PARAMETER ----------*#*/	
    SET @_Keyword = REPLACE(REPLACE(TRIM(@Keyword), '[', ''), ']', '');
    
    -- SELECT @_Level AS Lvl, @_Keyword AS Keywrod

    /*#*========== ✅ OUTPUT ==========*#*/
    SELECT o.[BaseQuery]
      ,o.[ExtenedQuery]
      ,o.[BK_DE]
      ,o.[BK_Database]
      ,o.[BK_Schema]
      ,o.[ObjectType]
      ,o.[QN_Database]
      ,o.[QN_Schema]
      ,o.[QN_Object]
      ,o.[DatabaseName]
      ,o.[DatabaseSeq]
      ,o.[SchemaName]
      ,o.[SchemaSeq]
      ,o.[ObjectName]
      ,o.[ObjectSeq]
      ,o.[ObjectSearch]
      ,o.[ObjectNameSearch]
  FROM [SVC].[Meta_Object] AS o
  INNER JOIN @_DB_List AS x ON x.[BK_Database] = o.[BK_Database]
  WHERE 1=1
    AND (@_ObjectType = '*' OR CHARINDEX(o.[ObjectType], @_ObjectType) > 0)
    AND (  
            @_Level > 1 AND o.[ObjectSearch] LIKE @_Keyword
        OR 
            @_Level = 1 AND o.[ObjectNameSearch] LIKE @_Keyword            
        )
    
    ORDER BY [DatabaseSeq], [SchemaSeq], [ObjectSeq]

	
    
END
/*#*==================== 🔚 ====================*#*/

GO
/****** Object:  StoredProcedure [SVC].[Provision]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'AUT%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [SVC].[Provision];
	EXEC [AUT].[AddSampleData];

	EXEC [SVC].[Provision] 'V91';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT *
	FROM #LAKE#.[MISC].[_TPL_REF]

*/
CREATE PROC [SVC].[Provision]
	@System varchar(500) = NULL/*_*{Parameter},{@System},{New System name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	
	/*#*---------- 📄 PARAMETER ----------*#*/	
	DECLARE @_SQL VARCHAR(8000), @_System VARCHAR(50), @_Core VARCHAR(50), @_Lake VARCHAR(50), @_QN_Core VARCHAR(50), @_QN_Lake VARCHAR(50);
	SET @_System = TRIM(@System);
	SET @_Core = @_System + '_Core';
	SET @_Lake = @_System + '_Lake';
	SET @_QN_Core = QUOTENAME(@_Core);
	SET @_QN_Lake = QUOTENAME(@_Lake);

	/*#*========== ✅ ACTION ==========*#*/	
	WITH cteData AS (
	SELECT [Category] = 'Framework Creation Begin',  [Seq] = 100, [Script] = '/*#*########## 📚 Create Core and Lake ##########*#*/'	
	UNION SELECT [Category] = 'Validation',  [Seq] = 90, [Script] = '--   EXEC #CORE#.[SVC].[FindX] ''AUT%'', ''Proc'';  '
	UNION SELECT [Category] = 'Validation',  [Seq] = 91, [Script] = '--   EXEC #CORE#.[AUT].[GetIngestionList]; '
	UNION SELECT [Category] = 'Framework Creation End',  [Seq] = 190, [Script] = ''	
	UNION SELECT [Category] = 'Lake Template Begin',  [Seq] = 200, [Script] = '/*#*########## 📚 Sample Data ##########*#*/'
	UNION SELECT [Category] = 'Lake Template End',  [Seq] = 290, [Script] = ''	

	UNION SELECT [Category] = 'Core Creation Begin',  [Seq] = 300, [Script] = '/*#*########## 📚 Core Data ##########*#*/
USE #CORE#
GO '	
	UNION SELECT [Category] = 'Blank',  [Seq] = 390, [Script] = ''	
	UNION SELECT [Category] = 'Placeholder',  [Seq] = 391, [Script] = '/*???????????????????????????????????????????????????????????????*/'	
	UNION SELECT [Category] = 'Blank',  [Seq] = 392, [Script] = ''	
	UNION SELECT [Category] = 'Placeholder',  [Seq] = 393, [Script] = '/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/'	
	UNION SELECT [Category] = 'Core Creation End',  [Seq] = 394, [Script] = ''	

	UNION SELECT [Category] = 'Template App Creation Begin',  [Seq] = 500, [Script] = '/*#*########## 📚 Template App ##########*#*/'
	UNION SELECT [Category] = 'Template App Creation End',  [Seq] = 590, [Script] = ''

	

	/*#*---------- 📌 DETAIL ----------*#*/
	

	UNION SELECT [Category] = 'Core Creation',  [Seq] = 110, [Script] = 'CREATE DATABASE #CORE# COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8
GO
ALTER DATABASE #CORE# SET RECOVERY SIMPLE;

USE #CORE#
GO
CREATE SCHEMA [AAC]
GO
CREATE SCHEMA [AAM]
GO
CREATE SCHEMA [AUT]
GO
CREATE SCHEMA [HUB]
GO
CREATE SCHEMA [MRT]
GO
CREATE SCHEMA [PAX]
GO
CREATE SCHEMA [SVC]
GO
CREATE SCHEMA [UTL]
GO
CREATE SCHEMA [VPL]
GO
'
		UNION SELECT [Category] = CONVERT(VARCHAR(100), 'Lake Creation'),  [Seq] = 120, [Script] = 'CREATE DATABASE #LAKE#  COLLATE Latin1_General_100_CI_AS_KS_WS_SC_UTF8
GO 
ALTER DATABASE #LAKE# SET RECOVERY SIMPLE;
GO 
USE #LAKE#
GO 
CREATE SCHEMA [AAL]
GO
CREATE SCHEMA [MISC]
GO 
CREATE SCHEMA [APP]
GO
'

		/*#*========== 🧩 PREPARE ==========*#*/	
		UNION SELECT [Category] = 'Lake Settings', [Seq] = 130, [Script] = 'GO 
/*			
    /*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC #CORE#.[SVC].[FindX] ''%Config%'';

    /*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * 
	FROM [AAL].[Setting]

*/

CREATE VIEW [AAL].[Setting]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

    /*#*========== 🧩 PREPARE ==========*#*/
    WITH cteCfg AS (
		SELECT CONVERT(VARCHAR(50), ''Adelaide Time'') AS [CUR_TimeZoneDisplayName]
		,CONVERT(VARCHAR(100), ''Cen. Australia Standard Time'') AS [CUR_TimeZoneSystemName]
		,SYSDATETIMEOFFSET() AT TIME ZONE ''UTC'' AS [UTC_Time]
        ,CONVERT(VARCHAR(50), ''yyyy-MM-dd'') AS [DateStrFormat]
		,CONVERT(VARCHAR(50), ''yyyy-MM-dd HH:mm:ss'') AS [TimeStrFormat]
		,CONVERT(VARCHAR(50), ''yyyyMMddTHHmmss'') AS [TimeStampFormat]
	)
    ,cteTime AS (
		SELECT o.*
		,DATEADD(DAY, DATEDIFF(DAY, 0, o.[UTC_Time]), 0)  AS [UTC_Date]
		,o.[UTC_Time] AT TIME ZONE o.[CUR_TimeZoneSystemName] AS [CUR_Time]		
		,DATEADD(DAY, DATEDIFF(DAY, 0, o.[UTC_Time] AT TIME ZONE o.[CUR_TimeZoneSystemName]), 0)  AS [CUR_Date]
		FROM cteCfg AS o
	)
	,cteCUR_Date AS (
		SELECT o.*		
		,DATETRUNC(ISO_WEEK, o.[CUR_Date]) AS [CUR_WK]
		,DATETRUNC(MONTH, o.[CUR_Date]) AS [CUR_MTH]
		,DATETRUNC(QUARTER, o.[CUR_Date]) AS [CUR_QTR]
		,DATETRUNC(YEAR, o.[CUR_Date]) AS [CUR_Y]
		,CONVERT(DATETIME, DATEFROMPARTS(CASE WHEN MONTH(o.[CUR_Date]) >= 7 THEN YEAR(o.[CUR_Date]) ELSE YEAR(o.[CUR_Date]) - 1 END, 7, 1 )) AS [CUR_FY]
		FROM cteTime AS o
	)
    ,cteParam AS (
        SELECT o.[CUR_TimeZoneDisplayName] AS [TimeZoneName]           
          ,o.[CUR_Date] AS [CurrentDate]
          ,DATEADD(DAY, -30, [CUR_Date]) AS [CurrentDate-30]
          ,DATEADD(MONTH, DATEDIFF(MONTH, 0, o.[CUR_Date]), 0) AS [CurrentMonth]
		  ,DATEADD(MONTH, DATEDIFF(MONTH, 0, o.[CUR_Date])-3, 0) AS [CurrentMonth-3]
          ,o.[CUR_FY] AS [CurrentFinancialYear]
          ,o.[DateStrFormat]
          ,CONVERT(VARCHAR(50), FORMAT(o.[CUR_Time], ''yyyyMMddTHHmmss'')) AS [TimeStampStr]
      FROM cteCUR_Date AS o
    )
    ,cteData AS (
        SELECT o.*
        ,DATEADD(DAY, -1, DATEADD(MONTH, 1, o.[CurrentMonth])) AS [CurrentMonth_End]
        ,DATEADD(DAY, -1, DATEADD(YEAR, 1, o.[CurrentFinancialYear])) AS [CurrentFinancialYear_End]
        FROM cteParam AS o
    )
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT o.[TimeZoneName]
        ,CONVERT(VARCHAR(50), [TimeStampStr]) AS [TimeStampStr]
        ,CONVERT(VARCHAR(50), [DateStrFormat]) AS [DateStrFormat]
        /*#*---------- 📌 DETAIL ----------*#*/
        ,CONVERT(VARCHAR(50), ''APP'') AS [BK_SRC_APP]
        ,CONVERT(DATETIME2(0), o.[CurrentMonth-3]) AS [TranStartDate]
        ,CONVERT(DATETIME2(0), o.[CurrentMonth_End]) AS [TranEndDate]
        /*#*---------- 📌 DETAIL ----------*#*/        
        ,CONVERT(DATETIME2(0), o.[CurrentFinancialYear]) AS [TargetStartDate]
        ,CONVERT(DATETIME2(0), o.[CurrentFinancialYear_End]) AS [TargetEndDate]
        /*#*---------- 📌 DETAIL ----------*#*/
        ,CONVERT(VARCHAR(50), ''MISC'') AS [BK_SRC_MISC]
   FROM cteData AS o

/*#*==================== 🔚 ====================*#*/
GO'
 	
	
		/*#*========== 🧩 PREPARE ==========*#*/
		UNION SELECT [Category] = 'Lake Ingestion Parameters', [Seq] =140, [Script] = 'GO 
/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC #CORE#.[UTL].[FindX] ''%Ingestion%'';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 10 * 
	FROM [AAL].[IngestionParam]
*/
CREATE VIEW [AAL].[IngestionParam]
AS
	/*#*========== 🎯 PURPOSE: Configure the tables for the P101 to P105 extraction processes by source application. ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteData AS (
	SELECT * FROM(
		VALUES
		/*#*---------- 📌 DETAIL: MISC ----------*#*/
		(''Upstream'', 1,''MISC'', ''_TPL_REF'', ''Template'', ''[V90_Core].[SVC].[Sample_Ref]'', ''Full'')
		,(''Downstream'', 1,''MISC'', ''_TPL_TRN'', ''Template'', ''[V90_Core].[SVC].[Sample_TranDetail]'', ''Full'')

		/*#*---------- 📌 DETAIL: APP ----------*#*/
		,(''Main'', 1,''APP'', ''Ref'', ''Demo App'', ''[V90_Core].[SVC].[Sample_Ref]'', ''Full'')
		,(''Main,Zoned'', 1,''APP'', ''Target'', ''Demo App'', ''[V90_Core].[SVC].[Sample_Target]'', ''Partial'')
		,(''Main'', 5,''APP'', ''TranHeader'', ''Demo App'', ''[V90_Core].[SVC].[Sample_TranHeader]'', ''Partial'')
		,(''Main'', 5,''APP'', ''TranDetail'', ''Demo App'', ''[V90_Core].[SVC].[Sample_TranDetail]'', ''Partial'')
 
		) AS o([ScheduleList],[ProcessNo], [SchemaName], [TableName], [SourceApp], [QN_SourceTable], [Pattern]))
/*#*========== ✅ OUTPUT ==========*#*/
SELECT [ScheduleList] = CONVERT(VARCHAR(500), o.[ScheduleList]) 
	,[ProcessNo] = CONVERT(SMALLINT, o.[ProcessNo])
	,[LakeSchemaName] = CONVERT(VARCHAR(50), o.[SchemaName])
	,[LakeTableName] = CONVERT(VARCHAR(100), o.[TableName])
	,[SourceApp] = CONVERT(VARCHAR(50), o.[SourceApp])
	,[QN_SourceTable] = CONVERT(VARCHAR(100), o.[QN_SourceTable])		
	,[Pattern] = CONVERT(VARCHAR(50), o.[Pattern])
FROM cteData AS o

/*#*==================== 🔚 ====================*#*/
GO
'


		 /*#*========== 🧩 PREPARE ==========*#*/
		UNION SELECT [Category] = 'Lake Sample Data Tables', [Seq] = 210, [Script] = 'CREATE TABLE [MISC].[_TPL_REF](
[zID] VARCHAR(50) NOT NULL,
[zSTMPz] [varchar](50),
[RefCode] [varchar](50),
[RefName] [varchar](100),
[RefDesc] [varchar](200),
[RefCategory] [varchar](20),
[RefType] [varchar](20),
[RefSeq] [int],
[RefNo] [varchar](10),
[RefStatus] [varchar](20)
)
GO 
CREATE TABLE [MISC].[_TPL_TRN](
[zID] VARCHAR(50) NOT NULL,
[zSTMPz] [varchar](50),
[RefCode] [varchar](50),
[RefName] [varchar](100),
[TranNo] [nvarchar](20),
[TranLineNo] [varchar](10),
[TranDate] datetime2(0),
[TUOM] [varchar](10),
[DUOM] [varchar](10),
[CurrCode_TRN] [varchar](10),
[CurrCode_BASE] [varchar](10),
[CurrCode_CON] [varchar](10),
[UC_TUOM_TO_DUOM] [decimal](18, 6),
[Qty_TUOM] [decimal](18, 6),
[Qty_DUOM] [decimal](18, 6),
[UnitCost_TRN_TUOM] [decimal](18, 6),
[UnitPrice_TRN_TUOM] [decimal](18, 6),
[UnitCost_BASE_DUOM] [decimal](18, 6),
[UnitPrice_BASE_DUOM] [decimal](18, 6)
)
GO '


        /*#*========== 🧩 PREPARE ==========*#*/	
		UNION SELECT [Category] = 'Lake Demo APP Tables', [Seq] = 510, [Script] = 'USE #LAKE#;

CREATE TABLE [APP].[Ref](
	[zID] VARCHAR(50) NOT NULL,
	[zSTMPz] [varchar](50),
	[RefCode] [varchar](50),
	[RefName] [varchar](100),
	[RefDesc] [varchar](200),
	[RefCategory] [varchar](20),
	[RefType] [varchar](20),
	[RefSeq] [int],
	[RefNo] [varchar](10),
	[RefStatus] [varchar](20)
)

GO

CREATE TABLE [APP].[Target_FULL](
	[zID] VARCHAR(50),
	[zSTMPz] VARCHAR(50),
	[RefCode] VARCHAR(50),
	[RefName] VARCHAR(100),
	[TargetDate] DATETIME2(0),
	[DUOM] VARCHAR(10),
	[Qty_DUOM] DECIMAL(18, 6) 
)
GO

CREATE TABLE [APP].[Target_PARTIAL](
	[zID] VARCHAR(50),
	[zSTMPz] VARCHAR(50),
	[RefCode] VARCHAR(50),
	[RefName] VARCHAR(100),
	[TargetDate] DATETIME2(0),
	[DUOM] VARCHAR(10),
	[Qty_DUOM] DECIMAL(18, 6) 
)
GO
CREATE TABLE [APP].[TranDetail_FULL](
	[zID] VARCHAR(50),
	[zSTMPz] VARCHAR(50),
	[RefCode] VARCHAR(50),
	[RefName] VARCHAR(100),
	[TranNo] VARCHAR(50),
	[TranLineNo] VARCHAR(10),
	[TranDate] DATETIME2(0),
	[TUOM] VARCHAR(10),
	[DUOM] VARCHAR(10),
	[CurrCode_TRN] VARCHAR(10),
	[CurrCode_BASE] VARCHAR(10),
	[CurrCode_CON] VARCHAR(10),
	[UC_TUOM_TO_DUOM] DECIMAL(18, 6),
	[Qty_TUOM] DECIMAL(18, 6),
	[Qty_DUOM] DECIMAL(18, 6),
	[UnitCost_TRN_TUOM] DECIMAL(18, 6),
	[UnitPrice_TRN_TUOM] DECIMAL(18, 6),
	[UnitCost_BASE_DUOM] DECIMAL(18, 6),
	[UnitPrice_BASE_DUOM] DECIMAL(18, 6) 
)
GO
CREATE TABLE [APP].[TranDetail_PARTIAL](
	[zID] VARCHAR(50),
	[zSTMPz] VARCHAR(50),
	[RefCode] VARCHAR(50),
	[RefName] VARCHAR(100),
	[TranNo] VARCHAR(50),
	[TranLineNo] VARCHAR(10),
	[TranDate] DATETIME2(0),
	[TUOM] VARCHAR(10),
	[DUOM] VARCHAR(10),
	[CurrCode_TRN] VARCHAR(10),
	[CurrCode_BASE] VARCHAR(10),
	[CurrCode_CON] VARCHAR(10),
	[UC_TUOM_TO_DUOM] DECIMAL(18, 6),
	[Qty_TUOM] DECIMAL(18, 6),
	[Qty_DUOM] DECIMAL(18, 6),
	[UnitCost_TRN_TUOM] DECIMAL(18, 6),
	[UnitPrice_TRN_TUOM] DECIMAL(18, 6),
	[UnitCost_BASE_DUOM] DECIMAL(18, 6),
	[UnitPrice_BASE_DUOM] DECIMAL(18, 6) 
)
GO
CREATE TABLE [APP].[TranHeader_FULL](
	[zID] VARCHAR(50),
	[zSTMPz] VARCHAR(50),
	[RefCode] VARCHAR(50),
	[RefName] VARCHAR(100),
	[TranNo] VARCHAR(50),
	[TranDate] DATETIME2(0) 
)
GO
CREATE TABLE [APP].[TranHeader_PARTIAL](
	[zID] VARCHAR(50),
	[zSTMPz] VARCHAR(50),
	[RefCode] VARCHAR(50),
	[RefName] VARCHAR(100),
	[TranNo] VARCHAR(50),
	[TranDate] DATETIME2(0) 
)
GO
'

     /*#*========== 🧩 PREPARE ==========*#*/	
		UNION SELECT [Category] = 'Lake Demo APP Views', [Seq] = 520, [Script] = 'USE #LAKE#;
GO
/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC #CORE#.[UTL].[FindX] ''%Target%'';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 10 * 
	FROM [APP].[Target_OVERLAP]

*/
CREATE VIEW [APP].[Target_OVERLAP]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/	
	
	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteFull AS (
		SELECT o.[zID]
		,CONCAT_WS(''+'', o.[RefCode], FORMAT(o.[TargetDate], ''yyyyMMdd'')) AS [BK_DE]
		,o.[TargetDate] AS [BK_Date]		
		FROM [APP].[Target_FULL] AS o
	)
	, ctePartial AS (
		SELECT o.[zID]
		, CONCAT_WS(''+'', o.[RefCode], FORMAT(o.[TargetDate], ''yyyyMMdd'')) AS [BK_DE]
		,o.[TargetDate] AS [BK_Date]
		FROM [APP].[Target_PARTIAL] AS o 
	)

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT cfg.[BK_SRC_APP] AS [BK_SRC]
		,o.[zID] AS [zID]
		,x.[zID] AS [zID_PARTIAL]
		,CONVERT(VARCHAR(200), CONCAT_WS(''+'', cfg.[BK_SRC_APP], o.[BK_DE])) AS [BK_DE]
		,CONVERT(VARCHAR(500), CONCAT_WS(''; '', ''Start Date: '' + FORMAT(cfg.[TargetStartDate], ''yyyy-MM-dd'')
								, ''End Date: '' + FORMAT(cfg.[TargetEndDate], ''yyyy-MM-dd'') )) AS [CA_Memo]
	FROM cteFull AS o
	LEFT JOIN ctePartial AS x ON o.[BK_DE] = x.[BK_DE]
	INNER JOIN [AAL].[Setting] AS cfg ON o.[BK_Date] BETWEEN cfg.[TargetStartDate] AND cfg.[TargetEndDate]



/*#*==================== 🔚 ====================*#*/
GO

/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC #CORE#.[UTL].[FindX] ''%Target%'';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 10 * 
	FROM [APP].[Target_QUERY]

*/
CREATE VIEW [APP].[Target_QUERY]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteParam AS (
		SELECT [Lake] = CONVERT(VARCHAR(100), DB_NAME())
			,[SchemaName] = o.[BK_SRC_APP]
			,[TableName] = CONVERT(VARCHAR(100), ''Target'')
			,[Source] = o.[BK_SRC_APP]
			,[QN_SourceTable] = CONVERT(VARCHAR(100), ''#CORE#.[SVC].[Sample_Target]'')
			,StartDateStr = FORMAT(o.[TargetStartDate], o.[DateStrFormat])
			,EndDateStr = FORMAT(o.[TargetEndDate], o.[DateStrFormat])
			,TimeStampStr = o.TimeStampStr
		FROM [AAL].[Setting] AS o
	)
	,cteQuery AS (
		SELECT o.*
			/*#*---------- 📌 DETAIL ----------*#*/
			,SourceTablePreparation = CONVERT(VARCHAR(4000), ''/*--No Preparation--*/'' )
			,SourceTableCondidtion = CONVERT(VARCHAR(4000), ''WHERE [TargetDate] BETWEEN ''''#START_DATE#'''' AND ''''#END_DATE#'''' '' )		
		FROM cteParam AS o
	)

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT x.[SchemaName] 
		,x.[TableName]
		,x.[QN_Table_FULL]
		,x.[QN_Table_PARTIAL]
		,x.[QN_Table_OVERLAP]
		,x.[QN_SourceTable]
		,x.[ValidationQuery]		
		,x.[IngestionQuery_FULL]
		,x.[IngestionQuery_PARTIAL]
		,x.[ExtractionQuery]
	FROM cteQuery AS o
	CROSS APPLY #CORE#.[UTL].[GetLakeQuery_PARTIAL](o.[Lake] ,o.[SchemaName], o.[TableName]
	,o.[Source], o.[QN_SourceTable], o.[SourceTablePreparation], o.[SourceTableCondidtion]
    ,o.[StartDateStr], o.[EndDateStr], o.[TimeStampStr]
    ) AS x

/*#*==================== 🔚 ====================*#*/
GO

/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC #CORE#.[UTL].[FindX] ''%Tran%'';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 10 * 
	FROM [APP].[TranDetail_OVERLAP]

*/
CREATE VIEW [APP].[TranDetail_OVERLAP]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/
	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteFull AS (
		SELECT o.[zID]
		, CONCAT_WS(''+'', o.[TranNo], o.[TranLineNo]) AS [BK_DE]
		FROM [APP].[TranDetail_FULL] AS o
	)
	, ctePartial AS (
		SELECT o.[zID]
		, CONCAT_WS(''+'', o.[TranNo], o.[TranLineNo]) AS [BK_DE]
		FROM [APP].[TranDetail_PARTIAL] AS o
	)
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT cfg.[BK_SRC_APP]
		,o.[zID] AS [zID]
		,x.[zID] AS [zID_PARTIAL]
		,CONCAT_WS(''+'', cfg.[BK_SRC_APP], o.[BK_DE]) AS [BK_DE]
		,o.[BK_DE] AS [CA_Memo]
	FROM cteFull AS o
	INNER JOIN ctePartial AS x ON o.[BK_DE] = x.[BK_DE]
	CROSS JOIN [AAL].[Setting] AS cfg

/*#*==================== 🔚 ====================*#*/
GO

/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC #CORE#.[UTL].[FindX] ''%Tran%'';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 10 * 
	FROM [APP].[TranDetail_QUERY]

*/
CREATE VIEW [APP].[TranDetail_QUERY]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteParam AS (
		SELECT [Lake] = CONVERT(VARCHAR(100), DB_NAME())
			,[SchemaName] = o.[BK_SRC_APP]
			,[TableName] = CONVERT(VARCHAR(100), ''TranDetail'')
			,[Source] = o.[BK_SRC_APP]
			,[QN_SourceTable] = CONVERT(VARCHAR(100), ''#CORE#.[SVC].[Sample_TranDetail]'')
			,StartDateStr = FORMAT(o.[TranStartDate], o.[DateStrFormat])
			,EndDateStr = FORMAT(o.[TranEndDate], o.[DateStrFormat])
			,TimeStampStr = o.TimeStampStr
		FROM [AAL].[Setting] AS o
	)
	,cteQuery AS (
		SELECT o.*
			/*#*---------- 📌 DETAIL ----------*#*/
			,SourceTablePreparation = CONVERT(VARCHAR(4000), ''; WITH x AS ( SELECT [TranNo],[TranDate] FROM #CORE#.[SVC].[Sample_TranHeader] AS o WHERE [TranDate] BETWEEN ''''#START_DATE#'''' AND ''''#END_DATE#'''' ) '' )
			,SourceTableCondidtion = CONVERT(VARCHAR(4000), ''INNER JOIN x ON o.[TranNo] = x.[TranNo]; '' )		
		FROM cteParam AS o
	)

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT x.[SchemaName] 
		,x.[TableName]
		,x.[QN_Table_FULL]
		,x.[QN_Table_PARTIAL]
		,x.[QN_Table_OVERLAP]
		,x.[QN_SourceTable]
		,x.[ValidationQuery]		
		,x.[IngestionQuery_FULL]
		,x.[IngestionQuery_PARTIAL]
		,x.[ExtractionQuery]
	FROM cteQuery AS o
	CROSS APPLY #CORE#.[UTL].[GetLakeQuery_PARTIAL](o.[Lake] ,o.[SchemaName], o.[TableName]
	,o.[Source], o.[QN_SourceTable], o.[SourceTablePreparation], o.[SourceTableCondidtion]
    ,o.[StartDateStr], o.[EndDateStr], o.[TimeStampStr]
    ) AS x

/*#*==================== 🔚 ====================*#*/
GO

/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC #CORE#.[UTL].[FindX] ''%Tran%'';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 10 * 
	FROM [APP].[TranHeader_OVERLAP]

*/
CREATE VIEW [APP].[TranHeader_OVERLAP]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteFull AS (
		SELECT o.[zID]
		, CONCAT_WS(''+'', o.[TranNo], NULL) AS [BK_DE]
		FROM [APP].[TranHeader_FULL] AS o		
	)
	, ctePartial AS (
		SELECT o.[zID]
		, CONCAT_WS(''+'', o.[TranNo], NULL) AS [BK_DE]
		FROM [APP].[TranHeader_PARTIAL] AS o
	)
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT cfg.[BK_SRC_APP]
		,o.[zID] AS [zID]
		,x.[zID] AS [zID_PARTIAL]
		,CONCAT_WS(''+'', cfg.[BK_SRC_APP], o.[BK_DE]) AS [BK_DE]
		,o.[BK_DE] AS [CA_Memo]
	FROM cteFull AS o
	INNER JOIN ctePartial AS x ON o.[BK_DE] = x.[BK_DE]
	CROSS JOIN [AAL].[Setting] AS cfg

/*#*==================== 🔚 ====================*#*/
GO

/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC #CORE#.[UTL].[FindX] ''%Tran%'';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 10 * 
	FROM [APP].[TranHeader_QUERY]

*/
CREATE VIEW [APP].[TranHeader_QUERY]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteParam AS (
		SELECT [Lake] = CONVERT(VARCHAR(100), DB_NAME())
			,[SchemaName] = o.[BK_SRC_APP]
			,[TableName] = CONVERT(VARCHAR(100), ''TranHeader'')
			,[Source] = o.[BK_SRC_APP]
			,[QN_SourceTable] = CONVERT(VARCHAR(100), ''#CORE#.[SVC].[Sample_TranHeader]'')
			,StartDateStr = FORMAT(o.[TranStartDate], o.[DateStrFormat])
			,EndDateStr = FORMAT(o.[TranEndDate], o.[DateStrFormat])
			,TimeStampStr = o.TimeStampStr
		FROM [AAL].[Setting] AS o
	)
	,cteQuery AS (
		SELECT o.*
			/*#*---------- 📌 DETAIL ----------*#*/
			,SourceTablePreparation = CONVERT(VARCHAR(4000), ''/*--No Preparation--*/'' )
			,SourceTableCondidtion = CONVERT(VARCHAR(4000), ''WHERE [TranDate] BETWEEN ''''#START_DATE#'''' AND ''''#END_DATE#'''' '' )		
		FROM cteParam AS o
	)

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT x.[SchemaName] 
		,x.[TableName]
		,x.[QN_Table_FULL]
		,x.[QN_Table_PARTIAL]
		,x.[QN_Table_OVERLAP]
		,x.[QN_SourceTable]
		,x.[ValidationQuery]		
		,x.[IngestionQuery_FULL]
		,x.[IngestionQuery_PARTIAL]
		,x.[ExtractionQuery]
	FROM cteQuery AS o
	CROSS APPLY #CORE#.[UTL].[GetLakeQuery_PARTIAL](o.[Lake] ,o.[SchemaName], o.[TableName]
	,o.[Source], o.[QN_SourceTable], o.[SourceTablePreparation], o.[SourceTableCondidtion]
    ,o.[StartDateStr], o.[EndDateStr], o.[TimeStampStr]
    ) AS x

/*#*==================== 🔚 ====================*#*/
GO
'
     

 ) /*END of CET*/

		SELECT o.[Category]
		,[Script] = REPLACE(REPLACE(o.[Script]
					,'#CORE#', ISNULL(@_QN_Core, x.[QN_Core]))
					,'#LAKE#', ISNULL(@_QN_Lake, x.[QN_Lake]))					
		,o.[Seq]
		FROM cteData AS o
		CROSS JOIN [UTL].[Setting] AS x
		ORDER BY o.[Seq], o.[Category]

		PRINT '/*---------- 🔼 Lake Creation Script ----------*/'
        
	

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [SVC].[Prune]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO















/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/
	EXEC [SVC].[FindX] '%Prune%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [SVC].[Prune];

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT * 
	FROM [UTL].[Log] AS o
	ORDER BY o.RunTime DESC

	-- TRUNCATE TABLE [UTL].[Log]

*/
CREATE PROC [SVC].[Prune]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/

	
	/*#*---------- 📄 PARAMETER ----------*#*/
	DECLARE @_UPD DATETIME2, @_REF_DATE DATETIME2, @_REF_DATE_BGN DATETIME2
	, @_REF_DATE_P0M DATETIME2, @_REF_DATE_P3M DATETIME2, @_REF_DATE_P6M DATETIME2, @_REF_DATE_P12M DATETIME2
	, @_REF_DATE_P10D DATETIME2, @_REF_DATE_P30D DATETIME2, @_REF_DATE_P60D DATETIME2, @_REF_DATE_P120D DATETIME2;
	SELECT TOP 1 @_UPD = o.[CurrentTime]	,@_REF_DATE = o.[CurrentDate] FROM [UTL].[Variable] AS o;

	/*#*---------- 📄 PARAMETER ----------*#*/
	SET @_REF_DATE_P0M = DATEADD(MONTH, DATEDIFF(MONTH, 0, @_REF_DATE), 0);
	SET @_REF_DATE_P3M = DATEADD(MONTH, -3,  @_REF_DATE_P0M);
	SET @_REF_DATE_P6M = DATEADD(MONTH, -6,  @_REF_DATE_P0M);
	SET @_REF_DATE_P12M = DATEADD(MONTH, -12,  @_REF_DATE_P0M);
	SET @_REF_DATE_BGN = DATEADD(MONTH, -60,  @_REF_DATE_P0M); /*--Begin of 60M10D*/;
	
	/*#*---------- 📄 PARAMETER ----------*#*/
	SET @_REF_DATE_P10D = DATEADD(DAY, -10, @_REF_DATE);
	SET @_REF_DATE_P30D = DATEADD(DAY, -30, @_REF_DATE);
	SET @_REF_DATE_P60D = DATEADD(DAY, -60,  @_REF_DATE_P0M);
	SET @_REF_DATE_P120D = DATEADD(DAY, -120,  @_REF_DATE_P0M);

	--SELECT @_UPD, @_REF_DATE,@_REF_DATE_P0M,@_REF_DATE_P3M,@_REF_DATE_P6M,@_REF_DATE_P12M,@_REF_DATE_PDM
	--,@_REF_DATE_P10D, @_REF_DATE_P30D,@_REF_DATE_P60D,@_REF_DATE_P120D

	/*#*---------- ♻️ EMPTY ----------*#*/
	DELETE FROM [UTL].[Log] WHERE RunTime < @_REF_DATE_P10D; 
	

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [SVC].[Validate]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/	
	EXEC [SVC].[FindX] 'SVC%', 'Proc';


	/*#*---------- 🧪 VALIDATION ----------*#*/
	EXEC [SVC].[Validate];


*/
CREATE PROC [SVC].[Validate]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Orignal job or schedueler}*_*/ 
    ,@Mode varchar(10) = 'EXE' /*_*{Parameter},{@Mode},{Print or Exec}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	
	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_UPD DATETIME2, @_UPD_Str VARCHAR(50);
	SELECT TOP 1 @_UPD = DATEADD(HOUR, -2, o.[CurrentTime])
	FROM [UTL].[Variable] AS o ;
	SET @_UPD_Str = FORMAT(@_UPD, 'yyyy-MM-dd HH:mm');	

	/*#*---------- 📄 PARAMETER ----------*#*/
	DECLARE @_View_Script VARCHAR(1000), @_Table_Script VARCHAR(1000);
	SET @_View_Script =  'SELECT [BK_DE] = ''#TABLE#''
,[Status] = CASE WHEN COUNT(*) > 0 THEN ''Success'' ELSE ''Failure''END
,[Result] = ''Rows: '' + FORMAT(COUNT(*), ''N0'') 
FROM #TABLE#';
	SET @_Table_Script = 'SELECT [BK_DE] = ''#TABLE#''
,[Status] = CASE WHEN MAX([zUPD]) > ''#UPD#'' THEN ''Success'' ELSE ''Failure''END 
,[Result] = ''Rows: '' + FORMAT(COUNT(*), ''N0'')+ ''; zUPD: '' + FORMAT(MAX([zUPD]), ''yyyy-MM-dd HH:mm'') 
FROM #TABLE#'; 
	
	/*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @_Result TABLE ([BK_DE] VARCHAR(200), [Status] VARCHAR(50), [Result] VARCHAR(100), [Script] VARCHAR(1000) );
    DECLARE @_BK_DE VARCHAR(1000), @_Script VARCHAR(1000);
    /*#*========== 🧩 PREPARE ==========*#*/
	
	
    DECLARE curDB CURSOR LOCAL FAST_FORWARD FOR 
    SELECT o.[BK_DE]
	    ,[Script] = REPLACE(REPLACE( CASE WHEN o.[TableType] = 'View' THEN @_View_Script ELSE @_Table_Script END
						    , '#TABLE#', o.[BK_DE])
						    , '#UPD#', @_UPD_Str)
	FROM [SVC].[Meta_Table] AS o
	WHERE o.[DatabaseCode] = 'Core'


	/*#*========== ✅ ACTION ==========*#*/
    OPEN curDB;
    FETCH NEXT FROM curDB INTO @_BK_DE, @_Script;

    WHILE @@FETCH_STATUS = 0
    BEGIN
            IF (@Mode = 'EXE')
            BEGIN
				INSERT @_Result([BK_DE], [Status], [Result])
				EXEC(@_Script);
				
				UPDATE @_Result
				SET [Script] = @_Script
				WHERE [BK_DE] = @_BK_DE

				PRINT '/*---------- 🔼 Validated : ' + @_BK_DE + ' ----------*/'
            END
            ELSE
            BEGIN
                PRINT @_Script;
            END

            FETCH NEXT FROM curDB INTO @_BK_DE, @_Script;
    END

	/*#*---------- 🧹 CLEANUP ----------*#*/
    CLOSE curDB;
    DEALLOCATE curDB;

	SELECT o.[Status], o.[BK_DE], o.[Result], o.[Script]
	FROM @_Result AS o
	ORDER BY o.[Status], o.[BK_DE]
END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [UTL].[0DB_Backup]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/
	EXEC [SVC].[FindX] '%Backup%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/
    EXEC [UTL].[0DB_Backup] 'EXE';

	/*#*---------- 🧪 VALIDATION ----------*#*/

*/
CREATE PROC [UTL].[0DB_Backup] 
    @Mode varchar(10) = 'EXE' /*_*{Parameter},{@Mode},{Print or Exec}*_*/
AS
BEGIN	
    /*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_DB VARCHAR(50), @_DateString VARCHAR(50), @_Folder  VARCHAR(100), @_File VARCHAR(200), @_SQLT VARCHAR(500), @_SQL VARCHAR(500);     
	SET @_SQLT = 'BACKUP DATABASE #DB# TO DISK = ''#FOLDER#\#DB#_#DATE#.bak'' WITH INIT, COMPRESSION, CHECKSUM, STATS = 10;'
    SET @_Folder = N'C:\zVIN\_V9\DB';
    SET  @_DateString = CONVERT(CHAR(8), GETDATE(), 112); -- e.g. _20251216
    SET @_File = @_Folder + '' + @_DateString;
    
    /*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE aCursor CURSOR FOR
    SELECT [name] AS DB FROM SYS.DATABASES WHERE ([name] LIKE 'V90%'); 

	/*#*========== ✅ ACTION ==========*#*/    
    OPEN aCursor;
    FETCH NEXT FROM aCursor INTO @_DB;
    WHILE @@FETCH_STATUS = 0
    BEGIN
            SET @_SQL = REPLACE(REPLACE(REPLACE(@_SQLT, '#DB#', @_DB), '#FOLDER#', @_Folder) , '#DATE#', @_DateString);
            PRINT @_SQL;
            IF (@Mode = 'EXE')
            BEGIN
                EXEC(@_SQL);
            END
            FETCH NEXT FROM aCursor INTO @_DB;
    END

	/*#*---------- 🧹 CLEANUP ----------*#*/
    CLOSE aCursor;
    DEALLOCATE aCursor;



END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [UTL].[AddLog]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO














/*
    /*#*---------- 🔍 EXAMPLE ----------*#*/
	EXEC [SVC].[FindX] '%Log%', 'Proc';

	EXEC [UTL].[AddLog] 'MAIN*240905121314', '[UTL].[AddLog]','Data Hub Refresh';
	EXEC [UTL].[AddLog] 'MAIN*240905121314', '[UTL].[AddLog]','Data Hub Refresh', 'FAB59EF2-2A5B-4ABC-8CCB-4AF2F46F512A';

	/*#*---------- 🧪 VALIDATION ----------*#*/

    SELECT * 
	FROM [UTL].[Log]
    WHERE [System] = 'V9'
	ORDER BY RunTime DESC
	
    -- TRUNCATE TABLE [UTL].[Log];

*/
CREATE PROC [UTL].[AddLog]
    @Controller VARCHAR(500)/*_*{Parameter},{@Controller},{Orignal job or schedueler}*_*/    
	,@Action VARCHAR(500)/*_*{Parameter},{@Action},{Current process}*_*/	
    ,@Message VARCHAR(500)/*_*{Parameter},{@Message},{The message stored}*_*/
	,@ID VARCHAR(50) = NULL /*_*{Parameter},{@Action},{GUID for Log}*_*/
	,@ID_Paired VARCHAR(50) = NULL /*_*{Parameter},{@ID_Paired},{Paired Log Entry GUID}*_*/
	,@Tag VARCHAR(200) = NULL /*_*{Parameter},{@Action},{Tag}*_*/   
	,@Component VARCHAR(200) = NULL /*_*{Parameter},{@Action},{Tag}*_*/
AS
BEGIN
	SET NOCOUNT ON;	
	/*#*========== 🎯 PURPOSE ==========*#*/
    DECLARE @_ID VARCHAR(50),@_ID_Paired VARCHAR(50), @_User VARCHAR(200), @_RunTime datetime2(3), @_RunTime_UTC datetime2(3), @_Tag_Seed VARCHAR(50), @_Tag_Left VARCHAR(50), @_Tag_Right VARCHAR(50)
	, @_System VARCHAR(500), @_Status VARCHAR(50), @_Message VARCHAR(500), @_Detail VARCHAR(4000), @_Left INT, @_Right INT
	,@_Component VARCHAR(500),@_Controller VARCHAR(500), @_Action VARCHAR(500), @_UPD DATETIME2(3);

    /*#*---------- 📄 PARAMETER ----------*#*/
	SET @_ID = CASE WHEN TRY_CAST(@ID AS UNIQUEIDENTIFIER) IS NOT NULL THEN @ID
								ELSE NEWID() END;
	SET @_ID_Paired = CASE WHEN TRY_CAST(@ID_Paired AS UNIQUEIDENTIFIER) IS NOT NULL THEN @ID_Paired
								ELSE @_ID END; --Duplicate the @_ID

	/*#*---------- 📄 PARAMETER ----------*#*/
    SET @_User = CURRENT_USER; /*CURRENT_USER or SUSER_SNAME() */	
	SET @_Component = CASE WHEN ISNULL(@Component, '') = '' THEN 'Warehouse' ELSE TRIM(@Component) END;
	
    SELECT @_System = o.[System]
	, @_RunTime_UTC = o.[UTC_Time]
    , @_RunTime = o.[CurrentTime]
	, @_UPD = o.[CurrentTime]
	FROM [UTL].[Setting] AS o;
	 	
	/*#*---------- 📄 PARAMETER ----------*#*/
	SET @_Left = 10;
	SET @_Right = 20;
	SET @_Tag_Seed = ISNULL(@Tag, '');
    SET @_Tag_Left = CASE WHEN @_Tag_Seed <> '' THEN LEFT(REPLICATE(@_Tag_Seed, @_Left), @_Left)
									ELSE '' END
	SET @_Tag_Right = CASE WHEN @_Tag_Seed <> '' THEN LEFT(REPLICATE(@_Tag_Seed, @_Right), @_Right)
									ELSE '' END
	SET @_Status = CASE WHEN CHARINDEX('Error', @Message) > 0 THEN 'Failed' ELSE 'Completed' END;
	SET @_Message = CASE WHEN ISNULL(@Message,'') = '' THEN 'No Messages'
								    ELSE @_Tag_Left + @Message + @_Tag_Right
									END;
						
	/*#*---------- 📄 PARAMETER ----------*#*/	
	SET @_Detail = 'N.A.';
	SET @_Controller = CASE WHEN ISNULL(@Controller,'') = '' THEN  'Ad-hoc*' + FORMAT(GETDATE(), 'HHmmss')  ELSE @Controller END;
	SET @_Action = CASE WHEN ISNULL(@Action, '') = '' THEN 'Unknown' ELSE @Action END;

	/*#*========== ✅ ACTION ==========*#*/	
    INSERT [UTL].[Log]([zID]
		,[ID_Paired]
		,[System]
		,[Component]
		,[Controller]
		,[Action]
		,[RunBy]
		,[RunTime]
		,[RunTime_UTC]
		,[Status]
		,[Message]
		,[Detail]
		,[zUPD]
    )
    SELECT @_ID
		,@_ID_Paired
	    ,@_System
        ,@_Component
        ,@_Controller
        ,@_Action
        ,@_User
        ,@_RunTime
        ,@_RunTime_UTC
        ,@_Status
        ,@_Message
		,@_Detail
		,@_UPD

	/*#*---------- 🧹 CLEANUP ----------*#*/

END
/*#*==================== 🔚 ====================*#*/

GO
/****** Object:  StoredProcedure [UTL].[AddPlaceholder]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO















/*
    /*#*---------- 🔍 EXAMPLE ----------*#*/
	EXEC [SVC].[FindX] '%Placeholder%', 'Proc';

	EXEC [UTL].[AddPlaceholder] 'Ad-hoc', '[MRT].[_TPL_REF]','[UN]';
	EXEC [UTL].[AddPlaceholder] 'Ad-hoc', '[MRT].[_TPL_REF]','[NA-CUST]', 'NA';

	EXEC [UTL].[AddPlaceholder] 'Ad-hoc', '[MRT].[_TPL_REF]','[UN]', '', 'PRT';
	
	/*#*---------- 🧪 VALIDATION ----------*#*/

    SELECT * 
	FROM [MRT].[_TPL_REF]

*/
CREATE PROC [UTL].[AddPlaceholder]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Orignal job or schedueler}*_*/
	,@Table varchar(500)/*_*{Parameter},{@Table},{Table Full Name}*_*/	
	,@BK varchar(100) /*_*{Parameter},{@Message},{BK_DE of Placeholder, UN, N.A. or OTH }*_*/
	,@BK_REF varchar(100) = '' /*_*{Parameter},{@Message},{BK_DE_REF of Placeholder, UN, N.A. or OTH }*_*/
    ,@Mode VARCHAR(500) = 'EXE' /*_*{Parameter},{@Mode},{PRT and EXE}*_*/
AS
BEGIN
	SET NOCOUNT ON;	
	/*#*========== 🎯 PURPOSE ==========*#*/
    
    /*#*---------- 📄 PARAMETER ----------*#*/
	DECLARE @_SQLT VARCHAR(8000), @_SQL VARCHAR(8000), @_Column VARCHAR(8000), @_Value VARCHAR(8000)
	,@_DB VARCHAR(100),@_BK_Table VARCHAR(100),@_QN_SchemaTable VARCHAR(100), @_BK_DE VARCHAR(100), @_BK_REF VARCHAR(100), @_Code_REF VARCHAR(100), @_Name_REF VARCHAR(100);
	SET @_SQLT = 'DELETE #TABLE# WHERE [BK_DE] = ''#BK_DE#''; 
	INSERT #TABLE# (#COLUMN#) 
	VALUES (#VALUE#); ';
	SET @_DB = DB_NAME();
	SET @_QN_SchemaTable = @Table;

	/*#*---------- 📄 PARAMETER: UN ----------*#*/
	SET @_BK_DE = @BK;
	SET @_BK_REF = CASE WHEN ISNULL(@BK_REF, '') = '' THEN @_BK_DE ELSE @BK_REF END;

	/*#*---------- 📄 PARAMETER: UN ----------*#*/
	IF (@_BK_REF IN ('UN', '[UN]'))
		BEGIN			
			SET @_Code_REF = '[UN]';
			SET @_Name_REF = 'UNKNOWN'			
		END
	/*#*---------- 📄 PARAMETER: NA ----------*#*/
	ELSE IF (@_BK_REF IN ('NA', '[NA]', 'N.A.'))
		BEGIN			
			SET @_Code_REF = '[NA]';
			SET @_Name_REF = 'N.A.'
		END
	ELSE
		BEGIN			
			SET @_Code_REF = @_BK_REF;
			SET @_Name_REF = @_BK_REF;
		END

	/*#*========== 🧩 PREPARE ==========*#*/
	;WITH cteData AS (
		SELECT [ColumnName]
			,[ColumnType]
			,[ColumnSeq]
			,[BK_Table]		
		FROM [SVC].[Meta_Column] AS o
		WHERE [DatabaseName] = @_DB AND [TableType] = 'Table'
		AND [QN_SchemaTable] = @_QN_SchemaTable
	)
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT @_Column = LEFT(STRING_AGG(CONVERT(VARCHAR(MAX), '[' + o.[ColumnName] + ']' ), ',') WITHIN GROUP (ORDER BY o.[ColumnSeq]),8000)
	, @_Value = LEFT(STRING_AGG(CONVERT(VARCHAR(MAX)
						, CASE WHEN o.[ColumnName] = 'zID' THEN 'NEWID()'
									WHEN o.[ColumnName] = 'zUPD' THEN 'GETDATE()'
									WHEN o.[ColumnName] = 'BK_SRC' THEN '''PLH'''
									WHEN o.[ColumnName] = 'BK_DE' THEN '''#BK_DE#'''
									/*#*---------- 📌 DETAIL ----------*#*/
									WHEN o.[ColumnName] = 'CA_zFlag' THEN '''-100'''
									WHEN o.[ColumnName] = 'CA_zStatus' THEN '''Valid'''
									WHEN o.[ColumnName] = 'CA_zMemo' THEN '''Placeholder'''
									WHEN o.[ColumnName] = 'CA_zLock' THEN '''*'''
									WHEN o.[ColumnName] = 'CX_DE' THEN 'NULL'									
									/*#*---------- 📌 DETAIL ----------*#*/
									WHEN o.[ColumnType] IN ('varchar') AND CHARINDEX('BK_', o.[ColumnName]) > 0  THEN '''' + @_BK_REF + ''''
									WHEN o.[ColumnType] IN ('varchar') AND CHARINDEX('Code', o.[ColumnName]) > 0  THEN '''' + @_Code_REF + ''''
									WHEN o.[ColumnType] IN ('varchar') AND CHARINDEX('Name', o.[ColumnName]) > 0  THEN '''' + @_Name_REF + ''''									
									/*#*---------- 📌 DETAIL ----------*#*/
									WHEN o.[ColumnType] IN ('varchar') THEN ''''''
									WHEN o.[ColumnType] IN ('datetime', 'datetime2') THEN '''2000-01-01'''
									WHEN o.[ColumnType] IN ('int', 'smallint') THEN '''0'''
									WHEN o.[ColumnType] IN ('decimal', 'numeric') THEN '''0'''
						  ELSE 'NULL' END
						), ',') WITHIN GROUP (ORDER BY o.[ColumnSeq]), 8000)
	,@_BK_Table = MAX([BK_Table])
	FROM cteData AS o
	WHERE 1=1; 


	/*#*========== ✅ OUTPUT ==========*#*/
	EXEC [UTL].[ReplaceX] @_SQL OUTPUT, @_SQLT
	,'#TABLE#' , @_BK_Table
	,'#COLUMN#' , @_Column
	,'#VALUE#' , @_Value
	,'#BK_DE#' , @_BK_DE
	;


	/*#*========== ✅ ACTION ==========*#*/
    IF (@Mode = 'EXE')
    BEGIN
        EXEC(@_SQL);        
		PRINT '/*---------- ⏏️ Inserted Placehoder: ' + @_BK_Table + ' -- ' + @_BK_DE + ' ----------*/'
    END
    ELSE
    BEGIN
        PRINT @_SQL;
    END

	/*#*========== ✅ ACTION ==========*#*/	
    

	/*#*---------- 🧹 CLEANUP ----------*#*/

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [UTL].[EmptyTable]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



















/*
     /*#*---------- 🔍 EXAMPLE ----------*#*/
	EXEC [SVC].[FindX] '%Empty%', 'Proc';

	EXEC [UTL].[EmptyTable] 'Ad-hoc',  '[UTL].[Log]', '','PRT';
    EXEC [UTL].[EmptyTable] 'Ad-hoc',  '[UTL].[Log]', ' RunTime <= ''2026-02-20'' ','PRT';
	EXEC [UTL].[EmptyTable] 'Ad-hoc',  '[UTL].[Log]', ' RunTime <= ''2026-02-20'' ','EXE';
    EXEC [UTL].[EmptyTable] 'Ad-hoc',  '[UTL].[Log]', '','EXE';
    EXEC [UTL].[EmptyTable] 'Ad-hoc', '[V90_Hub]', '[ZH].[Demo]', '1=1','EXE';

	/*#*---------- 🧪 VALIDATION ----------*#*/

	SELECT TOP 100 * 
	FROM [UTL].[Log]
    ORDER BY 1,2,3
    
    UPDATE  [UTL].[Log] 
    SET RunTime = '2026-01-01' 
    WHERE zID = '197DC46B-CDDA-4477-A4DA-6D7249D042DC'

*/
CREATE PROC [UTL].[EmptyTable]
    @Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
    ,@QN_Table varchar(500)/*_*{Parameter},{@QN_Table},{Table Full Name}*_*/    	
    ,@Condition varchar(500) = '' /*_*{Parameter},{@Condition},{Condition}*_*/    
    ,@Mode varchar(10) = 'EXE' /*_*{Parameter},{@Mode},{Print or Exec}*_*/
AS
BEGIN
	SET NOCOUNT ON;
    /*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_DB VARCHAR(100), @_Schema VARCHAR(100), @_Table VARCHAR(100), @_TableFullName VARCHAR(500), @_Condition VARCHAR(500), @_OP VARCHAR(100), @_SQLT VARCHAR(500), @_SQL VARCHAR(8000);        
	/*#*---------- 📄 PARAMETER ----------*#*/
    SET @_SQLT = '#OP# #TABLE# #CONDITION#;'

    /*#*---------- 📄 PARAMETER ----------*#*/
    SET @_DB = DB_NAME();
    SET @_Schema = PARSENAME(@QN_Table, 2);
	SET @_Table = PARSENAME(@QN_Table, 1);
    SET @_TableFullName = CONCAT_WS('.', QUOTENAME(@_DB), QUOTENAME(@_Schema), QUOTENAME(@_Table));

    SET @_Condition = CASE WHEN ISNULL(@Condition, '') <> '' THEN ' WHERE ' + TRIM(@Condition)  + ' '
                                    ELSE '' END;
    SET @_OP = CASE WHEN @_Condition = '' THEN 'TRUNCATE TABLE'
                                    ELSE 'DELETE ' END;

    /*#*---------- 📄 PARAMETER ----------*#*/    
    SET @_SQL = REPLACE(REPLACE(REPLACE(@_SQLT
                        , '#OP#', @_OP)
                        , '#TABLE#', @_TableFullName)
                        , '#CONDITION#', @_Condition);
    

	/*#*========== ✅ ACTION ==========*#*/
    IF (@Mode = 'EXE')
        BEGIN
            EXEC(@_SQL);        
		    PRINT '/*---------- 🔽 Emptied: ' + @_TableFullName + ' -- ' + CASE WHEN @_Condition = '' THEN 'Truncate' ELSE 'Delete' END + ' ' + @_Condition + ' ----------*/'
        END
    ELSE
        BEGIN
            PRINT @_SQL;
        END
    
    /*#*---------- 🧹 CLEANUP ----------*#*/

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [UTL].[GetLog]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO















/*
    /*#*---------- 🔍 EXAMPLE ----------*#*/
	EXEC [SVC].[FindX] '%Log%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/
    EXEC [UTL].[GetLog];

    EXEC [UTL].[GetLog] 'Ad-hoc';
    EXEC [UTL].[GetLog] 'SVC', 2;

    SELECT * FROM [UTL].[Log]

    -- TRUNCATE TABLE [UTL].[Log]

*/
CREATE PROC [UTL].[GetLog]
    @Keyword VARCHAR(500) = NULL /*_*{Parameter},{@Keyword},{Keywords for search}*_*/
    ,@Offset SMALLINT = 1 /*_*{Parameter},{@Offset},{Day offset}*_*/
AS
BEGIN
	SET NOCOUNT ON;	
	/*#*========== 🎯 PURPOSE ==========*#*/
    
    /*#*---------- 📄 PARAMETER ----------*#*/
	DECLARE @_Keyword VARCHAR(500);
    SET @_Keyword = CASE WHEN ISNULL(@Keyword, '') IN ('', '*') THEN '*' ELSE TRIM(@Keyword) END;


	/*#*========== ✅ OUTPUT ==========*#*/	
    SELECT TOP 100 o.[System]
      ,o.[Controller]
      ,o.[Action]      
      ,o.[RunTime]
      ,o.[Message]      
  FROM [UTL].[Log] AS o
  WHERE o.[RunTime] BETWEEN DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()) - @Offset, 0) AND  GETDATE()
       AND ( @_Keyword = '*'
      OR o.[Controller] LIKE '%' + @_Keyword + '%'
      OR o.[Action] LIKE '%' + @_Keyword + '%'
      )
  ORDER BY o.[RunTime] DESC

END
/*#*==================== 🔚 ====================*#*/

GO
/****** Object:  StoredProcedure [UTL].[RemoveDuplication]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO












/*
    /*#*---------- 🔍 EXAMPLE ----------*#*/
	EXEC [SVC].[FindX] '%Duplication%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/
    EXEC [UTL].[RemoveDuplication] 'Ad-hoc', '[UTL].[Column]','PRT';
	EXEC [UTL].[RemoveDuplication] 'Ad-hoc', '[UTL].[Column]','EXE';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 100 * 
    -- SELECT COUNT(*)
	FROM [UTL].[Column]

*/
CREATE PROC [UTL].[RemoveDuplication]
    @Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
    ,@QN_Table varchar(500)/*_*{Parameter},{@QN_Table},{Table Full Name}*_*/    	
    ,@Mode varchar(10) = 'EXE' /*_*{Parameter},{@Mode},{Print or Exec}*_*/
AS
BEGIN
	SET NOCOUNT ON;    
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_DB VARCHAR(100),@_Schema VARCHAR(100),@_Table VARCHAR(100),@_TableFullName VARCHAR(500),@_SQLT VARCHAR(8000), @_SQL VARCHAR(8000);

	/*#*---------- 📄 PARAMETER ----------*#*/
    SET @_SQLT = 'WITH x AS ( SELECT [zID], ROW_NUMBER() OVER (PARTITION BY [BK_DE] ORDER BY [zUPD] DESC, [zID]) AS n FROM #TABLE#)
            DELETE FROM x WHERE n > 1;'

    SET @_DB = DB_NAME();
    SET @_Schema = PARSENAME(@QN_Table, 2);
	SET @_Table = PARSENAME(@QN_Table, 1);
    SET @_TableFullName = CONCAT_WS('.', QUOTENAME(@_DB), QUOTENAME(@_Schema), QUOTENAME(@_Table));

    SET @_SQL = REPLACE(@_SQLT, '#TABLE#', @_TableFullName);            
    IF (@Mode = 'EXE')
        BEGIN
            EXEC(@_SQL);
            PRINT '/*---------- ⏫ Duplication Removed: ' + @_TableFullName + ' ----------*/'
        END
    ELSE
        BEGIN
            PRINT @_SQL;
        END
    
    /*#*---------- 🧹 CLEANUP ----------*#*/

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [UTL].[ReplaceX]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





















/*
   /*#*---------- 🔍 EXAMPLE ----------*#*/
	EXEC [SVC].[FindX] '%Replace%', 'Proc';

   /*#*---------- 🧪 VALIDATION ----------*#*/
    DECLARE @_Result VARCHAR(500);
    EXEC [UTL].[ReplaceX] @_Result OUTPUT, 'SELECT #COLUMN# FROM #DB#.#SCHEMA#.#TABLE# '
    , '#DB#', 'T1'
    , '#SCHEMA#', 'S1'
    , '#TABLE#', 'S1'    
    , '#COLUMN#', 'C1'
    SELECT @_Result

    
	

*/
CREATE PROC [UTL].[ReplaceX]
    @OutputString NVARCHAR(MAX) OUTPUT /*_*{Parameter},{@OutputString},{Output string}*_*/
	,@InputString NVARCHAR(MAX) /*_*{Parameter},{@InputString},{Input string}*_*/
    ,@Find1 NVARCHAR(MAX) = NULL, @Replace1 NVARCHAR(MAX) = NULL
    ,@Find2 NVARCHAR(MAX) = NULL, @Replace2 NVARCHAR(MAX) = NULL
    ,@Find3 NVARCHAR(MAX) = NULL, @Replace3 NVARCHAR(MAX) = NULL
    ,@Find4 NVARCHAR(MAX) = NULL, @Replace4 NVARCHAR(MAX) = NULL
    ,@Find5 NVARCHAR(MAX) = NULL, @Replace5 NVARCHAR(MAX) = NULL
    ,@Find6 NVARCHAR(MAX) = NULL, @Replace6 NVARCHAR(MAX) = NULL
    ,@Find7 NVARCHAR(MAX) = NULL, @Replace7 NVARCHAR(MAX) = NULL
    ,@Find8 NVARCHAR(MAX) = NULL, @Replace8 NVARCHAR(MAX) = NULL
    ,@Find9 NVARCHAR(MAX) = NULL, @Replace9 NVARCHAR(MAX) = NULL
    ,@Find10 NVARCHAR(MAX) = NULL, @Replace10 NVARCHAR(MAX) = NULL
AS
BEGIN
	SET NOCOUNT ON;    
	/*#*========== 🎯 PURPOSE ==========*#*/

    /*#*---------- 📄 PARAMETER ----------*#*/
    DECLARE @Result NVARCHAR(MAX) = @InputString;

	/*#*========== ✅ ACTION ==========*#*/
    IF @Find1 IS NOT NULL SET @Result = REPLACE(@Result, @Find1, ISNULL(@Replace1,''));
    IF @Find2 IS NOT NULL SET @Result = REPLACE(@Result, @Find2, ISNULL(@Replace2,''));
    IF @Find3 IS NOT NULL SET @Result = REPLACE(@Result, @Find3, ISNULL(@Replace3,''));
    IF @Find4 IS NOT NULL SET @Result = REPLACE(@Result, @Find4, ISNULL(@Replace4,''));
    IF @Find5 IS NOT NULL SET @Result = REPLACE(@Result, @Find5, ISNULL(@Replace5,''));
    IF @Find6 IS NOT NULL SET @Result = REPLACE(@Result, @Find6, ISNULL(@Replace6,''));
    IF @Find7 IS NOT NULL SET @Result = REPLACE(@Result, @Find7, ISNULL(@Replace7,''));
    IF @Find8 IS NOT NULL SET @Result = REPLACE(@Result, @Find8, ISNULL(@Replace8,''));
    IF @Find9 IS NOT NULL SET @Result = REPLACE(@Result, @Find9, ISNULL(@Replace9,''));
    IF @Find10 IS NOT NULL SET @Result = REPLACE(@Result, @Find10, ISNULL(@Replace10,''));

    SET @OutputString = @Result;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [UTL].[SeedCalendar]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO















/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/
	EXEC [SVC].[FindX] '%Calendar%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/
    EXEC [UTL].[SeedCalendar];
	EXEC [UTL].[UpdateCalendar];

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 100 * 
	-- SELECT COUNT(*)
	FROM [UTL].[Calendar] AS o
	WHERE o.DateKey BETWEEN '2025-05-01' AND '2025-07-30' 
	ORDER BY o.DateKey

	-- TRUNCATE TABLE [UTL].[Calendar]

*/
CREATE PROC [UTL].[SeedCalendar]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/	

	/*#*---------- 📄 PARAMETER ----------*#*/
	DECLARE @_Time DATETIME, @_Date DATETIME, @_FinancialYear DATETIME, @_Lag SMALLINT;
	SET @_Time = GETDATE() AT TIME ZONE 'UTC' AT TIME ZONE 'Cen. Australia Standard Time'	;
	SET @_Date = DATEADD(DAY, DATEDIFF(DAY, 0, @_Time), 0);

	
	/*#*---------- ♻️ EMPTY ----------*#*/
	TRUNCATE TABLE [UTL].[Calendar];

	DECLARE @_StartDate DATE, @_EndDate DATE;
	SET @_StartDate = '2025-01-01';
	SET @_EndDate = '2026-12-31';

	/*#*========== 🧩 PREPARE ==========*#*/
    WITH DateSequence AS (
   		SELECT @_StartDate AS [Date]
   		UNION ALL
   		SELECT DATEADD(DAY, 1, [Date])
   		FROM DateSequence
   		WHERE [Date] < @_EndDate
	)

	/*#*========== ✅ ACTION ==========*#*/
	INSERT [UTL].[Calendar] ([zID],[zUPD],[DateInt]
	  ,[DateStr]
      ,[DateKey]
      ,[DateName]
      ,[DateFullName]
      ,[YearKey]
      ,[HalfYearKey]
      ,[QuarterKey]
      ,[MonthKey]
      ,[WeekKey]
      ,[WeekOfYearKey]
      ,[FinancialYearKey]
      ,[FinancialYearKey_April]
	  
	  )
	SELECT NEWID() AS [zID], GETDATE() AS [zUPD]
		,CONVERT(INT, FORMAT([Date], 'yyyyMMdd')) AS [DateInt]
		,FORMAT([Date], 'yyyy-MM-dd') AS [DateStr]
		,[Date] AS [DateKey]
		,FORMAT([Date], 'dd/MM/yyyy') AS [DateName]
		,UPPER(FORMAT([Date], 'ddd dd/MM/yyyy')) AS [DateFullName]      
		,DATEFROMPARTS(YEAR([Date]), 1, 1) AS [YearKey]
		,CASE WHEN MONTH([Date]) <= 6 THEN DATEFROMPARTS(YEAR([Date]), 1, 1)
			ELSE DATEFROMPARTS(YEAR([Date]), 7, 1)
			END AS  [HalfYearKey]
		,DATEFROMPARTS(YEAR([Date]), ((DATEPART(QUARTER, [Date]) - 1) * 3) + 1, 1) AS [QuarterKey]
		,DATEFROMPARTS(YEAR([Date]), MONTH([Date]), 1) AS [MonthKey]      
      ,DATEADD(DAY, 1 - DATEPART(WEEKDAY, DATEADD(DAY, -1, [Date])), [Date]) AS [WeekKey]
      ,DATEPART(ISOWK, [Date]) AS [WeekOfYearKey]      
      ,CASE WHEN MONTH([Date]) >= 7 THEN DATEFROMPARTS(YEAR([Date]), 7, 1)
        	 ELSE DATEFROMPARTS(YEAR([Date])-1, 7, 1) END AS [FinancialYearKey]
      ,CASE WHEN MONTH([Date]) >= 4 THEN DATEFROMPARTS(YEAR([Date]), 4, 1)
        	 ELSE DATEFROMPARTS(YEAR([Date])-1, 4, 1) END [FinancialYearKey_April]
	FROM DateSequence AS o	
	OPTION (MAXRECURSION 0);

	/*#*========== ✅ ACTION ==========*#*/
	UPDATE [UTL].[Calendar]
	SET [FinancialQuarterKey] = [QuarterKey]
	,[FinancialPeriod_January] = 'FY' + FORMAT([MonthKey], 'yyyy-MM')
	

	/*#*========== ✅ ACTION ==========*#*/
	UPDATE [UTL].[Calendar]
	SET [DayOfWeekKey] = DATEDIFF(DAY, [WeekKey], [DateKey]) + 1
	,[DayOfMonthKey] = DATEDIFF(DAY, [MonthKey], [DateKey]) + 1
	,[DayOfYearKey] = DATEDIFF(DAY, [YearKey], [DateKey]) + 1
	,[DayOfHalfYearKey] = DATEDIFF(DAY, [HalfYearKey], [DateKey]) + 1
	,[DayOfQuarterKey] = DATEDIFF(DAY, [QuarterKey], [DateKey]) + 1
	,[DayOfFinancialQuarterKey] = DATEDIFF(DAY, [FinancialQuarterKey] , [DateKey]) + 1
	,[MonthOfYearKey] = DATEDIFF(MONTH, [YearKey] , [MonthKey]) + 1
	,[MonthOfQuarterKey] = DATEDIFF(MONTH, [QuarterKey] , [MonthKey]) + 1
	,[MonthOfFinancialQuarterKey] = DATEDIFF(MONTH, [FinancialQuarterKey] , [MonthKey]) + 1
	,[MonthOfFinancialYearKey] = DATEDIFF(MONTH, [FinancialYearKey] , [MonthKey]) + 1
	,[MonthOfFinancialYearKey_April] = DATEDIFF(MONTH, [FinancialYearKey_April] , [MonthKey]) + 1

	
	/*#*========== ✅ ACTION ==========*#*/
	UPDATE [UTL].[Calendar]
	SET [DayOfWeekName] = UPPER(FORMAT([DateKey], 'ddd'))
	,[YearName] = FORMAT([DateKey], 'yyyy')
	,[HalfYearName] = CASE WHEN MONTH([HalfYearKey]) = 1 THEN 'S1' ELSE 'S2' END + ', ' + FORMAT([DateKey], 'yyyy')
	,[QuarterName] = CASE WHEN MONTH([QuarterKey]) = 1 THEN 'Q1' 
										   WHEN MONTH([QuarterKey]) = 4 THEN 'Q2' 
										   WHEN MONTH([QuarterKey]) = 7 THEN 'Q3' 										   
											ELSE 'Q4' END + ', ' + FORMAT([DateKey], 'yyyy')
	,[MonthName] = UPPER(FORMAT([MonthKey], 'MMM yyyy'))
	,[MonthOfYearName] = UPPER(FORMAT([MonthKey], 'MMM'))
	,[WeekName] = 'W' + FORMAT([WeekOfYearKey], '00') + ', ' + FORMAT([WeekKey], 'yyyy')
	,[FinancialYearName] = 'FY' + FORMAT([FinancialYearKey], 'yyyy') + '-'+ FORMAT(DATEADD(YEAR,1,[FinancialYearKey]), 'yyyy')
	,[FinancialPeriod] = 'FY' + FORMAT(DATEADD(YEAR,1,[FinancialYearKey]), 'yyyy') + '-' + FORMAT([MonthOfFinancialYearKey], '00')
	,[FinancialYearName_April] = 'FY' + FORMAT([FinancialYearKey_April], 'yyyy') + '-'+ FORMAT(DATEADD(YEAR,1,[FinancialYearKey_April]), 'yyyy')
	,[FinancialPeriod_April] = 'FY' + FORMAT(DATEADD(YEAR,1,[FinancialYearKey_April]), 'yyyy') + '-' + FORMAT([MonthOfFinancialYearKey_April], '00')
	,[FinancialQuarterName] = CASE WHEN MONTH([QuarterKey]) = 1 THEN 'Q1' 
										   WHEN MONTH([QuarterKey]) = 4 THEN 'Q2' 
										   WHEN MONTH([QuarterKey]) = 7 THEN 'Q3' 										   
											ELSE 'Q4' END + ', ' + 'FY' + FORMAT([FinancialYearKey], 'yyyy') + '-'+ FORMAT(DATEADD(YEAR,1,[FinancialYearKey]), 'yyyy')
	 
	/*#*========== ✅ ACTION ==========*#*/
	UPDATE [UTL].[Calendar]
	SET [QuarterFullName]  = [QuarterName] + UPPER(' (' + FORMAT([QuarterKey], 'dd MMM') + '-' + FORMAT(DATEADD(DAY,-1,DATEADD(MONTH,3,[QuarterKey])), 'dd MMM') + ')')
	, [MonthFullName] = [MonthName]
	,[WeekFullName] = [WeekName] + UPPER(' (' + FORMAT([WeekKey], 'dd MMM') + '-' + FORMAT(DATEADD(DAY,7, [WeekKey]), 'dd MMM') + ')')
	,[FinancialQuarterFullName] = [FinancialQuarterName]+ UPPER(' (' + FORMAT([QuarterKey], 'dd MMM') + '-' + FORMAT(DATEADD(DAY,-1,DATEADD(MONTH,3,[QuarterKey])), 'dd MMM') + ')')

	/*#*========== ✅ ACTION ==========*#*/
	UPDATE [UTL].[Calendar]
	SET [TotalDays_Month] = DATEDIFF(DAY, [MonthKey], DATEADD(MONTH, 1,[MonthKey]))
	,[TotalDays_Year] = DATEDIFF(DAY, [YearKey], DATEADD(YEAR, 1,[YearKey]))
	,[DaysElapsed_Month] = [DayOfMonthKey]
	,[DaysElapsed_Year] = [DayOfYearKey]
	,[WeekdayCount] = CASE WHEN [DayOfWeekKey] < 6 THEN 1 ELSE 0 END
	WHERE 1=1;


	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteMonth AS (	
		SELECT [MonthKey], SUM([WeekdayCount]) AS [TotalWeekdays_Month]
		FROM [UTL].[Calendar]
		GROUP BY [MonthKey]
	)
	,cteYear AS (
		SELECT [YearKey], SUM([WeekdayCount]) AS [TotalWeekdays_Year]
		FROM [UTL].[Calendar]
		GROUP BY [YearKey]
	)
	/*#*========== ✅ ACTION ==========*#*/
	UPDATE [UTL].[Calendar]
	SET [TotalWeekdays_Month] = m.[TotalWeekdays_Month]
	, [TotalWeekdays_Year] = y.[TotalWeekdays_Year]
	FROM [UTL].[Calendar] AS o
	INNER JOIN cteMonth AS m ON o.[MonthKey] = m.[MonthKey]
	INNER JOIN cteYear AS y ON o.[YearKey] = o.[YearKey]
	WHERE 1=1;
	
	
	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteWeekdayElapsed_Month AS (	
		SELECT o.[DateKey]
		,SUM(m.[WeekdayCount]) AS [WeekdaysElapsed_Month]		
		FROM [UTL].[Calendar] AS o
		INNER JOIN [UTL].[Calendar] AS m ON m.[DateKey] BETWEEN o.[MonthKey] AND o.[DateKey]
		GROUP BY o.[DateKey]
	)	
	,cteWeekdayElapsed_Year AS (	
		SELECT o.[DateKey]
		,SUM(y.[WeekdayCount]) AS [WeekdaysElapsed_Year]
		FROM [UTL].[Calendar] AS o
		INNER JOIN [UTL].[Calendar] AS y ON y.[DateKey] BETWEEN o.[YearKey] AND o.[DateKey]
		GROUP BY o.[DateKey]
	)
	/*#*========== ✅ ACTION ==========*#*/
	UPDATE [UTL].[Calendar]
	SET [WeekdaysElapsed_Month] = m.[WeekdaysElapsed_Month]
	,[WeekdaysElapsed_Year] = y.[WeekdaysElapsed_Year]
	FROM [UTL].[Calendar] AS o
	INNER JOIN cteWeekdayElapsed_Month AS m ON o.[DateKey] = m.[DateKey]
	INNER JOIN cteWeekdayElapsed_Year AS y ON o.[DateKey] = y.[DateKey]	
	WHERE 1=1;

	/*#*========== ✅ ACTION ==========*#*/
	UPDATE [UTL].[Calendar]
	SET [DaysElapsedRate_Month] = [DaysElapsed_Month] * 1.00 / [TotalDays_Month]
	,[DaysElapsedRate_Year] = [DaysElapsed_Year] * 1.00 / [TotalDays_Year]
	,[WeekdaysElapsedRate_Month] = [WeekdaysElapsed_Year] * 1.00 / [TotalWeekdays_Month]
	,[WeekdaysElapsedRate_Year] = [WeekdaysElapsed_Year] * 1.00 / [TotalWeekdays_Year]
	

	/*#*---------- 🧹 CLEANUP ----------*#*/



END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [UTL].[SnapshotBegin]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO















/*
	/*#*---------- 🔍 EXAMPLE ----------*#*/
	EXEC [SVC].[FindX] '%Snapshot%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/       
	EXEC [UTL].[SnapshotBegin] 'Ad-hoc', '[SVC].[IngestionParam]', '2026-02-23';
	

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT *
	-- SELECT DISTINCT OF_ASAT, OF_ALL
	FROM [UTL].[IngestionParam]
	ORDER BY  OF_ALL, OF_ASAT

*/
CREATE PROC [UTL].[SnapshotBegin]
	@Controller VARCHAR(500) /*_*{Parameter},{@Controller},{Orignal job or schedueler}*_*/
   ,@TableName_Qualifed VARCHAR(500) /*_*{Parameter},{@TableName_Qualifed},{Table Full Name}*_*/
   ,@ASAT DATETIME2(0) /*_*{Parameter},{@ASAT},{As at date}*_*/   
   ,@SnapshotLimit SMALLINT = 50 /*_*{Parameter},{@SnapshotLimit},{Number of Snapshot to keep}*_*/   
   ,@ExpiredSnapshotLimit SMALLINT = 5 /*_*{Parameter},{@ExpiredSnapshotLimit},{No of recently expired snapshot to keep}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/	
	
	
	/*#*---------- 📄 PARAMETER ----------*#*/
	DECLARE @_DB VARCHAR(500),  @_Condition NVARCHAR(500), @_ASAT NVARCHAR(50), @_SnapshotRetention SMALLINT, @_SnapshotRetention_Expired SMALLINT

	/*#*---------- 📄 PARAMETER ----------*#*/
	SET @_DB = DB_NAME();
	SET @_ASAT = FORMAT(@ASAT, 'yyyy-MM-dd'); 
	SET @_Condition = '[OF_ASAT] = ''' + @_ASAT + ''' '; 
	SET @_SnapshotRetention = ISNULL(@SnapshotLimit, 50);
	SET @_SnapshotRetention_Expired = ISNULL(@ExpiredSnapshotLimit, 5);

	/*#*========== ✅ ACTION: Remove ASAT  ==========*#*/
	EXEC [UTL].[EmptyTable] @Controller, @TableName_Qualifed, @_Condition;
	
	/*#*---------- 📄 PARAMETER ----------*#*/
	SET @_Condition = ' ([OF_ALL]<' + CONVERT(VARCHAR(10), -1 * @_SnapshotRetention) + ' OR  [OF_ALL] BETWEEN 50 AND ' + CONVERT(VARCHAR(10), 100 - @_SnapshotRetention_Expired) +  ')'; 
	/*#*========== ✅ ACTION: Remove Old Snapshots  ==========*#*/
	
	EXEC [UTL].[EmptyTable] @Controller, @TableName_Qualifed, @_Condition;

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [UTL].[SnapshotEnd]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



















/*
    /*#*---------- 🔍 EXAMPLE ----------*#*/
	EXEC [SVC].[FindX] '%Offset%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/    
	EXEC [UTL].[SnapshotEnd] 'Ad-hoc', '[SVC].[IngestionConfig]', 'Day'
    EXEC [UTL].[SnapshotEnd] 'Ad-hoc', '[SVC].[IngestionConfig]', 'Month'
    
	/*#*---------- 🧪 VALIDATION ----------*#*/

	SELECT TOP 100 * 
	FROM [SVC].[IngestionConfig]
    ORDER BY 5,4
    
    
*/
CREATE PROC [UTL].[SnapshotEnd]
    @Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
    ,@QN_Table varchar(500)/*_*{Parameter},{@QN_Table},{Table Full Name}*_*/    	
    ,@Frequency varchar(500)/*_*{Parameter},{@Frequency},{Month or Day}*_*/    
AS
BEGIN
	SET NOCOUNT ON;
    /*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_DB VARCHAR(100), @_Schema VARCHAR(100), @_Table VARCHAR(100), @_TableFullName VARCHAR(500), @_Frequency VARCHAR(500), @_OP VARCHAR(100), @_SQLT VARCHAR(4000), @_SQL VARCHAR(8000);        
	/*#*---------- 📄 PARAMETER ----------*#*/
    SET @_SQLT = ';WITH cteRaw AS (
	SELECT o.[OF_ASAT] AS [ASAT]
	,DATETRUNC(#PERIOD#, o.[OF_ASAT]) AS [ASAT_Period]
	,ROW_NUMBER() OVER (ORDER BY [OF_ASAT] DESC) AS [Rank_All]
	FROM #TABLE# AS o
	GROUP BY [OF_ASAT]
)
,cteASAT AS (
	SELECT o.*
	,ROW_NUMBER() OVER (PARTITION BY [ASAT_Period]  ORDER BY [ASAT] DESC) AS [Rank_Period]
	FROM cteRaw AS o
)
,ctePeriod AS (
	SELECT o.*
	,ROW_NUMBER() OVER (ORDER BY [ASAT] DESC) AS [Rank_Selected]
	FROM cteASAT AS o	
	WHERE [Rank_Period] = 1
)
,cteData AS (
	SELECT o.[ASAT], o.[ASAT_Period]
	,[OF_ALL] = CASE WHEN x.[ASAT] IS NOT NULL THEN 1 - x.[Rank_Selected]
				ELSE 101 - o.[Rank_All] END
	FROM cteASAT AS o
	LEFT JOIN ctePeriod AS x ON x.ASAT = o.ASAT
)

UPDATE o
SET [OF_ALL] = x.[OF_ALL]
FROM #TABLE# AS o
INNER JOIN cteData AS x ON x.[ASAT] = o.[OF_ASAT];'; 

    /*#*---------- 📄 PARAMETER ----------*#*/
    SET @_DB = DB_NAME();
    SET @_Schema = PARSENAME(@QN_Table, 2);
	SET @_Table = PARSENAME(@QN_Table, 1);
    SET @_TableFullName = CONCAT_WS('.', QUOTENAME(@_DB), QUOTENAME(@_Schema), QUOTENAME(@_Table));

    SET @_Frequency = CASE WHEN @Frequency IN('Day', 'Daily') THEN 'DAY' ELSE  'MONTH' END;

    SET @_OP = CASE WHEN @_Frequency = '' THEN 'TRUNCATE TABLE'
                                    ELSE 'DELETE ' END;

    /*#*---------- 📄 PARAMETER ----------*#*/    
    SET @_SQL = REPLACE(REPLACE(@_SQLT
                        , '#TABLE#', @_TableFullName)
                        , '#PERIOD#', @_Frequency);

	/*#*========== ✅ ACTION ==========*#*/
    EXEC(@_SQL);        
	PRINT '/*---------- 🔼 Offset Set : ' + @_TableFullName + ' -- ' + @_Frequency + ' ----------*/';
    
    /*#*---------- 🧹 CLEANUP ----------*#*/

END
/*#*==================== 🔚 ====================*#*/
GO
/****** Object:  StoredProcedure [UTL].[UpdateCalendar]    Script Date: 25/03/2026 4:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO












/*
     /*#*---------- 🔍 EXAMPLE ----------*#*/
	EXEC [SVC].[FindX] '%Calendar%', 'Proc';

	/*#*---------- 🧪 VALIDATION ----------*#*/
    EXEC [UTL].[SeedCalendar];
	EXEC [UTL].[UpdateCalendar];

	/*#*---------- 🧪 VALIDATION ----------*#*/

	SELECT TOP 100 * 
	FROM [UTL].[Calendar] AS o
	WHERE o.DateKey BETWEEN '2025-07-01' AND '2025-09-30' 
	ORDER BY o.[DateKey]

*/
CREATE PROC [UTL].[UpdateCalendar]
	@Controller varchar(500) = NULL /*_*{Parameter},{@Controller},{Control Flow SP Name}*_*/
AS
BEGIN
	SET NOCOUNT ON;
	/*#*========== 🎯 PURPOSE ==========*#*/
	DECLARE @_Time DATETIME, @_Date DATETIME, @_FinancialYear DATETIME, @_Lag SMALLINT;

	/*#*---------- 📄 PARAMETER ----------*#*/
	--SET @_Time = GETDATE() AT TIME ZONE 'UTC';	
	SET @_Time = GETDATE() AT TIME ZONE 'UTC' AT TIME ZONE 'Cen. Australia Standard Time'	;
	SET @_Date = DATEADD(DAY, DATEDIFF(DAY, 0, @_Time), 0);
	--	SET @_Date = TRY_CONVERT(DATETIME2, '2025-07-01');	

	SET @_FinancialYear = (SELECT TOP 1 [FinancialYearKey] FROM [UTL].[Calendar] WHERE [DateKey] = @_Date)
	
	/*#*========== ✅ ACTION ==========*#*/
    UPDATE [UTL].[Calendar]
	SET  [zUPD] = @_Time	
	, [CA_DayOffset] = DATEDIFF(DAY, @_Date, [DateKey]) 
	, [CA_WeekOffset] = DATEDIFF(WEEK, DATEADD(DAY, - 1, @_Date), DATEADD(DAY, - 1, [DateKey]))
	, [CA_MonthOffset] = DATEDIFF(MONTH, @_Date, [DateKey])
	, [CA_QuarterOffset] = DATEDIFF(QUARTER, @_Date, [DateKey])
	, [CA_FinancialQuarterOffset] = DATEDIFF(QUARTER, @_Date, [DateKey])
	, [CA_YearOffset] = DATEDIFF(YEAR, @_Date, [DateKey])
	, [CA_FinancialYearOffset] = DATEDIFF(YEAR, @_FinancialYear, [FinancialYearKey])

	/*#*========== ✅ ACTION ==========*#*/
	UPDATE [UTL].[Calendar]
	SET [CA_WeekOffset_ByThursday] = CASE 
		WHEN DATEPART(dw, @_Date) IN (2,3,4) THEN [CA_WeekOffset] + 1
		WHEN DATEPART(dw, @_Date) IN (5,6,7,1) THEN [CA_WeekOffset]
		ELSE NULL
		END
	
	/*#*---------- 📄 PARAMETER ----------*#*/
	DECLARE @_Threshold SMALLINT, @_Current VARCHAR(50),@_Future VARCHAR(50), @_History VARCHAR(50), @_Default VARCHAR(50);
	SET @_Current = 'Current ';
	SET @_Future = 'Future ';
	SET @_History = 'History ';
	SET @_Default = 'Default '
	SET @_Threshold = 3;

	/*#*========== ✅ ACTION ==========*#*/
	UPDATE [UTL].[Calendar] 
	SET [CA_DayOffset_Category] = CASE WHEN o.[CA_DayOffset] < 0 THEN CASE WHEN o.[CA_DayOffset] >= -1*@_Threshold THEN @_Current + 'Date' + ' - ' + FORMAT(ABS([CA_DayOffset]),'0') ELSE @_History + 'Dates' END
				WHEN o.[CA_DayOffset] = 0 THEN @_Current + 'Date'
				WHEN o.[CA_DayOffset] > 0 THEN CASE WHEN o.[CA_DayOffset] <= @_Threshold THEN @_Current + 'Date' + ' + '  + FORMAT(ABS([CA_DayOffset]),'0') ELSE @_Future + 'Dates' END
				END	
	,[CA_WeekOffset_Category] = CASE WHEN o.[CA_WeekOffset] < 0 THEN CASE WHEN o.[CA_WeekOffset] >= -1*@_Threshold THEN @_Current + 'Week' + ' - ' + FORMAT(ABS([CA_WeekOffset]),'0') ELSE @_History + 'Weeks' END
					WHEN o.[CA_WeekOffset] = 0 THEN @_Current + 'Week'
					WHEN o.[CA_WeekOffset] > 0 THEN CASE WHEN o.[CA_WeekOffset] <= @_Threshold THEN @_Current + 'Week' + ' + '  + FORMAT(ABS([CA_WeekOffset]),'0') ELSE @_Future + 'Weeks' END
					END
	,[CA_MonthOffset_Category] = CASE WHEN o.[CA_MonthOffset] < 0 THEN CASE WHEN o.[CA_MonthOffset] >= -1*@_Threshold THEN @_Current + 'Month' + ' - ' + FORMAT(ABS([CA_MonthOffset]),'0') ELSE @_History + 'Months' END
					WHEN o.[CA_MonthOffset] = 0 THEN @_Current + 'Month'
					WHEN o.[CA_MonthOffset] > 0 THEN CASE WHEN o.[CA_MonthOffset] <= @_Threshold THEN @_Current + 'Month' + ' + '  + FORMAT(ABS([CA_MonthOffset]),'0') ELSE @_Future + 'Months' END
					END
	,[CA_QuarterOffset_Category] = CASE WHEN o.[CA_QuarterOffset] < 0 THEN CASE WHEN o.[CA_QuarterOffset] >= -1*@_Threshold THEN @_Current + 'Quarter' + ' - ' + FORMAT(ABS([CA_QuarterOffset]),'0') ELSE @_History + 'Quarters' END
					WHEN o.[CA_QuarterOffset] = 0 THEN @_Current + 'Quarter'
					WHEN o.[CA_QuarterOffset] > 0 THEN CASE WHEN o.[CA_QuarterOffset] <= @_Threshold THEN @_Current + 'Quarter' + ' + '  + FORMAT(ABS([CA_QuarterOffset]),'0') ELSE @_Future + 'Quarters' END
					END
	,[CA_FinancialQuarterOffset_Category] = CASE WHEN o.[CA_FinancialQuarterOffset] < 0 THEN CASE WHEN o.[CA_FinancialQuarterOffset] >= -1*@_Threshold THEN @_Current + 'Quarter' + ' - ' + FORMAT(ABS([CA_FinancialQuarterOffset]),'0') ELSE @_History + 'Quarters' END
					WHEN o.[CA_FinancialQuarterOffset] = 0 THEN @_Current + 'Quarter'
					WHEN o.[CA_FinancialQuarterOffset] > 0 THEN CASE WHEN o.[CA_FinancialQuarterOffset] <= @_Threshold THEN @_Current + 'Quarter' + ' + '  + FORMAT(ABS([CA_FinancialQuarterOffset]),'0') ELSE @_Future + 'Quarters' END
					END
	,[CA_YearOffset_Category] = CASE WHEN o.[CA_YearOffset] < 0 THEN CASE WHEN o.[CA_YearOffset] >= -1*@_Threshold THEN @_Current + 'Year' + ' - ' + FORMAT(ABS([CA_YearOffset]),'0') ELSE @_History + 'Years' END
					WHEN o.[CA_YearOffset] = 0 THEN @_Current + 'Year'
					WHEN o.[CA_YearOffset] > 0 THEN CASE WHEN o.[CA_YearOffset] <= @_Threshold THEN @_Current + 'Year' + ' + '  + FORMAT(ABS([CA_YearOffset]),'0') ELSE @_Future + 'Years' END
					END
	,[CA_FinancialYearOffset_Category] = CASE WHEN o.[CA_FinancialYearOffset] < 0 THEN CASE WHEN o.[CA_FinancialYearOffset] >= -1*@_Threshold THEN @_Current + 'FY' + ' - ' + FORMAT(ABS([CA_FinancialYearOffset]),'0') ELSE @_History + 'FYs' END
					WHEN o.[CA_FinancialYearOffset] = 0 THEN @_Current + 'FY'
					WHEN o.[CA_FinancialYearOffset] > 0 THEN CASE WHEN o.[CA_FinancialYearOffset] <= @_Threshold THEN @_Current + 'FY' + ' + '  + FORMAT(ABS([CA_FinancialYearOffset]),'0') ELSE @_Future + 'FYs' END
					END
	/*#*========== 🙀 MISC ==========*#*/
	,[CA_DayOffset_Category_Simple]  = CASE WHEN o.[CA_DayOffset] < 0 THEN @_History + 'Dates'
				WHEN o.[CA_DayOffset] = 0 THEN @_Current + 'Date'
				WHEN o.[CA_DayOffset] > 0 THEN @_Future + 'Dates'
				END
	,[CA_WeekOffset_Category_Simple]  = CASE WHEN o.[CA_WeekOffset] < 0 THEN @_History + 'Weeks'
			WHEN o.[CA_WeekOffset] = 0 THEN @_Current + 'Week'
			WHEN o.[CA_WeekOffset] > 0 THEN @_Future + 'Weeks'
			END
	,[CA_MonthOffset_Category_Simple]  = CASE WHEN o.[CA_MonthOffset] < 0 THEN @_History + 'Months'
			WHEN o.[CA_MonthOffset] = 0 THEN @_Current + 'Month'
			WHEN o.[CA_MonthOffset] > 0 THEN @_Future + 'Months'
			END
	,[CA_QuarterOffset_Category_Simple]  = CASE WHEN o.[CA_QuarterOffset] < 0 THEN @_History + 'Quarters'
			WHEN o.[CA_QuarterOffset] = 0 THEN @_Current + 'Quarter'
			WHEN o.[CA_QuarterOffset] > 0 THEN @_Future + 'Quarters'
			END	
	,[CA_FinancialQuarterOffset_Category_Simple]  = CASE WHEN o.[CA_FinancialQuarterOffset] < 0 THEN @_History + 'FinancialQuarters'
			WHEN o.[CA_FinancialQuarterOffset] = 0 THEN @_Current + 'FinancialQuarter'
			WHEN o.[CA_FinancialQuarterOffset] > 0 THEN @_Future + 'FinancialQuarters'
			END
	,[CA_YearOffset_Category_Simple]  = CASE WHEN o.[CA_YearOffset] < 0 THEN @_History + 'Years'
			WHEN o.[CA_YearOffset] = 0 THEN @_Current + 'Year'
			WHEN o.[CA_YearOffset] > 0 THEN @_Future + 'Years'
			END
	,[CA_FinancialYearOffset_Category_Simple]  = CASE WHEN o.[CA_FinancialYearOffset] < 0 THEN @_History + 'FinancialYears'
			WHEN o.[CA_FinancialYearOffset] = 0 THEN @_Current + 'FinancialYear'
			WHEN o.[CA_FinancialYearOffset] > 0 THEN @_Future + 'FinancialYears'
			END
	FROM [UTL].[Calendar] AS o;
	
	/*#*---------- 📄 PARAMETER ----------*#*/
	DECLARE @_DayOffset_Default SMALLINT
		,@_WeekOffset_Default SMALLINT
		,@_MonthOffset_Default SMALLINT
		,@_QuarterOffset_Default SMALLINT
		,@_FinancialQuarterOffset_Default SMALLINT
		,@_YearOffset_Default SMALLINT
		,@_FinancialYearOffset_Default SMALLINT;

	/*#*---------- 📄 PARAMETER ----------*#*/
	SELECT TOP 1 @_DayOffset_Default = CASE WHEN o.[DayOfMonthKey] = 1 THEN -1 ELSE 0 END
		,@_QuarterOffset_Default = CASE WHEN o.[MonthOfQuarterKey] = 1 THEN -1 ELSE 0 END
		,@_FinancialQuarterOffset_Default = CASE WHEN o.[MonthOfFinancialQuarterKey] = 1 THEN -1 ELSE 0 END
		,@_YearOffset_Default = CASE WHEN o.[MonthOfYearKey] <= 3 THEN -1 ELSE 0 END
		,@_FinancialYearOffset_Default = CASE WHEN o.[MonthOfFinancialYearKey] <= 3 THEN -1 ELSE 0 END
	FROM [UTL].[Calendar] AS o
	WHERE o.[CA_DayOffset] = 0;

	/*#*---------- 📄 PARAMETER ----------*#*/
	SELECT @_WeekOffset_Default = o.[CA_WeekOffset]
		,@_MonthOffset_Default = o.[CA_MonthOffset]
	FROM [UTL].[Calendar] AS o
	WHERE o.[CA_DayOffset] = @_DayOffset_Default;

	/*#*========== ✅ ACTION ==========*#*/
	UPDATE [UTL].[Calendar]
	SET [CA_DayOffset_Category_Default] = 
		CASE WHEN o.[CA_DayOffset] < @_DayOffset_Default
				THEN CASE WHEN o.[CA_DayOffset] >= -1 * @_Threshold + @_DayOffset_Default
					THEN @_Default + 'Date' + ' - ' + FORMAT(ABS([CA_DayOffset] - @_DayOffset_Default),'0') 
					ELSE @_History + 'Dates' END
			WHEN o.[CA_DayOffset] = @_DayOffset_Default
				THEN @_Default + 'Date'
			WHEN o.[CA_DayOffset] > @_DayOffset_Default
				THEN CASE WHEN o.[CA_DayOffset] <= @_Threshold + @_DayOffset_Default
					THEN @_Default + 'Date' + ' + ' + FORMAT(ABS([CA_DayOffset] - @_DayOffset_Default),'0') 
					ELSE @_Future + 'Dates' END
	END
	,[CA_WeekOffset_Category_Default] = 
		CASE WHEN o.[CA_WeekOffset] < @_WeekOffset_Default
				THEN CASE WHEN o.[CA_WeekOffset] >= -1 * @_Threshold + @_WeekOffset_Default
					THEN @_Default + 'Week' + ' - ' + FORMAT(ABS([CA_WeekOffset] - @_WeekOffset_Default),'0') 
					ELSE @_History + 'Weeks' END
			WHEN o.[CA_WeekOffset] = @_WeekOffset_Default
				THEN @_Default + 'Week'
			WHEN o.[CA_WeekOffset] > @_WeekOffset_Default
				THEN CASE WHEN o.[CA_WeekOffset] <= @_Threshold + @_WeekOffset_Default
					THEN @_Default + 'Week' + ' + ' + FORMAT(ABS([CA_WeekOffset] - @_WeekOffset_Default),'0') 
					ELSE @_Future + 'Weeks' END
	END
	,[CA_MonthOffset_Category_Default] = 
		CASE WHEN o.[CA_MonthOffset] < @_MonthOffset_Default
				THEN CASE WHEN o.[CA_MonthOffset] >= -1 * @_Threshold + @_MonthOffset_Default
					THEN @_Default + 'Month' + ' - ' + FORMAT(ABS([CA_MonthOffset] - @_MonthOffset_Default),'0') 
					ELSE @_History + 'Months' END
			WHEN o.[CA_MonthOffset] = @_MonthOffset_Default
				THEN @_Default + 'Month'
			WHEN o.[CA_MonthOffset] > @_MonthOffset_Default
				THEN CASE WHEN o.[CA_MonthOffset] <= @_Threshold + @_MonthOffset_Default
					THEN @_Default + 'Month' + ' + ' + FORMAT(ABS([CA_MonthOffset] - @_MonthOffset_Default),'0') 
					ELSE @_Future + 'Months' END
	END
	,[CA_QuarterOffset_Category_Default] = 
		CASE WHEN o.[CA_QuarterOffset] < @_QuarterOffset_Default
				THEN CASE WHEN o.[CA_QuarterOffset] >= -1 * @_Threshold + @_QuarterOffset_Default
					THEN @_Default + 'Quarter' + ' - ' + FORMAT(ABS([CA_QuarterOffset] - @_QuarterOffset_Default),'0') 
					ELSE @_History + 'Quarters' END
			WHEN o.[CA_QuarterOffset] = @_QuarterOffset_Default
				THEN @_Default + 'Quarter'
			WHEN o.[CA_QuarterOffset] > @_QuarterOffset_Default
				THEN CASE WHEN o.[CA_QuarterOffset] <= @_Threshold + @_QuarterOffset_Default
					THEN @_Default + 'Quarter' + ' + ' + FORMAT(ABS([CA_QuarterOffset] - @_QuarterOffset_Default),'0') 
					ELSE @_Future + 'Quarters' END
	END
	,[CA_FinancialQuarterOffset_Category_Default] = 
		CASE WHEN o.[CA_FinancialQuarterOffset] < @_FinancialQuarterOffset_Default
				THEN CASE WHEN o.[CA_FinancialQuarterOffset] >= -1 * @_Threshold + @_FinancialQuarterOffset_Default
					THEN @_Default + 'FinancialQuarter' + ' - ' + FORMAT(ABS([CA_FinancialQuarterOffset] - @_FinancialQuarterOffset_Default),'0') 
					ELSE @_History + 'FinancialQuarters' END
			WHEN o.[CA_FinancialQuarterOffset] = @_FinancialQuarterOffset_Default
				THEN @_Default + 'FinancialQuarter'
			WHEN o.[CA_FinancialQuarterOffset] > @_FinancialQuarterOffset_Default
				THEN CASE WHEN o.[CA_FinancialQuarterOffset] <= @_Threshold + @_FinancialQuarterOffset_Default
					THEN @_Default + 'FinancialQuarter' + ' + ' + FORMAT(ABS([CA_FinancialQuarterOffset] - @_FinancialQuarterOffset_Default),'0') 
					ELSE @_Future + 'FinancialQuarters' END
	END
	,[CA_YearOffset_Category_Default] = 
		CASE WHEN o.[CA_YearOffset] < @_YearOffset_Default
				THEN @_History + 'Years'
			WHEN o.[CA_YearOffset] BETWEEN @_YearOffset_Default AND 0
				THEN @_Default + 'Year'
			WHEN o.[CA_YearOffset] > 0
				THEN @_Future + 'Years'
	END
	,[CA_FinancialYearOffset_Category_Default] = 
		CASE WHEN o.[CA_FinancialYearOffset] < @_FinancialYearOffset_Default 
				THEN @_History + 'FYs'
			WHEN o.[CA_FinancialYearOffset] BETWEEN @_FinancialYearOffset_Default AND 0
				THEN @_Default + 'FY'
			WHEN o.[CA_FinancialYearOffset] > 0
				THEN @_Future + 'FYs'
	END
	FROM [UTL].[Calendar] AS o;



	/*#*---------- 🧹 CLEANUP ----------*#*/

END
/*#*==================== 🔚 ====================*#*/
GO

/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/

/*#*########## 📚 Template App ##########*#*/
USE [V90_Lake];

CREATE TABLE [APP].[Ref](
	[zID] VARCHAR(50) NOT NULL,
	[zSTMPz] [varchar](50),
	[RefCode] [varchar](50),
	[RefName] [varchar](100),
	[RefDesc] [varchar](200),
	[RefCategory] [varchar](20),
	[RefType] [varchar](20),
	[RefSeq] [int],
	[RefNo] [varchar](10),
	[RefStatus] [varchar](20)
)

GO

CREATE TABLE [APP].[Target_FULL](
	[zID] VARCHAR(50),
	[zSTMPz] VARCHAR(50),
	[RefCode] VARCHAR(50),
	[RefName] VARCHAR(100),
	[TargetDate] DATETIME2(0),
	[DUOM] VARCHAR(10),
	[Qty_DUOM] DECIMAL(18, 6) 
)
GO

CREATE TABLE [APP].[Target_PARTIAL](
	[zID] VARCHAR(50),
	[zSTMPz] VARCHAR(50),
	[RefCode] VARCHAR(50),
	[RefName] VARCHAR(100),
	[TargetDate] DATETIME2(0),
	[DUOM] VARCHAR(10),
	[Qty_DUOM] DECIMAL(18, 6) 
)
GO
CREATE TABLE [APP].[TranDetail_FULL](
	[zID] VARCHAR(50),
	[zSTMPz] VARCHAR(50),
	[RefCode] VARCHAR(50),
	[RefName] VARCHAR(100),
	[TranNo] VARCHAR(50),
	[TranLineNo] VARCHAR(10),
	[TranDate] DATETIME2(0),
	[TUOM] VARCHAR(10),
	[DUOM] VARCHAR(10),
	[CurrCode_TRN] VARCHAR(10),
	[CurrCode_BASE] VARCHAR(10),
	[CurrCode_CON] VARCHAR(10),
	[UC_TUOM_TO_DUOM] DECIMAL(18, 6),
	[Qty_TUOM] DECIMAL(18, 6),
	[Qty_DUOM] DECIMAL(18, 6),
	[UnitCost_TRN_TUOM] DECIMAL(18, 6),
	[UnitPrice_TRN_TUOM] DECIMAL(18, 6),
	[UnitCost_BASE_DUOM] DECIMAL(18, 6),
	[UnitPrice_BASE_DUOM] DECIMAL(18, 6) 
)
GO
CREATE TABLE [APP].[TranDetail_PARTIAL](
	[zID] VARCHAR(50),
	[zSTMPz] VARCHAR(50),
	[RefCode] VARCHAR(50),
	[RefName] VARCHAR(100),
	[TranNo] VARCHAR(50),
	[TranLineNo] VARCHAR(10),
	[TranDate] DATETIME2(0),
	[TUOM] VARCHAR(10),
	[DUOM] VARCHAR(10),
	[CurrCode_TRN] VARCHAR(10),
	[CurrCode_BASE] VARCHAR(10),
	[CurrCode_CON] VARCHAR(10),
	[UC_TUOM_TO_DUOM] DECIMAL(18, 6),
	[Qty_TUOM] DECIMAL(18, 6),
	[Qty_DUOM] DECIMAL(18, 6),
	[UnitCost_TRN_TUOM] DECIMAL(18, 6),
	[UnitPrice_TRN_TUOM] DECIMAL(18, 6),
	[UnitCost_BASE_DUOM] DECIMAL(18, 6),
	[UnitPrice_BASE_DUOM] DECIMAL(18, 6) 
)
GO
CREATE TABLE [APP].[TranHeader_FULL](
	[zID] VARCHAR(50),
	[zSTMPz] VARCHAR(50),
	[RefCode] VARCHAR(50),
	[RefName] VARCHAR(100),
	[TranNo] VARCHAR(50),
	[TranDate] DATETIME2(0) 
)
GO
CREATE TABLE [APP].[TranHeader_PARTIAL](
	[zID] VARCHAR(50),
	[zSTMPz] VARCHAR(50),
	[RefCode] VARCHAR(50),
	[RefName] VARCHAR(100),
	[TranNo] VARCHAR(50),
	[TranDate] DATETIME2(0) 
)
GO
USE [V90_Lake];
GO
/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [V90_Core].[UTL].[FindX] '%Target%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 10 * 
	FROM [APP].[Target_OVERLAP]

*/
CREATE VIEW [APP].[Target_OVERLAP]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/	
	
	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteFull AS (
		SELECT o.[zID]
		,CONCAT_WS('+', o.[RefCode], FORMAT(o.[TargetDate], 'yyyyMMdd')) AS [BK_DE]
		,o.[TargetDate] AS [BK_Date]		
		FROM [APP].[Target_FULL] AS o
	)
	, ctePartial AS (
		SELECT o.[zID]
		, CONCAT_WS('+', o.[RefCode], FORMAT(o.[TargetDate], 'yyyyMMdd')) AS [BK_DE]
		,o.[TargetDate] AS [BK_Date]
		FROM [APP].[Target_PARTIAL] AS o 
	)

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT cfg.[BK_SRC_APP] AS [BK_SRC]
		,o.[zID] AS [zID]
		,x.[zID] AS [zID_PARTIAL]
		,CONVERT(VARCHAR(200), CONCAT_WS('+', cfg.[BK_SRC_APP], o.[BK_DE])) AS [BK_DE]
		,CONVERT(VARCHAR(500), CONCAT_WS('; ', 'Start Date: ' + FORMAT(cfg.[TargetStartDate], 'yyyy-MM-dd')
								, 'End Date: ' + FORMAT(cfg.[TargetEndDate], 'yyyy-MM-dd') )) AS [CA_Memo]
	FROM cteFull AS o
	LEFT JOIN ctePartial AS x ON o.[BK_DE] = x.[BK_DE]
	INNER JOIN [AAL].[Setting] AS cfg ON o.[BK_Date] BETWEEN cfg.[TargetStartDate] AND cfg.[TargetEndDate]



/*#*==================== 🔚 ====================*#*/
GO

/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [V90_Core].[UTL].[FindX] '%Target%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 10 * 
	FROM [APP].[Target_QUERY]

*/
CREATE VIEW [APP].[Target_QUERY]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteParam AS (
		SELECT [Lake] = CONVERT(VARCHAR(100), DB_NAME())
			,[SchemaName] = o.[BK_SRC_APP]
			,[TableName] = CONVERT(VARCHAR(100), 'Target')
			,[Source] = o.[BK_SRC_APP]
			,[QN_SourceTable] = CONVERT(VARCHAR(100), '[V90_Core].[SVC].[Sample_Target]')
			,StartDateStr = FORMAT(o.[TargetStartDate], o.[DateStrFormat])
			,EndDateStr = FORMAT(o.[TargetEndDate], o.[DateStrFormat])
			,TimeStampStr = o.TimeStampStr
		FROM [AAL].[Setting] AS o
	)
	,cteQuery AS (
		SELECT o.*
			/*#*---------- 📌 DETAIL ----------*#*/
			,SourceTablePreparation = CONVERT(VARCHAR(4000), '/*--No Preparation--*/' )
			,SourceTableCondidtion = CONVERT(VARCHAR(4000), 'WHERE [TargetDate] BETWEEN ''#START_DATE#'' AND ''#END_DATE#'' ' )		
		FROM cteParam AS o
	)

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT x.[SchemaName] 
		,x.[TableName]
		,x.[QN_Table_FULL]
		,x.[QN_Table_PARTIAL]
		,x.[QN_Table_OVERLAP]
		,x.[QN_SourceTable]
		,x.[ValidationQuery]		
		,x.[IngestionQuery_FULL]
		,x.[IngestionQuery_PARTIAL]
		,x.[ExtractionQuery]
	FROM cteQuery AS o
	CROSS APPLY [V90_Core].[UTL].[GetLakeQuery_PARTIAL](o.[Lake] ,o.[SchemaName], o.[TableName]
	,o.[Source], o.[QN_SourceTable], o.[SourceTablePreparation], o.[SourceTableCondidtion]
    ,o.[StartDateStr], o.[EndDateStr], o.[TimeStampStr]
    ) AS x

/*#*==================== 🔚 ====================*#*/
GO

/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [V90_Core].[UTL].[FindX] '%Tran%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 10 * 
	FROM [APP].[TranDetail_OVERLAP]

*/
CREATE VIEW [APP].[TranDetail_OVERLAP]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/
	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteFull AS (
		SELECT o.[zID]
		, CONCAT_WS('+', o.[TranNo], o.[TranLineNo]) AS [BK_DE]
		FROM [APP].[TranDetail_FULL] AS o
	)
	, ctePartial AS (
		SELECT o.[zID]
		, CONCAT_WS('+', o.[TranNo], o.[TranLineNo]) AS [BK_DE]
		FROM [APP].[TranDetail_PARTIAL] AS o
	)
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT cfg.[BK_SRC_APP]
		,o.[zID] AS [zID]
		,x.[zID] AS [zID_PARTIAL]
		,CONCAT_WS('+', cfg.[BK_SRC_APP], o.[BK_DE]) AS [BK_DE]
		,o.[BK_DE] AS [CA_Memo]
	FROM cteFull AS o
	INNER JOIN ctePartial AS x ON o.[BK_DE] = x.[BK_DE]
	CROSS JOIN [AAL].[Setting] AS cfg

/*#*==================== 🔚 ====================*#*/
GO

/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [V90_Core].[UTL].[FindX] '%Tran%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 10 * 
	FROM [APP].[TranDetail_QUERY]

*/
CREATE VIEW [APP].[TranDetail_QUERY]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteParam AS (
		SELECT [Lake] = CONVERT(VARCHAR(100), DB_NAME())
			,[SchemaName] = o.[BK_SRC_APP]
			,[TableName] = CONVERT(VARCHAR(100), 'TranDetail')
			,[Source] = o.[BK_SRC_APP]
			,[QN_SourceTable] = CONVERT(VARCHAR(100), '[V90_Core].[SVC].[Sample_TranDetail]')
			,StartDateStr = FORMAT(o.[TranStartDate], o.[DateStrFormat])
			,EndDateStr = FORMAT(o.[TranEndDate], o.[DateStrFormat])
			,TimeStampStr = o.TimeStampStr
		FROM [AAL].[Setting] AS o
	)
	,cteQuery AS (
		SELECT o.*
			/*#*---------- 📌 DETAIL ----------*#*/
			,SourceTablePreparation = CONVERT(VARCHAR(4000), '; WITH x AS ( SELECT [TranNo],[TranDate] FROM [V90_Core].[SVC].[Sample_TranHeader] AS o WHERE [TranDate] BETWEEN ''#START_DATE#'' AND ''#END_DATE#'' ) ' )
			,SourceTableCondidtion = CONVERT(VARCHAR(4000), 'INNER JOIN x ON o.[TranNo] = x.[TranNo]; ' )		
		FROM cteParam AS o
	)

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT x.[SchemaName] 
		,x.[TableName]
		,x.[QN_Table_FULL]
		,x.[QN_Table_PARTIAL]
		,x.[QN_Table_OVERLAP]
		,x.[QN_SourceTable]
		,x.[ValidationQuery]		
		,x.[IngestionQuery_FULL]
		,x.[IngestionQuery_PARTIAL]
		,x.[ExtractionQuery]
	FROM cteQuery AS o
	CROSS APPLY [V90_Core].[UTL].[GetLakeQuery_PARTIAL](o.[Lake] ,o.[SchemaName], o.[TableName]
	,o.[Source], o.[QN_SourceTable], o.[SourceTablePreparation], o.[SourceTableCondidtion]
    ,o.[StartDateStr], o.[EndDateStr], o.[TimeStampStr]
    ) AS x

/*#*==================== 🔚 ====================*#*/
GO

/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [V90_Core].[UTL].[FindX] '%Tran%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 10 * 
	FROM [APP].[TranHeader_OVERLAP]

*/
CREATE VIEW [APP].[TranHeader_OVERLAP]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteFull AS (
		SELECT o.[zID]
		, CONCAT_WS('+', o.[TranNo], NULL) AS [BK_DE]
		FROM [APP].[TranHeader_FULL] AS o		
	)
	, ctePartial AS (
		SELECT o.[zID]
		, CONCAT_WS('+', o.[TranNo], NULL) AS [BK_DE]
		FROM [APP].[TranHeader_PARTIAL] AS o
	)
	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT cfg.[BK_SRC_APP]
		,o.[zID] AS [zID]
		,x.[zID] AS [zID_PARTIAL]
		,CONCAT_WS('+', cfg.[BK_SRC_APP], o.[BK_DE]) AS [BK_DE]
		,o.[BK_DE] AS [CA_Memo]
	FROM cteFull AS o
	INNER JOIN ctePartial AS x ON o.[BK_DE] = x.[BK_DE]
	CROSS JOIN [AAL].[Setting] AS cfg

/*#*==================== 🔚 ====================*#*/
GO

/*
	/*#*---------- 🔍 EXAMPLE: List Table Info ----------*#*/
	EXEC [V90_Core].[UTL].[FindX] '%Tran%';

	/*#*---------- 🧪 VALIDATION ----------*#*/
	SELECT TOP 10 * 
	FROM [APP].[TranHeader_QUERY]

*/
CREATE VIEW [APP].[TranHeader_QUERY]
AS
	/*#*========== 🎯 PURPOSE ==========*#*/

	/*#*========== 🧩 PREPARE ==========*#*/
	WITH cteParam AS (
		SELECT [Lake] = CONVERT(VARCHAR(100), DB_NAME())
			,[SchemaName] = o.[BK_SRC_APP]
			,[TableName] = CONVERT(VARCHAR(100), 'TranHeader')
			,[Source] = o.[BK_SRC_APP]
			,[QN_SourceTable] = CONVERT(VARCHAR(100), '[V90_Core].[SVC].[Sample_TranHeader]')
			,StartDateStr = FORMAT(o.[TranStartDate], o.[DateStrFormat])
			,EndDateStr = FORMAT(o.[TranEndDate], o.[DateStrFormat])
			,TimeStampStr = o.TimeStampStr
		FROM [AAL].[Setting] AS o
	)
	,cteQuery AS (
		SELECT o.*
			/*#*---------- 📌 DETAIL ----------*#*/
			,SourceTablePreparation = CONVERT(VARCHAR(4000), '/*--No Preparation--*/' )
			,SourceTableCondidtion = CONVERT(VARCHAR(4000), 'WHERE [TranDate] BETWEEN ''#START_DATE#'' AND ''#END_DATE#'' ' )		
		FROM cteParam AS o
	)

	/*#*========== ✅ OUTPUT ==========*#*/
	SELECT x.[SchemaName] 
		,x.[TableName]
		,x.[QN_Table_FULL]
		,x.[QN_Table_PARTIAL]
		,x.[QN_Table_OVERLAP]
		,x.[QN_SourceTable]
		,x.[ValidationQuery]		
		,x.[IngestionQuery_FULL]
		,x.[IngestionQuery_PARTIAL]
		,x.[ExtractionQuery]
	FROM cteQuery AS o
	CROSS APPLY [V90_Core].[UTL].[GetLakeQuery_PARTIAL](o.[Lake] ,o.[SchemaName], o.[TableName]
	,o.[Source], o.[QN_SourceTable], o.[SourceTablePreparation], o.[SourceTableCondidtion]
    ,o.[StartDateStr], o.[EndDateStr], o.[TimeStampStr]
    ) AS x

/*#*==================== 🔚 ====================*#*/
GO
