/********************************************************************************************************
    NAME:           usp_ReadCommandLog

    SYNOPSIS:       Retrieves information from Ola Hallengren's Command Log table.

    DEPENDENCIES:   Ola Hallengren's maintenance solution must be present.
                    
	PARAMETERS:     Required:
					@DatabaseName must be provided in order to function correctly. 
            
                    Optional:
					@Days can be provided to go back in time further. Defaults to 1.
	
	NOTES:			

    AUTHOR:         Mark Boomaars, http://www.bravisziekenhuis.nl
    
    CREATED:        2020-08-31
    
    VERSION:        1.0

    LICENSE:        MIT
    
    USAGE:          EXEC dbo.usp_ReadCommandLog
                        @DatabaseName = 'HIX_PRODUCTIE', 
						@Days = 7; -- Shows all work done in the past week

 ---------------------------------------------------------------------------------------------------------
 --  DATE       VERSION     AUTHOR                  DESCRIPTION                                        --
 ---------------------------------------------------------------------------------------------------------
     20200831   1.0         Mark Boomaars			Open Sourced on GitHub
*********************************************************************************************************/

CREATE OR ALTER PROC dbo.usp_ReadCommandLog (
	@DatabaseName sysname,
    @Days         INT = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------------------------------------
    -- Indexes
    -------------------------------------------------------------------------------
    SELECT StartTime,
           EndTime,
           DATEDIFF(SECOND, StartTime, EndTime) AS DurationInSec,
           CONCAT(QUOTENAME(ObjectName), '.', QUOTENAME(IndexName)) AS [Index],
           CASE IndexType
               WHEN 1 THEN
                   'Clustered'
               WHEN 2 THEN
                   'Nonclustered'
               ELSE
                   'Heap'
           END AS IndexType,
           ExtendedInfo.value('(/ExtendedInfo/PageCount/text())[1]', 'int') AS [Pages],
           ExtendedInfo.value('(/ExtendedInfo/Fragmentation/text())[1]', 'float') AS [Fragmentation],
           ROW_NUMBER() OVER (PARTITION BY CONCAT(QUOTENAME(ObjectName), '.', QUOTENAME(IndexName))
                              ORDER BY CONCAT(QUOTENAME(ObjectName), '.', QUOTENAME(IndexName)),
                                       StartTime
                        ) AS Execution,
           Command
    FROM [dbo].[CommandLog]
    WHERE DatabaseName = @DatabaseName
          AND CommandType = 'ALTER_INDEX'
          AND DATEDIFF(DAY, StartTime, GETDATE()) < @Days;

    -------------------------------------------------------------------------------
    -- Statistics
    -------------------------------------------------------------------------------
    SELECT StartTime,
           EndTime,
           DATEDIFF(SECOND, StartTime, EndTime) AS DurationInSec,
           CONCAT(QUOTENAME(ObjectName), '.', QUOTENAME(StatisticsName)) AS [Statistic],
           ExtendedInfo.value('(/ExtendedInfo/RowCount/text())[1]', 'int') AS [Rows],
           ExtendedInfo.value('(/ExtendedInfo/ModificationCounter/text())[1]', 'float') AS [Modifications],
           ROW_NUMBER() OVER (PARTITION BY CONCAT(QUOTENAME(ObjectName), '.', QUOTENAME(StatisticsName))
                              ORDER BY CONCAT(QUOTENAME(ObjectName), '.', QUOTENAME(StatisticsName)),
                                       StartTime
                        ) AS Execution,
           'USE ' + @DatabaseName + '; DBCC SHOW_STATISTICS(''' + ObjectName + ''', ' + StatisticsName
           + '); SELECT * FROM sys.stats AS stat CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp WHERE stat.object_id = OBJECT_ID('''
           + ObjectName + ''') AND stat.name = ''' + '' + StatisticsName + ''';' AS StatInfo
    FROM [dbo].[CommandLog]
    WHERE DatabaseName = @DatabaseName
          AND CommandType = 'UPDATE_STATISTICS'
          AND DATEDIFF(DAY, StartTime, GETDATE()) < @Days;
END;
GO