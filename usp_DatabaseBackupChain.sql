/********************************************************************************************************
    NAME:           usp_DatabaseBackupChain

    SYNOPSIS:       Creates a list of RESTORE statements that have to be executed in order to 
                    return to a particular point in time.

    DEPENDENCIES:   .
                    
	PARAMETERS:     Required:
					@DatabaseName must be provided in order to function correctly. 
           
					@RecoveryPoint is the point in time where to restore to
	
	NOTES:			Based on a script by Hugo Kornelis posted at:
                    https://sqlserverfast.com/blog/hugo/2020/09/t-sql-tuesday-120-automated-restores/

    AUTHOR:         Mark Boomaars
    
    CREATED:        2020-09-11
    
    VERSION:        1.0

    LICENSE:        MIT

    USAGE:          EXEC dbo.usp_DatabaseBackupChain @DatabaseName = 'Playground',
													 @RecoveryPoint = '2020-09-10T07:37:09';

	--------------------------------------------------------------------------------------------
	    DATE       VERSION     AUTHOR                DESCRIPTION                               
	--------------------------------------------------------------------------------------------
        20200911   1.0         Mark Boomaars		 Open Sourced on GitHub
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
    -- Just a few working variables (DO NOT CHANGE THESE!)
    -------------------------------------------------------------------------------
    DECLARE @PhysicalDeviceName NVARCHAR(255),
            @FullBackup DATETIME,
            @DiffBackup DATETIME,
            @LastLog DATETIME,
            @DataFileName sysname,
            @DataFilePath sysname,
            @LogFileName sysname,
            @LogFilePath sysname;

    -------------------------------------------------------------------------------
    -- Determine logical names and full paths for data and log files of the 
    -- specified database.
    -------------------------------------------------------------------------------
    SELECT @DataFileName = f.name,
           @DataFilePath
               = LEFT(f.physical_name, LEN(f.physical_name) - 4)
                 + REPLACE(RIGHT(f.physical_name, 4), '.', '_Restored.')
    FROM sys.master_files f
        INNER JOIN sys.databases d
            ON d.database_id = f.database_id
    WHERE d.name = @DatabaseName
          AND f.type_desc = 'ROWS';

    SELECT @LogFileName = f.name,
           @LogFilePath
               = LEFT(f.physical_name, LEN(f.physical_name) - 4)
                 + REPLACE(RIGHT(f.physical_name, 4), '.', '_Restored.')
    FROM sys.master_files f
        INNER JOIN sys.databases d
            ON d.database_id = f.database_id
    WHERE d.name = @DatabaseName
          AND f.type_desc = 'LOG';

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

    PRINT 'RESTORE DATABASE ' + @DatabaseName + '_Restored FROM DISK = ''' + @PhysicalDeviceName
          + ''' WITH FILE = 1, NORECOVERY, NOUNLOAD, REPLACE, STATS = 5, STOPAT = '''
          + CAST(@RecoveryPoint AS VARCHAR(50)) + ''', '
          + COALESCE('MOVE N''' + @DataFileName + ''' TO N''' + @DataFilePath + ''',', '') + N'MOVE N''' + @LogFileName
          + N''' TO N''' + @LogFilePath + N''';';

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
    -- Perform the recovery.
    -------------------------------------------------------------------------------
    PRINT 'RESTORE DATABASE ' + @DatabaseName + '_Restored WITH RECOVERY;';
END;
GO
