/********************************************************************************************************
    
    NAME:           usp_RebuildHeaps

    SYNOPSIS:       A heap is a table without a clustered index. This proc can be used to 
                    rebuild those heaps on a database. Thereby alleviating the problems that arise 
                    from large numbers of forwarding records on a heap.

    DEPENDENCIES:   .

	PARAMETERS:     Required:
                    @DatabaseName specifies on which database the heaps should be rebuilt.
                    
                    Optional:
                    @MinNumberOfPages specifies the minimum number of pages required on the heap
                    to be taken into account

                    @ProcessHeapCount specifies the number of heaps that should be rebuild. 
                    Processing large heaps can have a negative effect on the performance
                    of your system. Also be aware that your logshipping processes can be greatly
                    affected by rebuilding heaps as all changes need to be replicated.

                    @DryRun specifies whether the actual query should be executed or just 
                    printed to the screen
	
	NOTES:			

    AUTHOR:         Mark Boomaars, http://www.bravisziekenhuis.nl
    
    CREATED:        2020-01-03
    
    VERSION:        1.0

    LICENSE:        MIT
    
    USAGE:          EXEC dbo.usp_RebuildHeaps
                        @DatabaseName = 'HIX_PRODUCTIE', 
						@@DryRun = 0;

    -----------------------------------------------------------------------------------------------
     DATE       VERSION     AUTHOR                  DESCRIPTION
    -----------------------------------------------------------------------------------------------
     20200103   1.0         Mark Boomaars			Open Sourced on GitHub
     20200831   1.1         Mark Boomaars           Changes to logic and logging

*********************************************************************************************************/

