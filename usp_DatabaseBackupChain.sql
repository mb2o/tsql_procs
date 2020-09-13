/********************************************************************************************************
    
    NAME:           usp_DatabaseBackupChain

    SYNOPSIS:       Creates a list of RESTORE statements that have to be executed in order to 
                    return to a particular point in time.

    DEPENDENCIES:   .
                    
	PARAMETERS:     Required:
					@DatabaseName must be provided in order to function correctly. 
           
					@RecoveryPoint is the point in time to where the database must be restored
	
	NOTES:			Based on a script posted by Hugo Kornelis at:
                    https://sqlserverfast.com/blog/hugo/2020/09/t-sql-tuesday-120-automated-restores/

    AUTHOR:         Mark Boomaars
    
    CREATED:        2020-09-11
    
    VERSION:        1.0

    LICENSE:        MIT

    USAGE:          EXEC dbo.usp_DatabaseBackupChain @DatabaseName = 'AdventureWorks',
													 @RecoveryPoint = '2020-09-10T07:37:09';

	--------------------------------------------------------------------------------------------
	    DATE       VERSION     AUTHOR               DESCRIPTION                               
	--------------------------------------------------------------------------------------------
        20200911   1.0         Mark Boomaars		Open Sourced on GitHub

*********************************************************************************************************/

CREATE OR ALTER PROCEDURE usp_DatabaseBackupChain
(
    @DatabaseName sysname,
    @RecoveryPoint DATETIME
)
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------------------------------------
    -- Just a few working variables (DO NOT CHANGE THESE !)
    -------------------------------------------------------------------------------
    DECLARE @DiffBackup DATETIME,
            @FileName NVARCHAR(255),
            @FilePath NVARCHAR(255),
            @FullBackup DATETIME,
            @LastLog DATETIME,
            @Cur CURSOR,
            @PhysicalDeviceName NVARCHAR(255),
            @SQL NVARCHAR(MAX) = N'';

    -------------------------------------------------------------------------------
    -- Find last full backup before recovery point and then restore it.
    -------------------------------------------------------------------------------
    SELECT TOP (1)
           @PhysicalDeviceName = bmf.physical_device_name,
           @FullBackup = bs.backup_start_date
    FROM msdb.dbo.backupset AS bs
        INNER JOIN msdb.dbo.backupmediafamily AS bmf
            ON bmf.media_set_id = bs.media_set_id
    WHERE bs.database_name = @DatabaseName
          AND bs.type = 'D'
          AND bs.backup_start_date < @RecoveryPoint
    ORDER BY bs.backup_start_date DESC;

    SET @SQL += N'RESTORE DATABASE ' + @DatabaseName + N'_Restored FROM DISK = ''' + @PhysicalDeviceName
                + N''' WITH FILE = 1, NORECOVERY, NOUNLOAD, REPLACE, STATS = 5, STOPAT = '''
                + CAST(@RecoveryPoint AS VARCHAR(50)) + N'''';

    BEGIN
        SET @Cur = CURSOR FOR
        SELECT f.name,
               f.physical_name
        FROM sys.master_files f
            INNER JOIN sys.databases d
                ON d.database_id = f.database_id
        WHERE d.name = @DatabaseName;

        OPEN @Cur;
        FETCH NEXT FROM @Cur
        INTO @FileName,
             @FilePath;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @SQL += COALESCE(', MOVE N''' + @FileName + ''' TO N''' + 
						LEFT(@FilePath, LEN(@FilePath) - 4) + 
						REPLACE(RIGHT(@FilePath, 4), '.', '_Restored.') + '''', '');

            FETCH NEXT FROM @Cur
            INTO @FileName,
                 @FilePath;
        END;

        CLOSE @Cur;
        DEALLOCATE @Cur;
    END;

    PRINT @SQL;

    -------------------------------------------------------------------------------
    -- Find last differential backup before recovery point and restore it.
    -------------------------------------------------------------------------------
    SELECT TOP (1)
           @PhysicalDeviceName = bmf.physical_device_name,
           @DiffBackup = bs.backup_start_date
    FROM msdb.dbo.backupset AS bs
        INNER JOIN msdb.dbo.backupmediafamily AS bmf
            ON bmf.media_set_id = bs.media_set_id
    WHERE bs.database_name = @DatabaseName
          AND bs.type = 'I'
          AND bs.backup_start_date >= @FullBackup
          AND bs.backup_start_date < @RecoveryPoint
    ORDER BY bs.backup_start_date DESC;

    IF @@ROWCOUNT > 0
    BEGIN;
        PRINT 'RESTORE DATABASE ' + @DatabaseName + '_Restored FROM DISK = ''' + @PhysicalDeviceName
              + ''' WITH FILE = 1, NORECOVERY, NOUNLOAD, REPLACE, STATS = 5, STOPAT = '''
              + CAST(@RecoveryPoint AS VARCHAR(50)) + ''';';
    END;

    -------------------------------------------------------------------------------
    -- Find all log backups taken after the restored differential or full backup 
    -- and restore them until we are past the recovery point.
    -------------------------------------------------------------------------------
    DECLARE c CURSOR LOCAL FAST_FORWARD READ_ONLY TYPE_WARNING FOR
    SELECT bmf.physical_device_name,
           bs.backup_start_date
    FROM msdb.dbo.backupset AS bs
        INNER JOIN msdb.dbo.backupmediafamily AS bmf
            ON bmf.media_set_id = bs.media_set_id
    WHERE bs.database_name = @DatabaseName
          AND bs.type = 'L'
          AND bs.backup_start_date >= COALESCE(@DiffBackup, @FullBackup)
    ORDER BY bs.backup_start_date ASC;

    OPEN c;

    FETCH NEXT FROM c
    INTO @PhysicalDeviceName,
         @LastLog;

    WHILE @@FETCH_STATUS = 0
    BEGIN;
        IF @LastLog > @RecoveryPoint
            BREAK;

        FETCH NEXT FROM c
        INTO @PhysicalDeviceName,
             @LastLog;

        PRINT 'RESTORE LOG ' + @DatabaseName + '_Restored FROM DISK = ''' + @PhysicalDeviceName
              + ''' WITH FILE = 1, NORECOVERY, NOUNLOAD, REPLACE, STATS = 5, STOPAT = '''
              + CAST(@RecoveryPoint AS VARCHAR(50)) + ''';';

    END;

    CLOSE c;
    DEALLOCATE c;

    -------------------------------------------------------------------------------
    -- Perform final recovery.
    -------------------------------------------------------------------------------
    PRINT 'RESTORE DATABASE ' + @DatabaseName + '_Restored WITH RECOVERY;';
END;
GO
