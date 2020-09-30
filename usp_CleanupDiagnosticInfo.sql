IF OBJECT_ID('usp_CleanupDiagnosticInfo') IS NOT NULL
    DROP PROCEDURE dbo.usp_CleanupDiagnosticInfo;
GO

CREATE PROCEDURE usp_CleanupDiagnosticInfo
(@Weeks INT NULL)
AS
BEGIN
    DECLARE @iWeeks INT = COALESCE(@Weeks, 4);

    IF OBJECT_ID('dbo.WaitStats') IS NOT NULL
    BEGIN
        DELETE dbo.WaitStats
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.IndexUsageStats') IS NOT NULL
    BEGIN
        DELETE dbo.IndexUsageStats
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.VersionInfo') IS NOT NULL
    BEGIN
        DELETE dbo.VersionInfo
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.ServerProperties') IS NOT NULL
    BEGIN
        DELETE dbo.ServerProperties
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.ConfigurationValues') IS NOT NULL
    BEGIN
        DELETE dbo.ConfigurationValues
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.GlobalTraceFlags') IS NOT NULL
    BEGIN
        DELETE dbo.GlobalTraceFlags
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.ProcessMemory') IS NOT NULL
    BEGIN
        DELETE dbo.ProcessMemory
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.SQLServerServicesInfo') IS NOT NULL
    BEGIN
        DELETE dbo.SQLServerServicesInfo
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.SQLServerAgentJobs') IS NOT NULL
    BEGIN
        DELETE dbo.SQLServerAgentJobs
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.SQLServerAgentAlerts') IS NOT NULL
    BEGIN
        DELETE dbo.SQLServerAgentAlerts
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.SQLServerNUMAInfo') IS NOT NULL
    BEGIN
        DELETE dbo.SQLServerNUMAInfo
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.SystemMemory') IS NOT NULL
    BEGIN
        DELETE dbo.SystemMemory
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.HardwareInfo') IS NOT NULL
    BEGIN
        DELETE dbo.HardwareInfo
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.MemoryDumpInfo') IS NOT NULL
    BEGIN
        DELETE dbo.MemoryDumpInfo
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.SuspectPages') IS NOT NULL
    BEGIN
        DELETE dbo.SuspectPages
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.DatabaseFilenamesAndPaths') IS NOT NULL
    BEGIN
        DELETE dbo.DatabaseFilenamesAndPaths
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.FixedDrives') IS NOT NULL
    BEGIN
        DELETE dbo.FixedDrives
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.VolumeInfo') IS NOT NULL
    BEGIN
        DELETE dbo.VolumeInfo
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.DriveLevelLatency') IS NOT NULL
    BEGIN
        DELETE dbo.DriveLevelLatency
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.IOLatencyByFile') IS NOT NULL
    BEGIN
        DELETE dbo.IOLatencyByFile
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.IOWarnings') IS NOT NULL
    BEGIN
        DELETE dbo.IOWarnings
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.DatabaseProperties') IS NOT NULL
    BEGIN
        DELETE dbo.DatabaseProperties
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.MissingIndexes') IS NOT NULL
    BEGIN
        DELETE dbo.MissingIndexes
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.VLFCounts') IS NOT NULL
    BEGIN
        DELETE dbo.VLFCounts
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.CPUUsageByDatabase') IS NOT NULL
    BEGIN
        DELETE dbo.CPUUsageByDatabase
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.IOUsageByDatabase') IS NOT NULL
    BEGIN
        DELETE dbo.IOUsageByDatabase
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.TotalBufferUsageByDatabase') IS NOT NULL
    BEGIN
        DELETE dbo.TotalBufferUsageByDatabase
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.TopWaits') IS NOT NULL
    BEGIN
        DELETE dbo.TopWaits
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.ConnectionCountsByIPAddress') IS NOT NULL
    BEGIN
        DELETE dbo.ConnectionCountsByIPAddress
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.CPUUtilizationHistory') IS NOT NULL
    BEGIN
        DELETE dbo.CPUUtilizationHistory
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.PLEByNUMANode') IS NOT NULL
    BEGIN
        DELETE dbo.PLEByNUMANode
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.MemoryClerkUsage') IS NOT NULL
    BEGIN
        DELETE dbo.MemoryClerkUsage
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.UDFStatsByDatabase') IS NOT NULL
    BEGIN
        DELETE dbo.UDFStatsByDatabase
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.WhoIsActive') IS NOT NULL
    BEGIN
        DELETE dbo.WhoIsActive
        WHERE collection_time < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.IdentityColumns') IS NOT NULL
    BEGIN
        DELETE dbo.IdentityColumns
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.DatabaseTriggers') IS NOT NULL
    BEGIN
        DELETE dbo.DatabaseTriggers
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;

    IF OBJECT_ID('dbo.PerformanceCounters') IS NOT NULL
    BEGIN
        DELETE dbo.PerformanceCounters
        WHERE CollectionDate < DATEADD(WEEK, -1 * @iWeeks, GETDATE());
    END;
END;