CREATE OR ALTER PROC dbo.usp_RebuildHeaps
    @DatabaseName NVARCHAR(100),
    @MinNumberOfPages INT = 0,
    @ProcessHeapCount INT = 2,
    @DryRun TINYINT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET ARITHABORT ON;
    SET NUMERIC_ROUNDABORT OFF;

    DECLARE @db_id INT,
            @db_name sysname = @DatabaseName,
            @object_id INT,
            @schema_name sysname,
            @table_name sysname,
            @page_count BIGINT,
            @record_count BIGINT,
            @forwarded_record_count BIGINT,
            @forwarded_record_percent DECIMAL(10, 2),
            @sql NVARCHAR(MAX),
            @msg NVARCHAR(MAX),
            @EndMessage NVARCHAR(MAX),
            @ErrorMessage NVARCHAR(MAX),
            @EmptyLine NVARCHAR(MAX) = CHAR(9),
            @Error INT = 0,
            @ReturnCode INT = 0;

    IF @DatabaseName IS NULL
    BEGIN
        SET @ErrorMessage = N'The @DatabaseName parameter must be specified and cannot be NULL. Stopping execution...';
        RAISERROR('%s', 16, 1, @ErrorMessage) WITH NOWAIT;
        SET @Error = @@ERROR;
        RAISERROR(@EmptyLine, 10, 1) WITH NOWAIT;
    END;

    IF @Error <> 0
    BEGIN
        SET @ReturnCode = @Error;
        GOTO Logging;
    END;

    -------------------------------------------------------------------------------
    -- Preparing our working table
    -------------------------------------------------------------------------------
    IF OBJECT_ID(N'FragmentedHeaps', N'U') IS NULL
    BEGIN
        RAISERROR('Preparing our working table', 10, 1) WITH NOWAIT;

        CREATE TABLE dbo.FragmentedHeaps
        (
            object_id INT NOT NULL,
            page_count BIGINT NOT NULL,
            record_count BIGINT NOT NULL,
            forwarded_record_count BIGINT NOT NULL,
            forwarded_record_percent DECIMAL(10, 2)
        );

        DECLARE heapdb CURSOR STATIC FOR
        SELECT d.database_id,
               d.name
        FROM sys.databases AS d
        WHERE d.name = @db_name;

        OPEN heapdb;

        WHILE 1 = 1
        BEGIN
            FETCH NEXT FROM heapdb
            INTO @db_id,
                 @db_name;

            IF @@FETCH_STATUS <> 0
                BREAK;

            -- Loop through all heaps
            RAISERROR('Looping through all heaps', 10, 1) WITH NOWAIT;

            SET @sql
                = N'DECLARE heaps CURSOR GLOBAL STATIC FOR
                SELECT i.object_id 
                FROM ' + QUOTENAME(@db_name) + N'.sys.indexes AS i 
                INNER JOIN ' + QUOTENAME(@db_name)
                  + N'.sys.objects AS o ON o.object_id = i.object_id
                WHERE i.type_desc = ''HEAP'' AND o.type_desc = ''USER_TABLE''';
            --RAISERROR(@sql, 10, 1) WITH NOWAIT;
            EXECUTE sp_executesql @stmt = @sql;

            OPEN heaps;

            WHILE 1 = 1
            BEGIN
                FETCH NEXT FROM heaps
                INTO @object_id;

                IF @@FETCH_STATUS <> 0
                    BREAK;

                INSERT INTO dbo.FragmentedHeaps
                (
                    object_id,
                    page_count,
                    record_count,
                    forwarded_record_count,
                    forwarded_record_percent
                )
                SELECT P.object_id,
                       P.page_count,
                       P.record_count,
                       P.forwarded_record_count,
                       (CAST(P.forwarded_record_count AS DECIMAL(10, 2)) / CAST(P.record_count AS DECIMAL(10, 2)))
                       * 100
                FROM sys.dm_db_index_physical_stats(DB_ID(@db_name), @object_id, 0, NULL, 'DETAILED') AS P
                WHERE P.page_count > @MinNumberOfPages
                      AND P.forwarded_record_count > 0;
            END;

            CLOSE heaps;
            DEALLOCATE heaps;
        END;

        CLOSE heapdb;
        DEALLOCATE heapdb;
    END;

    -------------------------------------------------------------------------------
    -- Starting actual hard work
    -------------------------------------------------------------------------------
    IF @DryRun = 1
        RAISERROR('Performing a dry run. Nothing will be executed or logged...', 10, 1) WITH NOWAIT;

    RAISERROR('Starting actual hard work', 10, 1) WITH NOWAIT;

    SELECT @db_id = d.database_id
    FROM sys.databases AS d
    WHERE d.name = @db_name;

    DECLARE worklist CURSOR STATIC FOR
    SELECT TOP (@ProcessHeapCount)
           object_id,
           page_count,
           record_count,
           forwarded_record_count,
           forwarded_record_percent
    FROM dbo.FragmentedHeaps
    ORDER BY forwarded_record_percent DESC;

    OPEN worklist;

    WHILE 1 = 1
    BEGIN
        FETCH NEXT FROM worklist
        INTO @object_id,
             @page_count,
             @record_count,
             @forwarded_record_count,
             @forwarded_record_percent;

        IF @@FETCH_STATUS <> 0
            BREAK;

        SET @schema_name = OBJECT_SCHEMA_NAME(@object_id, @db_id);
        SET @table_name = OBJECT_NAME(@object_id, @db_id);
        SET @msg
            = CONCAT(
                        'Rebuilding [',
                        @db_name,
                        '].[',
                        @schema_name,
                        '].[',
                        @table_name,
                        '] because of ',
                        @forwarded_record_count,
                        ' forwarded records (',
                        @forwarded_record_percent,
                        ')'
                    );

        RAISERROR(@msg, 10, 1) WITH NOWAIT;

        SET @sql
            = N'ALTER TABLE ' + QUOTENAME(@db_name) + N'.' + QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name)
              + N' REBUILD WITH (ONLINE = ON);';
        IF @DryRun = 0
            EXECUTE sp_executesql @stmt = @sql;

        RAISERROR(@sql, 10, 1) WITH NOWAIT; -- Log executed command

        -- Remove processed heap from working table
        IF @DryRun = 0
        BEGIN
            DELETE FROM dbo.FragmentedHeaps
            WHERE object_id = @object_id;

            RAISERROR('Removing heap from working table', 10, 1) WITH NOWAIT;
        END;
    END;

    CLOSE worklist;
    DEALLOCATE worklist;

    -- Delete working table when no rows present
    IF @DryRun = 0
    BEGIN
        DECLARE @rows INT = 0;
        SELECT @rows = COUNT(*)
        FROM dbo.FragmentedHeaps;

        IF @rows = 0
        BEGIN
            DROP TABLE dbo.FragmentedHeaps;
            RAISERROR('No rows in table. Cleaning up...', 10, 1) WITH NOWAIT;
        END;
    END;

    ----------------------------------------------------------------------------------------------------
    -- Log information
    ----------------------------------------------------------------------------------------------------

    Logging:
    SET @EndMessage = N'Date and time: ' + CONVERT(NVARCHAR, GETDATE(), 120);
    RAISERROR('%s', 10, 1, @EndMessage) WITH NOWAIT;

    RAISERROR(@EmptyLine, 10, 1) WITH NOWAIT;

    IF @ReturnCode <> 0
    BEGIN
        RETURN @ReturnCode;
    END;

END;