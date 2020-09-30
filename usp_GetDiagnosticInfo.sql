/* --------------------------------------------------
 Prerequisites:

 – Install sp_whoisactive
-------------------------------------------------- */

IF OBJECT_ID('usp_GetDiagnosticInfo') IS NOT NULL
    DROP PROCEDURE dbo.usp_GetDiagnosticInfo;
GO

CREATE PROCEDURE dbo.usp_GetDiagnosticInfo
AS
BEGIN

    SET QUOTED_IDENTIFIER ON;

    -------------------------------------------------------------------------------
    -- Collect index usage statistics
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.IndexUsageStats') IS NULL
    BEGIN
        CREATE TABLE dbo.IndexUsageStats
        (
            [CollectionDate] [DATETIME2](0) NOT NULL,
            [ServerName] [sysname] NOT NULL,
            [DatabaseName] [sysname] NOT NULL,
            [SchemaName] [sysname] NOT NULL,
            [TableName] [sysname] NOT NULL,
            [IndexName] [sysname] NULL,
            [User_Seeks] [BIGINT] NOT NULL,
            [User_Scans] [BIGINT] NOT NULL,
            [User_Lookups] [BIGINT] NOT NULL,
            [User_Updates] [BIGINT] NOT NULL,
            [System_Seeks] [BIGINT] NOT NULL,
            [System_Scans] [BIGINT] NOT NULL,
            [System_Lookups] [BIGINT] NOT NULL,
            [System_Updates] [BIGINT] NOT NULL
        ) ON [PRIMARY];
    END;

    -- get current stats for all online databases
    SELECT database_id,
           name
    INTO #dblist
    FROM sys.databases
    WHERE [state] = 0
          AND database_id <> 2; -- skip TempDB

    CREATE TABLE #t1
    (
        [CollectionDate] DATETIME2(0),
        ServerName sysname,
        DatabaseName sysname,
        SchemaName sysname,
        TableName sysname,
        IndexName sysname NULL,
        User_Seeks BIGINT,
        User_Scans BIGINT,
        User_Lookups BIGINT,
        User_Updates BIGINT,
        System_Seeks BIGINT,
        System_Scans BIGINT,
        System_Lookups BIGINT,
        System_Updates BIGINT
    );

    DECLARE @DBID INT;
    DECLARE @DBNAME sysname;
    DECLARE @Qry NVARCHAR(2000);

    -- iterate through each DB, generate & run query
    WHILE
    (SELECT COUNT(*) FROM #dblist) > 0
    BEGIN
        SELECT TOP (1)
               @DBID = database_id,
               @DBNAME = [name]
        FROM #dblist
        ORDER BY database_id;

        SET @Qry
            = N'
					INSERT INTO #t1
					SELECT
					  GETDATE() AS [CollectionDate],
					  @@SERVERNAME AS ServerName,
					  ''' + @DBNAME
              + N''' AS DatabaseName,
					  c.name AS SchemaName,
					  o.name AS TableName,
					  i.name AS IndexName,
					  s.user_seeks,
					  s.user_scans,
					  s.user_lookups,
					  s.user_updates,
					  s.system_seeks,
					  s.system_scans,
					  s.system_lookups,
					  s.system_updates
					FROM sys.dm_db_index_usage_stats s
					INNER JOIN ' + @DBNAME + N'.sys.objects o ON s.object_id = o.object_id
					INNER JOIN ' + @DBNAME + N'.sys.schemas c ON o.schema_id = c.schema_id
					INNER JOIN ' + @DBNAME
              + N'.sys.indexes i ON s.object_id = i.object_id and s.index_id = i.index_id
					WHERE s.database_id = ' + CONVERT(NVARCHAR, @DBID) + N';';

        EXEC sp_executesql @Qry;

        DELETE FROM #dblist
        WHERE database_id = @DBID;
    END; -- db while loop

    -- Calculate Deltas
    INSERT INTO dbo.IndexUsageStats
    (
        [CollectionDate],
        ServerName,
        DatabaseName,
        SchemaName,
        TableName,
        IndexName,
        User_Seeks,
        User_Scans,
        User_Lookups,
        User_Updates,
        System_Seeks,
        System_Scans,
        System_Lookups,
        System_Updates
    )
    SELECT t.[CollectionDate],
           t.ServerName,
           t.DatabaseName,
           t.SchemaName,
           t.TableName,
           t.IndexName,
           t.User_Seeks,
           t.User_Scans,
           t.User_Lookups,
           t.User_Updates,
           t.System_Seeks,
           t.System_Scans,
           t.System_Lookups,
           t.System_Updates
    FROM #t1 t
    ORDER BY [CollectionDate],
             ServerName;

    DROP TABLE #t1;
    DROP TABLE #dblist;

    -------------------------------------------------------------------------------
    -- SQL and OS Version information for current instance  (Query 1) (Version Info)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.VersionInfo') IS NULL
    BEGIN
        CREATE TABLE dbo.VersionInfo
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [ServerName] NVARCHAR(100) NOT NULL,
            [SQL Server and OS Version Info] NVARCHAR(MAX) NOT NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.VersionInfo
    (
        CollectionDate,
        ServerName,
        [SQL Server and OS Version Info]
    )
    SELECT GETDATE(),
           @@SERVERNAME,
           @@VERSION;

    -------------------------------------------------------------------------------
    -- Get selected server properties (Query 3) (Server Properties)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.ServerProperties') IS NULL
    BEGIN
        CREATE TABLE dbo.ServerProperties
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [MachineName] SQL_VARIANT NOT NULL,
            [ServerName] SQL_VARIANT NOT NULL,
            [Instance] SQL_VARIANT NULL,
            [IsClustered] SQL_VARIANT NOT NULL,
            [ComputerNamePhysicalNetBIOS] SQL_VARIANT NOT NULL,
            [Edition] SQL_VARIANT NOT NULL,
            [ProductLevel] SQL_VARIANT NULL,
            [ProductUpdateLevel] SQL_VARIANT NULL,
            [ProductVersion] SQL_VARIANT NULL,
            [ProductMajorVersion] SQL_VARIANT NULL,
            [ProductMinorVersion] SQL_VARIANT NULL,
            [ProductBuild] SQL_VARIANT NULL,
            [ProductBuildType] SQL_VARIANT NULL,
            [ProductUpdateReference] SQL_VARIANT NOT NULL,
            [ProcessID] SQL_VARIANT NOT NULL,
            [Collation] SQL_VARIANT NOT NULL,
            [IsFullTextInstalled] SQL_VARIANT NOT NULL,
            [IsIntegratedSecurityOnly] SQL_VARIANT NOT NULL,
            [FilestreamConfiguredLevel] SQL_VARIANT NOT NULL,
            [IsHadrEnabled] SQL_VARIANT NOT NULL,
            [HadrManagerStatus] SQL_VARIANT NOT NULL,
            [InstanceDefaultDataPath] SQL_VARIANT NOT NULL,
            [InstanceDefaultLogPath] SQL_VARIANT NOT NULL,
            InstanceDefaultBackupPath SQL_VARIANT NOT NULL,
            [Build CLR Version] SQL_VARIANT NOT NULL,
            [IsXTPSupported] SQL_VARIANT NOT NULL,
            [IsPolybaseInstalled] SQL_VARIANT NOT NULL,
            [IsRServicesInstalled] SQL_VARIANT NOT NULL,
            [IsTempdbMetadataMemoryOptimized] SQL_VARIANT NOT NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.ServerProperties
    (
        CollectionDate,
        MachineName,
        ServerName,
        Instance,
        IsClustered,
        ComputerNamePhysicalNetBIOS,
        Edition,
        ProductLevel,
        ProductUpdateLevel,
        ProductVersion,
        ProductMajorVersion,
        ProductMinorVersion,
        ProductBuild,
        ProductBuildType,
        ProductUpdateReference,
        ProcessID,
        Collation,
        IsFullTextInstalled,
        IsIntegratedSecurityOnly,
        FilestreamConfiguredLevel,
        IsHadrEnabled,
        HadrManagerStatus,
        InstanceDefaultDataPath,
        InstanceDefaultLogPath,
        InstanceDefaultBackupPath,
        [Build CLR Version],
        IsXTPSupported,
        IsPolybaseInstalled,
        IsRServicesInstalled,
        IsTempdbMetadataMemoryOptimized
    )
    SELECT GETDATE() AS CollectionDate,
           SERVERPROPERTY('MachineName'),
           SERVERPROPERTY('ServerName'),
           SERVERPROPERTY('InstanceName'),
           SERVERPROPERTY('IsClustered'),
           SERVERPROPERTY('ComputerNamePhysicalNetBIOS'),
           SERVERPROPERTY('Edition'),
           SERVERPROPERTY('ProductLevel'), -- What servicing branch (RTM/SP/CU)
           SERVERPROPERTY('ProductUpdateLevel'), -- Within a servicing branch, what CU# is applied
           SERVERPROPERTY('ProductVersion') ,
           SERVERPROPERTY('ProductMajorVersion') ,
           SERVERPROPERTY('ProductMinorVersion'),
           SERVERPROPERTY('ProductBuild'),
           SERVERPROPERTY('ProductBuildType'), -- Is this a GDR or OD hotfix (NULL if on a CU build)
           SERVERPROPERTY('ProductUpdateReference'), -- KB article number that is applicable for this build
           SERVERPROPERTY('ProcessID'),
           SERVERPROPERTY('Collation'),
           SERVERPROPERTY('IsFullTextInstalled'),
           SERVERPROPERTY('IsIntegratedSecurityOnly'),
           SERVERPROPERTY('FilestreamConfiguredLevel'),
           SERVERPROPERTY('IsHadrEnabled'),
           SERVERPROPERTY('HadrManagerStatus'),
           SERVERPROPERTY('InstanceDefaultDataPath'),
           SERVERPROPERTY('InstanceDefaultLogPath'),
           SERVERPROPERTY('InstanceDefaultBackupPath'),
           SERVERPROPERTY('BuildClrVersion'),
           SERVERPROPERTY('IsXTPSupported'),
           SERVERPROPERTY('IsPolybaseInstalled'),
           SERVERPROPERTY('IsAdvancedAnalyticsInstalled'),
           SERVERPROPERTY('IsTempdbMetadataMemoryOptimized');

    -------------------------------------------------------------------------------
    -- Get instance-level configuration values for instance  (Query 4) (Configuration Values)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.ConfigurationValues') IS NULL
    BEGIN
        CREATE TABLE dbo.ConfigurationValues
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [Name] NVARCHAR(35) NOT NULL,
            [Value] SQL_VARIANT NULL,
            [ValueInUse] SQL_VARIANT NULL,
            [Minimum] SQL_VARIANT NULL,
            [Maximum] SQL_VARIANT NULL,
            [Description] NVARCHAR(255) NULL,
            [IsDynamic] BIT NOT NULL,
            [IsAdvanced] BIT NOT NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.ConfigurationValues
    (
        CollectionDate,
        [Name],
        [Value],
        ValueInUse,
        Minimum,
        Maximum,
        [Description],
        IsDynamic,
        IsAdvanced
    )
    SELECT GETDATE() AS CollectionDate,
           [name],
           [value],
           value_in_use,
           minimum,
           maximum,
           [description],
           is_dynamic,
           is_advanced
    FROM sys.configurations WITH (NOLOCK)
    ORDER BY name
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Returns global trace flags that are enabled (Query 5) (Global Trace Flags)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.GlobalTraceFlags') IS NULL
    BEGIN
        CREATE TABLE dbo.GlobalTraceFlags
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [TraceFlag] NVARCHAR(35) NOT NULL,
            [Status] BIT NOT NULL,
            [Global] BIT NOT NULL,
            [Session] BIT NOT NULL
        ) ON [PRIMARY];
    END;

    CREATE TABLE #tracestatus
    (
        [TraceFlag] INT,
        [Status] INT,
        [Global] BIT,
        [Session] BIT
    );

    INSERT INTO #tracestatus
    EXEC ('DBCC TRACESTATUS (-1) WITH NO_INFOMSGS');

    INSERT INTO dbo.GlobalTraceFlags
    (
        [CollectionDate],
        [TraceFlag],
        [Status],
        [Global],
        [Session]
    )
    SELECT GETDATE(),
           [TraceFlag],
           [Status],
           [Global],
           [Session]
    FROM #tracestatus;

    DROP TABLE #tracestatus;

    -------------------------------------------------------------------------------
    -- SQL Server Process Address space info  (Query 6) (Process Memory)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.ProcessMemory') IS NULL
    BEGIN
        CREATE TABLE dbo.ProcessMemory
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [SQL Server Memory Usage (MB)] BIGINT NOT NULL,
            [SQL Server Locked Pages Allocation (MB)] BIGINT NOT NULL,
            [SQL Server Large Pages Allocation (MB)] BIGINT NOT NULL,
            [Page Fault Count] BIGINT NOT NULL,
            [Memory Utilization Percentage] INT NOT NULL,
            [Available Commit Limit (KB)] BIGINT NOT NULL,
            [Process Physical Memory Low] BIT NOT NULL,
            [Process Virtual Memory Low] BIT NOT NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.ProcessMemory
    (
        [CollectionDate],
        [SQL Server Memory Usage (MB)],
        [SQL Server Locked Pages Allocation (MB)],
        [SQL Server Large Pages Allocation (MB)],
        [Page Fault Count],
        [Memory Utilization Percentage],
        [Available Commit Limit (KB)],
        [Process Physical Memory Low],
        [Process Virtual Memory Low]
    )
    SELECT GETDATE() AS CollectionDate,
           physical_memory_in_use_kb / 1024,
           locked_page_allocations_kb / 1024,
           large_page_allocations_kb / 1024,
           page_fault_count,
           memory_utilization_percentage,
           available_commit_limit_kb,
           process_physical_memory_low,
           process_virtual_memory_low
    FROM sys.dm_os_process_memory WITH (NOLOCK)
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- SQL Server Services information (Query 7) (SQL Server Services Info)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.SQLServerServicesInfo') IS NULL
    BEGIN
        CREATE TABLE dbo.SQLServerServicesInfo
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [ServiceName] NVARCHAR(256) NOT NULL,
            [ProcessID] INT NOT NULL,
            [StartupTypeDescription] NVARCHAR(256) NULL,
            [StatusDescription] NVARCHAR(256) NULL,
            [LastStartupTime] DATETIMEOFFSET(7) NULL,
            [ServiceAccount] NVARCHAR(256) NOT NULL,
            IsClustered NVARCHAR(1) NOT NULL,
            ClusterNodeName NVARCHAR(256) NULL,
            [Filename] NVARCHAR(256) NOT NULL,
            [InstantFileInitializationEnabled] NVARCHAR(256) NOT NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.SQLServerServicesInfo
    (
        CollectionDate,
        ServiceName,
        ProcessID,
        StartupTypeDescription,
        StatusDescription,
        LastStartupTime,
        ServiceAccount,
        IsClustered,
        ClusterNodeName,
        Filename,
        InstantFileInitializationEnabled
    )
    SELECT GETDATE(),
           servicename,
           process_id,
           startup_type_desc,
           status_desc,
           last_startup_time,
           service_account,
           is_clustered,
           cluster_nodename,
           [filename],
           instant_file_initialization_enabled
    FROM sys.dm_server_services WITH (NOLOCK)
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Get SQL Server Agent jobs and Category information (Query 9) (SQL Server Agent Jobs)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.SQLServerAgentJobs') IS NULL
    BEGIN
        CREATE TABLE dbo.SQLServerAgentJobs
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [JobName] sysname NOT NULL,
            [JobDescription] NVARCHAR(512) NULL,
            [JobOwner] NVARCHAR(256) NOT NULL,
            [DateCreated] DATETIME NOT NULL,
            [JobEnabled] TINYINT NOT NULL,
            NotifyEmailOperatorID INT NOT NULL,
            NotifyLevelEmail INT NOT NULL,
            [CategoryName] sysname NOT NULL,
            [ScheduleEnabled] INT NULL,
            NextRunDate INT NULL,
            NextRunTime INT NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.SQLServerAgentJobs
    (
        CollectionDate,
        JobName,
        JobDescription,
        JobOwner,
        DateCreated,
        JobEnabled,
        NotifyEmailOperatorID,
        NotifyLevelEmail,
        CategoryName,
        ScheduleEnabled,
        NextRunDate,
        NextRunTime
    )
    SELECT GETDATE(),
           sj.name,
           sj.[description],
           SUSER_SNAME(sj.owner_sid),
           sj.date_created,
           sj.[enabled],
           sj.notify_email_operator_id,
           sj.notify_level_email,
           sc.name,
           s.[enabled],
           js.next_run_date,
           js.next_run_time
    FROM msdb.dbo.sysjobs AS sj WITH (NOLOCK)
        INNER JOIN msdb.dbo.syscategories AS sc WITH (NOLOCK)
            ON sj.category_id = sc.category_id
        LEFT OUTER JOIN msdb.dbo.sysjobschedules AS js WITH (NOLOCK)
            ON sj.job_id = js.job_id
        LEFT OUTER JOIN msdb.dbo.sysschedules AS s WITH (NOLOCK)
            ON js.schedule_id = s.schedule_id
    ORDER BY sj.name
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Get SQL Server Agent Alert Information (Query 10) (SQL Server Agent Alerts)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.SQLServerAgentAlerts') IS NULL
    BEGIN
        CREATE TABLE dbo.SQLServerAgentAlerts
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [Name] sysname NOT NULL,
            [EventSource] NVARCHAR(100) NOT NULL,
            [MesssageID] INT NOT NULL,
            [Severity] INT NOT NULL,
            [Enabled] TINYINT NOT NULL,
            HasNotification INT NOT NULL,
            DelayBetweenResponses INT NOT NULL,
            OccurrenceCount INT NOT NULL,
            LastOccurrenceDate INT NOT NULL,
            LastOccurrenceTime INT NOT NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.SQLServerAgentAlerts
    (
        CollectionDate,
        Name,
        EventSource,
        MesssageID,
        Severity,
        Enabled,
        HasNotification,
        DelayBetweenResponses,
        OccurrenceCount,
        LastOccurrenceDate,
        LastOccurrenceTime
    )
    SELECT GETDATE(),
           name,
           event_source,
           message_id,
           severity,
           [enabled],
           has_notification,
           delay_between_responses,
           occurrence_count,
           last_occurrence_date,
           last_occurrence_time
    FROM msdb.dbo.sysalerts WITH (NOLOCK)
    ORDER BY name
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- SQL Server NUMA Node information  (Query 12) (SQL Server NUMA Info)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.SQLServerNUMAInfo') IS NULL
    BEGIN
        CREATE TABLE dbo.SQLServerNUMAInfo
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [NodeID] SMALLINT NOT NULL,
            [NodeStateDescription] NVARCHAR(256) NOT NULL,
            [MemoryNodeID] SMALLINT NOT NULL,
            [ProcessorGroup] SMALLINT NOT NULL,
            [CPUCount] INT NOT NULL,
            OnlineSchedulerCount SMALLINT NOT NULL,
            IdleSchedulerCount SMALLINT NOT NULL,
            ActiveWorkerCount INT NOT NULL,
            AverageLoadBalance INT NOT NULL,
            ResourceMonitorState BIT NOT NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.SQLServerNUMAInfo
    (
        CollectionDate,
        NodeID,
        NodeStateDescription,
        MemoryNodeID,
        ProcessorGroup,
        CPUCount,
        OnlineSchedulerCount,
        IdleSchedulerCount,
        ActiveWorkerCount,
        AverageLoadBalance,
        ResourceMonitorState
    )
    SELECT GETDATE(),
           node_id,
           node_state_desc,
           memory_node_id,
           processor_group,
           cpu_count,
           online_scheduler_count,
           idle_scheduler_count,
           active_worker_count,
           avg_load_balance,
           resource_monitor_state
    FROM sys.dm_os_nodes WITH (NOLOCK)
    WHERE node_state_desc <> N'ONLINE DAC'
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Good basic information about OS memory amounts and state  (Query 13) (System Memory)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.SystemMemory') IS NULL
    BEGIN
        CREATE TABLE dbo.SystemMemory
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [Physical Memory (MB)] BIGINT NOT NULL,
            [Available Memory (MB)] BIGINT NOT NULL,
            [Page File Commit Limit (MB)] BIGINT NOT NULL,
            [Physical Page File Size (MB)] BIGINT NOT NULL,
            [Available Page File (MB)] BIGINT NOT NULL,
            [System Cache (MB)] BIGINT NOT NULL,
            [System Memory State] NVARCHAR(256) NOT NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.SystemMemory
    (
        CollectionDate,
        [Physical Memory (MB)],
        [Available Memory (MB)],
        [Page File Commit Limit (MB)],
        [Physical Page File Size (MB)],
        [Available Page File (MB)],
        [System Cache (MB)],
        [System Memory State]
    )
    SELECT GETDATE(),
           total_physical_memory_kb / 1024,
           available_physical_memory_kb / 1024,
           total_page_file_kb / 1024,
           total_page_file_kb / 1024 - total_physical_memory_kb / 1024,
           available_page_file_kb / 1024,
           system_cache_kb / 1024,
           system_memory_state_desc
    FROM sys.dm_os_sys_memory WITH (NOLOCK)
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Hardware information from SQL Server 2019  (Query 17) (Hardware Info)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.HardwareInfo') IS NULL
    BEGIN
        CREATE TABLE dbo.HardwareInfo
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [Logical CPU Count] INT NOT NULL,
            SchedulerCount INT NOT NULL,
            [Physical Core Count] INT NOT NULL,
            [Socket Count] INT NOT NULL,
            CoresPerSocket INT NOT NULL,
            NumaNodeCount INT NOT NULL,
            [Physical Memory (MB)] BIGINT NOT NULL,
            [Max Workers Count] INT NOT NULL,
            [Affinity Type] NVARCHAR(60) NOT NULL,
            [SQL Server Start Time] DATETIME NOT NULL,
            [SQL Server Up Time (hrs)] INT NOT NULL,
            [Virtual Machine Type] NVARCHAR(60) NOT NULL,
            [Soft NUMA Configuration] NVARCHAR(60) NOT NULL,
            [SQL Memory Model] NVARCHAR(60) NOT NULL,
            [Container Type] NVARCHAR(60) NOT NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.HardwareInfo
    (
        CollectionDate,
        [Logical CPU Count],
        SchedulerCount,
        [Physical Core Count],
        [Socket Count],
        CoresPerSocket,
        NumaNodeCount,
        [Physical Memory (MB)],
        [Max Workers Count],
        [Affinity Type],
        [SQL Server Start Time],
        [SQL Server Up Time (hrs)],
        [Virtual Machine Type],
        [Soft NUMA Configuration],
        [SQL Memory Model],
        [Container Type]
    )
    SELECT GETDATE(),
           cpu_count,
           scheduler_count,
           (socket_count * cores_per_socket),
           socket_count,
           cores_per_socket,
           numa_node_count,
           physical_memory_kb / 1024,
           max_workers_count,
           affinity_type_desc,
           sqlserver_start_time,
           DATEDIFF(HOUR, sqlserver_start_time, GETDATE()),
           virtual_machine_type_desc,
           softnuma_configuration_desc,
           sql_memory_model_desc,
           CASE
               WHEN (SELECT CONVERT(VARCHAR(128), SERVERPROPERTY('ProductVersion'))) LIKE '15%' THEN
                   container_type_desc
               ELSE
                   'N/A'
           END
    FROM sys.dm_os_sys_info WITH (NOLOCK)
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Get information on location, time and size of any memory dumps from SQL Server  (Query 21) (Memory Dump Info)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.MemoryDumpInfo') IS NULL
    BEGIN
        CREATE TABLE dbo.MemoryDumpInfo
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [Filename] NVARCHAR(256) NOT NULL,
            [CreationTime] DATETIMEOFFSET(7) NOT NULL,
            [Size (MB)] BIGINT NOT NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.MemoryDumpInfo
    (
        CollectionDate,
        Filename,
        CreationTime,
        [Size (MB)]
    )
    SELECT GETDATE(),
           [filename],
           creation_time,
           size_in_bytes / 1048576.0
    FROM sys.dm_server_memory_dumps WITH (NOLOCK)
    ORDER BY creation_time DESC
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Look at Suspect Pages table (Query 22) (Suspect Pages)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.SuspectPages') IS NULL
    BEGIN
        CREATE TABLE dbo.SuspectPages
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [DatabaseName] NVARCHAR(128) NOT NULL,
            [FileID] INT NOT NULL,
            [PageID] BIGINT NOT NULL,
            [EventType] INT NOT NULL,
            [ErrorCount] INT NOT NULL,
            [LastUpdatePage] DATETIME NOT NULL,
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.SuspectPages
    (
        CollectionDate,
        DatabaseName,
        FileID,
        PageID,
        EventType,
        ErrorCount,
        LastUpdatePage
    )
    SELECT GETDATE(),
           DB_NAME(database_id),
           [file_id],
           page_id,
           event_type,
           error_count,
           last_update_date
    FROM msdb.dbo.suspect_pages WITH (NOLOCK)
    ORDER BY database_id
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- File names and paths for all user and system databases on instance  (Query 24) (Database Filenames and Paths)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.DatabaseFilenamesAndPaths') IS NULL
    BEGIN
        CREATE TABLE dbo.DatabaseFilenamesAndPaths
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [DatabaseName] NVARCHAR(128) NOT NULL,
            [FileID] INT NOT NULL,
            [Name] sysname NOT NULL,
            [PhysicalName] NVARCHAR(260) NOT NULL,
            [Type] NVARCHAR(60) NOT NULL,
            [State] NVARCHAR(60) NOT NULL,
            [IsPercentGrowth] BIT NOT NULL,
            [Growth] INT NOT NULL,
            [Growth (MB)] BIGINT NOT NULL,
            [Total Size (MB)] BIGINT NOT NULL,
            [MaxSize] INT NOT NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.DatabaseFilenamesAndPaths
    (
        CollectionDate,
        DatabaseName,
        FileID,
        Name,
        PhysicalName,
        Type,
        State,
        IsPercentGrowth,
        Growth,
        [Growth (MB)],
        [Total Size (MB)],
        MaxSize
    )
    SELECT GETDATE(),
           DB_NAME([database_id]),
           [file_id],
           [name],
           physical_name,
           [type_desc],
           state_desc,
           is_percent_growth,
           growth,
           CONVERT(BIGINT, growth / 128.0),
           CONVERT(BIGINT, size / 128.0),
           max_size
    FROM sys.master_files WITH (NOLOCK)
    ORDER BY DB_NAME([database_id]),
             [file_id]
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Drive information for all fixed drives visible to the operating system (Query 25) (Fixed Drives)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.FixedDrives') IS NULL
    BEGIN
        CREATE TABLE dbo.FixedDrives
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [FixedDrivePath] NVARCHAR(256) NULL,
            [DriveType] NVARCHAR(256) NULL,
            [Available Space (GB)] DECIMAL(18, 2) NOT NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.FixedDrives
    (
        CollectionDate,
        FixedDrivePath,
        DriveType,
        [Available Space (GB)]
    )
    SELECT GETDATE(),
           fixed_drive_path,
           drive_type_desc,
           CONVERT(DECIMAL(18, 2), free_space_in_bytes / 1073741824.0)
    FROM sys.dm_os_enumerate_fixed_drives WITH (NOLOCK)
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Volume info for all LUNS that have database files on the current instance (Query 26) (Volume Info)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.VolumeInfo') IS NULL
    BEGIN
        CREATE TABLE dbo.VolumeInfo
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [VolumeMountPoint] NVARCHAR(256) NULL,
            [FileSystemType] NVARCHAR(256) NULL,
            [LogicalVolumeName] NVARCHAR(256) NULL,
            [Total Size (GB)] NVARCHAR(256) NULL,
            [Available Size (GB)] DECIMAL(18, 2) NOT NULL,
            [Space Free %] DECIMAL(18, 2) NOT NULL,
            [SupportsCompression] TINYINT NULL,
            [IsCompressed] TINYINT NULL,
            [SupportsSparseFiles] TINYINT NULL,
            [SupportsAlternateStreams] TINYINT NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.VolumeInfo
    (
        CollectionDate,
        VolumeMountPoint,
        FileSystemType,
        LogicalVolumeName,
        [Total Size (GB)],
        [Available Size (GB)],
        [Space Free %],
        SupportsCompression,
        IsCompressed,
        SupportsSparseFiles,
        SupportsAlternateStreams
    )
    SELECT DISTINCT
           GETDATE(),
           vs.volume_mount_point,
           vs.file_system_type,
           vs.logical_volume_name,
           CONVERT(DECIMAL(18, 2), vs.total_bytes / 1073741824.0),
           CONVERT(DECIMAL(18, 2), vs.available_bytes / 1073741824.0),
           CONVERT(DECIMAL(18, 2), vs.available_bytes * 1. / vs.total_bytes * 100.),
           vs.supports_compression,
           vs.is_compressed,
           vs.supports_sparse_files,
           vs.supports_alternate_streams
    FROM sys.master_files AS f WITH (NOLOCK)
        CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.[file_id]) AS vs
    ORDER BY vs.volume_mount_point
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Drive level latency information (Query 27) (Drive Level Latency)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.DriveLevelLatency') IS NULL
    BEGIN
        CREATE TABLE dbo.DriveLevelLatency
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [Drive] NVARCHAR(260) NULL,
            [VolumeMountPoint] NVARCHAR(260) NULL,
            [Read Latency] BIGINT NOT NULL,
            [Write Latency] BIGINT NOT NULL,
            [Overall Latency] BIGINT NOT NULL,
            [Avg Bytes/Read] BIGINT NOT NULL,
            [Avg Bytes/Write] BIGINT NOT NULL,
            [Avg Bytes/Transfer] BIGINT NOT NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.DriveLevelLatency
    (
        CollectionDate,
        Drive,
        VolumeMountPoint,
        [Read Latency],
        [Write Latency],
        [Overall Latency],
        [Avg Bytes/Read],
        [Avg Bytes/Write],
        [Avg Bytes/Transfer]
    )
    SELECT GETDATE() AS CollectionDate,
           tab.[Drive],
           tab.volume_mount_point AS [Volume Mount Point],
           CASE
               WHEN num_of_reads = 0 THEN
                   0
               ELSE
           (io_stall_read_ms / num_of_reads)
           END AS [Read Latency],
           CASE
               WHEN num_of_writes = 0 THEN
                   0
               ELSE
           (io_stall_write_ms / num_of_writes)
           END AS [Write Latency],
           CASE
               WHEN
               (
                   num_of_reads = 0
                   AND num_of_writes = 0
               ) THEN
                   0
               ELSE
           (io_stall / (num_of_reads + num_of_writes))
           END AS [Overall Latency],
           CASE
               WHEN num_of_reads = 0 THEN
                   0
               ELSE
           (num_of_bytes_read / num_of_reads)
           END AS [Avg Bytes/Read],
           CASE
               WHEN num_of_writes = 0 THEN
                   0
               ELSE
           (num_of_bytes_written / num_of_writes)
           END AS [Avg Bytes/Write],
           CASE
               WHEN
               (
                   num_of_reads = 0
                   AND num_of_writes = 0
               ) THEN
                   0
               ELSE
           ((num_of_bytes_read + num_of_bytes_written) / (num_of_reads + num_of_writes))
           END AS [Avg Bytes/Transfer]
    FROM
    (
        SELECT LEFT(UPPER(mf.physical_name), 2) AS Drive,
               SUM(num_of_reads) AS num_of_reads,
               SUM(io_stall_read_ms) AS io_stall_read_ms,
               SUM(num_of_writes) AS num_of_writes,
               SUM(io_stall_write_ms) AS io_stall_write_ms,
               SUM(num_of_bytes_read) AS num_of_bytes_read,
               SUM(num_of_bytes_written) AS num_of_bytes_written,
               SUM(io_stall) AS io_stall,
               vs.volume_mount_point
        FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS vfs
            INNER JOIN sys.master_files AS mf WITH (NOLOCK)
                ON vfs.database_id = mf.database_id
                   AND vfs.file_id = mf.file_id
            CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.[file_id]) AS vs
        GROUP BY LEFT(UPPER(mf.physical_name), 2),
                 vs.volume_mount_point
    ) AS tab
    ORDER BY [Overall Latency]
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Calculates average latency per read, per write, and per total input/output for each database file  (Query 28) (IO Latency by File)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.IOLatencyByFile') IS NULL
    BEGIN
        CREATE TABLE dbo.IOLatencyByFile
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [DatabaseName] NVARCHAR(260) NULL,
            [Average Read Latency (ms)] NUMERIC(10, 1) NULL,
            [Average Write Latency (ms)] NUMERIC(10, 1) NOT NULL,
            [Average IO Latency (ms)] NUMERIC(10, 1) NOT NULL,
            [File Size (MB)] DECIMAL(18, 2) NOT NULL,
            [PhysicalName] NVARCHAR(260) NOT NULL,
            [Type] NVARCHAR(60) NULL,
            [IO Stall Read (ms)] BIGINT NOT NULL,
            [Number of Reads] BIGINT NOT NULL,
            [IO Stall Write (ms)] BIGINT NOT NULL,
            [Number of Writes] BIGINT NOT NULL,
            [IO Stalls] BIGINT NOT NULL,
            [Total IO] BIGINT NOT NULL,
            [Resource Governor Total Read IO Latency (ms)] BIGINT NOT NULL,
            [Resource Governor Total Write IO Latency (ms)] BIGINT NOT NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.IOLatencyByFile
    (
        [CollectionDate],
        [DatabaseName],
        [Average Read Latency (ms)],
        [Average Write Latency (ms)],
        [Average IO Latency (ms)],
        [File Size (MB)],
        [PhysicalName],
        [Type],
        [IO Stall Read (ms)],
        [Number of Reads],
        [IO Stall Write (ms)],
        [Number of Writes],
        [IO Stalls],
        [Total IO],
        [Resource Governor Total Read IO Latency (ms)],
        [Resource Governor Total Write IO Latency (ms)]
    )
    SELECT GETDATE(),
           DB_NAME(fs.database_id),
           CAST(fs.io_stall_read_ms / (1.0 + fs.num_of_reads) AS NUMERIC(10, 1)),
           CAST(fs.io_stall_write_ms / (1.0 + fs.num_of_writes) AS NUMERIC(10, 1)),
           CAST((fs.io_stall_read_ms + fs.io_stall_write_ms) / (1.0 + fs.num_of_reads + fs.num_of_writes) AS NUMERIC(10, 1)) AS [avg_io_latency_ms],
           CONVERT(DECIMAL(18, 2), mf.size / 128.0),
           mf.physical_name,
           mf.type_desc,
           fs.io_stall_read_ms,
           fs.num_of_reads,
           fs.io_stall_write_ms,
           fs.num_of_writes,
           fs.io_stall_read_ms + fs.io_stall_write_ms,
           fs.num_of_reads + fs.num_of_writes,
           io_stall_queued_read_ms,
           io_stall_queued_write_ms
    FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS fs
        INNER JOIN sys.master_files AS mf WITH (NOLOCK)
            ON fs.database_id = mf.database_id
               AND fs.[file_id] = mf.[file_id]
    ORDER BY avg_io_latency_ms DESC
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Look for I/O requests taking longer than 15 seconds in the six most recent SQL Server Error Logs (Query 29) (IO Warnings)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.IOWarnings') IS NULL
    BEGIN
        CREATE TABLE dbo.IOWarnings
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            LogDate DATETIME,
            ProcessInfo sysname,
            LogText NVARCHAR(1000)
        ) ON [PRIMARY];
    END;

    CREATE TABLE #IOWarningResults
    (
        LogDate DATETIME,
        ProcessInfo sysname,
        LogText NVARCHAR(1000)
    );

    INSERT INTO #IOWarningResults
    EXEC xp_readerrorlog 0, 1, N'taking longer than 15 seconds';

    INSERT INTO #IOWarningResults
    EXEC xp_readerrorlog 1, 1, N'taking longer than 15 seconds';

    INSERT INTO #IOWarningResults
    EXEC xp_readerrorlog 2, 1, N'taking longer than 15 seconds';

    INSERT INTO #IOWarningResults
    EXEC xp_readerrorlog 3, 1, N'taking longer than 15 seconds';

    INSERT INTO #IOWarningResults
    EXEC xp_readerrorlog 4, 1, N'taking longer than 15 seconds';

    INSERT INTO #IOWarningResults
    EXEC xp_readerrorlog 5, 1, N'taking longer than 15 seconds';

    INSERT INTO dbo.IOWarnings
    (
        CollectionDate,
        LogDate,
        ProcessInfo,
        LogText
    )
    SELECT GETDATE(),
           LogDate,
           ProcessInfo,
           LogText
    FROM #IOWarningResults
    ORDER BY LogDate DESC;

    DROP TABLE #IOWarningResults;

    -------------------------------------------------------------------------------
    -- Recovery model, log reuse wait description, log file size, log usage size  (Query 31) (Database Properties)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.DatabaseProperties') IS NULL
    BEGIN
        CREATE TABLE dbo.DatabaseProperties
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [Database Name] sysname NOT NULL,
            [Database Owner] NVARCHAR(128) NULL,
            [Recovery Model] NVARCHAR(60) NULL,
            [State] NVARCHAR(60) NULL,
            [Containment] NVARCHAR(60) NULL,
            [Log Reuse Wait Description] NVARCHAR(60) NULL,
            [Log Size (MB)] DECIMAL(18, 2) NOT NULL,
            [Log Used (MB)] DECIMAL(18, 2) NOT NULL,
            [Log Used %] DECIMAL(18, 2) NOT NULL,
            [DB Compatibility Level] TINYINT NOT NULL,
            [Is Mixed Page Allocation On] BIT NULL,
            [Page Verify Option] NVARCHAR(60) NULL,
            is_auto_create_stats_on BIT NULL,
            is_auto_update_stats_on BIT NULL,
            is_auto_update_stats_async_on BIT NULL,
            is_parameterization_forced BIT NULL,
            snapshot_isolation_state_desc NVARCHAR(60) NULL,
            is_read_committed_snapshot_on BIT NULL,
            is_auto_close_on BIT NULL,
            is_auto_shrink_on BIT NULL,
            target_recovery_time_in_seconds INT NULL,
            is_cdc_enabled BIT NULL,
            is_published BIT NULL,
            is_distributor BIT NULL,
            group_database_id UNIQUEIDENTIFIER NULL,
            replica_id UNIQUEIDENTIFIER NULL,
            is_memory_optimized_elevate_to_snapshot_on BIT NULL,
            delayed_durability_desc NVARCHAR(60) NULL,
            is_auto_create_stats_incremental_on BIT NULL,
            is_query_store_on BIT NULL,
            is_sync_with_backup BIT NULL,
            is_temporal_history_retention_enabled BIT NULL,
            is_supplemental_logging_enabled BIT NULL,
            is_remote_data_archive_enabled BIT NULL,
            is_encrypted BIT NULL,
            encryption_state INT NULL,
            percent_complete REAL NULL,
            key_algorithm NVARCHAR(128) NULL,
            key_length INT NULL,
            resource_pool_id INT NULL,
            is_tempdb_spill_to_remote_store BIT NULL,
            is_result_set_caching_on BIT NULL,
            is_accelerated_database_recovery_on BIT NULL,
            is_stale_page_detection_on BIT NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.DatabaseProperties
    (
        CollectionDate,
        [Database Name],
        [Database Owner],
        [Recovery Model],
        State,
        Containment,
        [Log Reuse Wait Description],
        [Log Size (MB)],
        [Log Used (MB)],
        [Log Used %],
        [DB Compatibility Level],
        [Is Mixed Page Allocation On],
        [Page Verify Option],
        is_auto_create_stats_on,
        is_auto_update_stats_on,
        is_auto_update_stats_async_on,
        is_parameterization_forced,
        snapshot_isolation_state_desc,
        is_read_committed_snapshot_on,
        is_auto_close_on,
        is_auto_shrink_on,
        target_recovery_time_in_seconds,
        is_cdc_enabled,
        is_published,
        is_distributor,
        group_database_id,
        replica_id,
        is_memory_optimized_elevate_to_snapshot_on,
        delayed_durability_desc,
        is_auto_create_stats_incremental_on,
        is_query_store_on,
        is_sync_with_backup,
        is_temporal_history_retention_enabled,
        is_supplemental_logging_enabled,
        is_remote_data_archive_enabled,
        is_encrypted,
        encryption_state,
        percent_complete,
        key_algorithm,
        key_length,
        resource_pool_id,
        is_tempdb_spill_to_remote_store,
        is_result_set_caching_on,
        is_accelerated_database_recovery_on,
        is_stale_page_detection_on
    )
    SELECT GETDATE(),
           db.[name],
           SUSER_SNAME(db.owner_sid),
           db.recovery_model_desc,
           db.state_desc,
           db.containment_desc,
           db.log_reuse_wait_desc,
           CONVERT(DECIMAL(18, 2), ls.cntr_value / 1024.0),
           CONVERT(DECIMAL(18, 2), lu.cntr_value / 1024.0),
           CAST(CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT) AS DECIMAL(18, 2)) * 100,
           db.[compatibility_level],
           db.is_mixed_page_allocation_on,
           db.page_verify_option_desc,
           db.is_auto_create_stats_on,
           db.is_auto_update_stats_on,
           db.is_auto_update_stats_async_on,
           db.is_parameterization_forced,
           db.snapshot_isolation_state_desc,
           db.is_read_committed_snapshot_on,
           db.is_auto_close_on,
           db.is_auto_shrink_on,
           db.target_recovery_time_in_seconds,
           db.is_cdc_enabled,
           db.is_published,
           db.is_distributor,
           db.group_database_id,
           db.replica_id,
           db.is_memory_optimized_elevate_to_snapshot_on,
           db.delayed_durability_desc,
           db.is_auto_create_stats_incremental_on,
           db.is_query_store_on,
           db.is_sync_with_backup,
           db.is_temporal_history_retention_enabled,
           db.is_supplemental_logging_enabled,
           db.is_remote_data_archive_enabled,
           db.is_encrypted,
           de.encryption_state,
           de.percent_complete,
           de.key_algorithm,
           de.key_length,
           db.resource_pool_id,
           db.is_tempdb_spill_to_remote_store,
           db.is_result_set_caching_on,
           db.is_accelerated_database_recovery_on,
           is_stale_page_detection_on
    FROM sys.databases AS db WITH (NOLOCK)
        INNER JOIN sys.dm_os_performance_counters AS lu WITH (NOLOCK)
            ON db.name = lu.instance_name
        INNER JOIN sys.dm_os_performance_counters AS ls WITH (NOLOCK)
            ON db.name = ls.instance_name
        LEFT OUTER JOIN sys.dm_database_encryption_keys AS de WITH (NOLOCK)
            ON db.database_id = de.database_id
    WHERE lu.counter_name LIKE N'Log File(s) Used Size (KB)%'
          AND ls.counter_name LIKE N'Log File(s) Size (KB)%'
          AND ls.cntr_value > 0
    ORDER BY db.[name]
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Missing Indexes for all databases by Index Advantage  (Query 32) (Missing Indexes All Databases)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.MissingIndexes') IS NULL
    BEGIN
        CREATE TABLE dbo.MissingIndexes
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [Database] NVARCHAR(128) NOT NULL,
            [Index Advantage] DECIMAL(18, 2) NULL,
            [Last User Seek] DATETIME NULL,
            [Database.Schema.Table] NVARCHAR(4000) NULL,
            [Missing Indexes] NVARCHAR(4000) NULL,
            [Similar Missing Indexes] NVARCHAR(4000) NULL,
            [Equality Columns] NVARCHAR(4000) NULL,
            [Inequality Columns] NVARCHAR(4000) NULL,
            [Included Columns] NVARCHAR(4000) NULL,
            [User Seeks] BIGINT NOT NULL,
            [Average Total User Cost] DECIMAL(18, 2) NOT NULL,
            [Average User Impact] FLOAT NOT NULL,
            [Short Query Text] NVARCHAR(255) NULL
        ) ON [PRIMARY];
    END;

    EXEC sp_MSforeachdb @command1 = 'USE ?;
		INSERT INTO DBA.dbo.MissingIndexes
		(
			[CollectionDate],
			[Database],
			[Index Advantage],
			[Last User Seek],
			[Database.Schema.Table],
			[Missing Indexes],
			[Similar Missing Indexes],
			[Equality Columns],
			[Inequality Columns],
			[Included Columns],
			[User Seeks],
			[Average Total User Cost],
			[Average User Impact],
			[Short Query Text]
		)
		SELECT GETDATE() AS CollectionDate,
		       DB_NAME() AS [Database],
			   CONVERT(DECIMAL(18, 2), migs.user_seeks * migs.avg_total_user_cost * (migs.avg_user_impact * 0.01)) AS [Index Advantage],
			   FORMAT(migs.last_user_seek, ''yyyy-MM-dd HH:mm:ss'') AS [Last User Seek],
			   mid.[statement] AS [Database.Schema.Table],
			   COUNT(1) OVER (PARTITION BY mid.[statement]) AS [Missing Indexes],
			   COUNT(1) OVER (PARTITION BY mid.[statement], mid.equality_columns) AS [Similar Missing Indexes],
			   mid.equality_columns AS [Equality Columns],
		       mid.inequality_columns AS [Inequality Columns],
			   mid.included_columns AS [Included Columns],
			   migs.user_seeks AS [User Seeks],
			   CONVERT(DECIMAL(18, 2), migs.avg_total_user_cost) AS [Average Total User Cost],
		       migs.avg_user_impact AS [Average User Impact],
			   REPLACE(REPLACE(LEFT(st.[text], 255), CHAR(10), ''''), CHAR(13), '''') AS [Short Query Text]
		FROM [?].sys.dm_db_missing_index_groups AS mig WITH (NOLOCK)
		INNER JOIN [?].sys.dm_db_missing_index_group_stats_query AS migs WITH (NOLOCK) ON mig.index_group_handle = migs.group_handle
		CROSS APPLY [?].sys.dm_exec_sql_text(migs.last_sql_handle) AS st
		INNER JOIN [?].sys.dm_db_missing_index_details AS mid WITH (NOLOCK) ON mig.index_handle = mid.index_handle
		ORDER BY [Index Advantage] DESC
		OPTION (RECOMPILE);';

    -------------------------------------------------------------------------------
    -- Get VLF Counts for all databases on the instance (Query 33) (VLF Counts)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.VLFCounts') IS NULL
    BEGIN
        CREATE TABLE dbo.VLFCounts
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [DatabaseName] sysname NULL,
            [VLF Count] INT NOT NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.VLFCounts
    (
        CollectionDate,
        DatabaseName,
        [VLF Count]
    )
    SELECT GETDATE(),
           [name],
           [VLF Count]
    FROM sys.databases AS db WITH (NOLOCK)
        CROSS APPLY
    (
        SELECT file_id,
               COUNT(*) AS [VLF Count]
        FROM sys.dm_db_log_info(db.database_id)
        GROUP BY file_id
    ) AS li
    ORDER BY [VLF Count] DESC
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Get CPU utilization by database (Query 34) (CPU Usage by Database)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.CPUUsageByDatabase') IS NULL
    BEGIN
        CREATE TABLE dbo.CPUUsageByDatabase
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [CPU Rank] BIGINT NULL,
            [Database Name] sysname NOT NULL,
            [CPU Time (ms)] BIGINT NOT NULL,
            [CPU Percent] DECIMAL(5, 2) NOT NULL
        ) ON [PRIMARY];
    END;

    WITH DB_CPU_Stats
    AS (SELECT pa.DatabaseID,
               DB_NAME(pa.DatabaseID) AS [Database Name],
               SUM(qs.total_worker_time / 1000) AS [CPU_Time_Ms]
        FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
            CROSS APPLY
        (
            SELECT CONVERT(INT, value) AS [DatabaseID]
            FROM sys.dm_exec_plan_attributes(qs.plan_handle)
            WHERE attribute = N'dbid'
        ) AS pa
        GROUP BY DatabaseID)
    INSERT INTO dbo.CPUUsageByDatabase
    (
        CollectionDate,
        [CPU Rank],
        [Database Name],
        [CPU Time (ms)],
        [CPU Percent]
    )
    SELECT GETDATE(),
           ROW_NUMBER() OVER (ORDER BY [CPU_Time_Ms] DESC) AS [CPU Rank],
           [Database Name],
           [CPU_Time_Ms],
           CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER () * 100.0 AS DECIMAL(5, 2))
    FROM DB_CPU_Stats
    WHERE DatabaseID <> 32767 -- ResourceDB
    ORDER BY [CPU Rank]
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Get I/O utilization by database (Query 35) (IO Usage By Database)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.IOUsageByDatabase') IS NULL
    BEGIN
        CREATE TABLE dbo.IOUsageByDatabase
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [I/O Rank] BIGINT NULL,
            [Database Name] sysname NOT NULL,
            [Total I/O (MB)] BIGINT NOT NULL,
            [Total I/O %] DECIMAL(5, 2) NOT NULL,
            [Read I/O (MB)] DECIMAL(12, 2) NOT NULL,
            [Read I/O %] DECIMAL(5, 2) NOT NULL,
            [Write I/O (MB)] DECIMAL(12, 2) NOT NULL,
            [Write I/O %] DECIMAL(5, 2) NOT NULL
        ) ON [PRIMARY];
    END;

    WITH Aggregate_IO_Statistics
    AS (SELECT DB_NAME(database_id) AS [Database Name],
               CAST(SUM(num_of_bytes_read + num_of_bytes_written) / 1048576 AS DECIMAL(12, 2)) AS [ioTotalMB],
               CAST(SUM(num_of_bytes_read) / 1048576 AS DECIMAL(12, 2)) AS [ioReadMB],
               CAST(SUM(num_of_bytes_written) / 1048576 AS DECIMAL(12, 2)) AS [ioWriteMB]
        FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS [DM_IO_STATS]
        GROUP BY database_id)
    INSERT INTO dbo.IOUsageByDatabase
    (
        CollectionDate,
        [I/O Rank],
        [Database Name],
        [Total I/O (MB)],
        [Total I/O %],
        [Read I/O (MB)],
        [Read I/O %],
        [Write I/O (MB)],
        [Write I/O %]
    )
    SELECT GETDATE(),
           ROW_NUMBER() OVER (ORDER BY ioTotalMB DESC) AS [I/O Rank],
           [Database Name],
           ioTotalMB AS [Total I/O (MB)],
           CAST(ioTotalMB / SUM(ioTotalMB) OVER () * 100.0 AS DECIMAL(5, 2)),
           ioReadMB,
           CAST(ioReadMB / SUM(ioReadMB) OVER () * 100.0 AS DECIMAL(5, 2)),
           ioWriteMB,
           CAST(ioWriteMB / SUM(ioWriteMB) OVER () * 100.0 AS DECIMAL(5, 2))
    FROM Aggregate_IO_Statistics
    ORDER BY [I/O Rank]
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Get total buffer usage by database for current instance  (Query 36) (Total Buffer Usage by Database)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.TotalBufferUsageByDatabase') IS NULL
    BEGIN
        CREATE TABLE dbo.TotalBufferUsageByDatabase
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [Buffer Pool Rank] BIGINT NULL,
            [Database Name] sysname NOT NULL,
            [Cached Size (MB)] DECIMAL(10, 2) NOT NULL,
            [Buffer Pool Percent] DECIMAL(5, 2) NOT NULL
        ) ON [PRIMARY];
    END;

    WITH AggregateBufferPoolUsage
    AS (SELECT DB_NAME(database_id) AS [Database Name],
               CAST(COUNT(*) * 8 / 1024.0 AS DECIMAL(10, 2)) AS [CachedSize]
        FROM sys.dm_os_buffer_descriptors WITH (NOLOCK)
        WHERE database_id <> 32767 -- ResourceDB
        GROUP BY DB_NAME(database_id))
    INSERT INTO dbo.TotalBufferUsageByDatabase
    (
        CollectionDate,
        [Buffer Pool Rank],
        [Database Name],
        [Cached Size (MB)],
        [Buffer Pool Percent]
    )
    SELECT GETDATE(),
           ROW_NUMBER() OVER (ORDER BY CachedSize DESC) AS [Buffer Pool Rank],
           [Database Name],
           CachedSize,
           CAST(CachedSize / SUM(CachedSize) OVER () * 100.0 AS DECIMAL(5, 2))
    FROM AggregateBufferPoolUsage
    ORDER BY [Buffer Pool Rank]
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Isolate top waits for server instance since last restart or wait statistics clear  (Query 38) (Top Waits)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.TopWaits') IS NULL
    BEGIN
        CREATE TABLE dbo.TopWaits
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [WaitType] NVARCHAR(60) NOT NULL,
            [Wait Percentage] DECIMAL(5, 2) NOT NULL,
            [AvgWait_Sec] DECIMAL(16, 4) NOT NULL,
            [AvgRes_Sec] DECIMAL(5, 2) NULL,
            [AvgSig_Sec] DECIMAL(16, 4) NULL,
            [Wait_Sec] DECIMAL(16, 2) NULL,
            [Resource_Sec] DECIMAL(16, 2) NULL,
            [Signal_Sec] DECIMAL(16, 2) NULL,
            [Wait Count] BIGINT NOT NULL,
            [Help/Info URL] XML NULL
        ) ON [PRIMARY];
    END;

    WITH [Waits]
    AS (SELECT wait_type,
               wait_time_ms / 1000.0 AS [WaitS],
               (wait_time_ms - signal_wait_time_ms) / 1000.0 AS [ResourceS],
               signal_wait_time_ms / 1000.0 AS [SignalS],
               waiting_tasks_count AS [WaitCount],
               100.0 * wait_time_ms / SUM(wait_time_ms) OVER () AS [Percentage],
               ROW_NUMBER() OVER (ORDER BY wait_time_ms DESC) AS [RowNum]
        FROM sys.dm_os_wait_stats WITH (NOLOCK)
        WHERE [wait_type] NOT IN ( N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR', N'BROKER_TASK_STOP',
                                   N'BROKER_TO_FLUSH', N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE', N'CHKPT',
                                   N'CLR_AUTO_EVENT', N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE', N'CXCONSUMER',
                                   N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE', N'DBMIRROR_WORKER_QUEUE',
                                   N'DBMIRRORING_CMD', N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE', N'EXECSYNC',
                                   N'FSAGENT', N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
                                   N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
                                   N'HADR_LOGCAPTURE_WAIT', N'HADR_NOTIFICATION_DEQUEUE', N'HADR_TIMER_TASK',
                                   N'HADR_WORK_QUEUE', N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP', N'LOGMGR_QUEUE',
                                   N'MEMORY_ALLOCATION_EXT', N'ONDEMAND_TASK_QUEUE', N'PARALLEL_REDO_DRAIN_WORKER',
                                   N'PARALLEL_REDO_LOG_CACHE', N'PARALLEL_REDO_TRAN_LIST',
                                   N'PARALLEL_REDO_WORKER_SYNC', N'PARALLEL_REDO_WORKER_WAIT_WORK',
                                   N'PREEMPTIVE_HADR_LEASE_MECHANISM', N'PREEMPTIVE_SP_SERVER_DIAGNOSTICS',
                                   N'PREEMPTIVE_OS_LIBRARYOPS', N'PREEMPTIVE_OS_COMOPS', N'PREEMPTIVE_OS_CRYPTOPS',
                                   N'PREEMPTIVE_OS_PIPEOPS', N'PREEMPTIVE_OS_AUTHENTICATIONOPS',
                                   N'PREEMPTIVE_OS_GENERICOPS', N'PREEMPTIVE_OS_VERIFYTRUST', N'PREEMPTIVE_OS_FILEOPS',
                                   N'PREEMPTIVE_OS_DEVICEOPS', N'PREEMPTIVE_OS_QUERYREGISTRY',
                                   N'PREEMPTIVE_OS_WRITEFILE', N'PREEMPTIVE_OS_WRITEFILEGATHER',
                                   N'PREEMPTIVE_XE_CALLBACKEXECUTE', N'PREEMPTIVE_XE_DISPATCHER',
                                   N'PREEMPTIVE_XE_GETTARGETSTATE', N'PREEMPTIVE_XE_SESSIONCOMMIT',
                                   N'PREEMPTIVE_XE_TARGETINIT', N'PREEMPTIVE_XE_TARGETFINALIZE',
                                   N'PWAIT_ALL_COMPONENTS_INITIALIZED', N'PWAIT_DIRECTLOGCONSUMER_GETNEXT',
                                   N'PWAIT_EXTENSIBILITY_CLEANUP_TASK', N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
                                   N'QDS_ASYNC_QUEUE', N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
                                   N'REQUEST_FOR_DEADLOCK_SEARCH', N'RESOURCE_QUEUE', N'SERVER_IDLE_CHECK',
                                   N'SLEEP_BPOOL_FLUSH', N'SLEEP_DBSTARTUP', N'SLEEP_DCOMSTARTUP',
                                   N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY', N'SLEEP_MASTERUPGRADED',
                                   N'SLEEP_MSDBSTARTUP', N'SLEEP_SYSTEMTASK', N'SLEEP_TASK', N'SLEEP_TEMPDBSTARTUP',
                                   N'SNI_HTTP_ACCEPT', N'SOS_WORK_DISPATCHER', N'SP_SERVER_DIAGNOSTICS_SLEEP',
                                   N'SQLTRACE_BUFFER_FLUSH', N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
                                   N'SQLTRACE_WAIT_ENTRIES', N'STARTUP_DEPENDENCY_MANAGER', N'WAIT_FOR_RESULTS',
                                   N'WAITFOR', N'WAITFOR_TASKSHUTDOWN', N'WAIT_XTP_HOST_WAIT',
                                   N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', N'WAIT_XTP_CKPT_CLOSE', N'WAIT_XTP_RECOVERY',
                                   N'XE_BUFFERMGR_ALLPROCESSED_EVENT', N'XE_DISPATCHER_JOIN', N'XE_DISPATCHER_WAIT',
                                   N'XE_LIVE_TARGET_TVF', N'XE_TIMER_EVENT'
                                 )
              AND waiting_tasks_count > 0)
    INSERT INTO dbo.TopWaits
    (
        CollectionDate,
        WaitType,
        [Wait Percentage],
        AvgWait_Sec,
        AvgRes_Sec,
        AvgSig_Sec,
        Wait_Sec,
        Resource_Sec,
        Signal_Sec,
        [Wait Count],
        [Help/Info URL]
    )
    SELECT GETDATE(),
           MAX(W1.wait_type),
           CAST(MAX(W1.Percentage) AS DECIMAL(5, 2)),
           CAST((MAX(W1.WaitS) / MAX(W1.WaitCount)) AS DECIMAL(16, 4)),
           CAST((MAX(W1.ResourceS) / MAX(W1.WaitCount)) AS DECIMAL(16, 4)),
           CAST((MAX(W1.SignalS) / MAX(W1.WaitCount)) AS DECIMAL(16, 4)),
           CAST(MAX(W1.WaitS) AS DECIMAL(16, 2)),
           CAST(MAX(W1.ResourceS) AS DECIMAL(16, 2)),
           CAST(MAX(W1.SignalS) AS DECIMAL(16, 2)),
           MAX(W1.WaitCount),
           CAST(N'https://www.sqlskills.com/help/waits/' + W1.wait_type AS XML)
    FROM Waits AS W1
        INNER JOIN Waits AS W2
            ON W2.RowNum <= W1.RowNum
    GROUP BY W1.RowNum,
             W1.wait_type
    HAVING SUM(W2.Percentage) - MAX(W1.Percentage) < 99 -- percentage threshold
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Get a count of SQL connections by IP address (Query 39) (Connection Counts by IP Address)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.ConnectionCountsByIPAddress') IS NULL
    BEGIN
        CREATE TABLE dbo.ConnectionCountsByIPAddress
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            client_net_address NVARCHAR(48) NULL,
            [program_name] NVARCHAR(128) NULL,
            [host_name] NVARCHAR(128) NULL,
            login_name NVARCHAR(128) NOT NULL,
            [connection count] INT NOT NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.ConnectionCountsByIPAddress
    (
        CollectionDate,
        client_net_address,
        program_name,
        host_name,
        login_name,
        [connection count]
    )
    SELECT GETDATE(),
           ec.client_net_address,
           es.[program_name],
           es.[host_name],
           es.login_name,
           COUNT(ec.session_id)
    FROM sys.dm_exec_sessions AS es WITH (NOLOCK)
        INNER JOIN sys.dm_exec_connections AS ec WITH (NOLOCK)
            ON es.session_id = ec.session_id
    GROUP BY ec.client_net_address,
             es.[program_name],
             es.[host_name],
             es.login_name
    ORDER BY ec.client_net_address,
             es.[program_name]
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Get CPU Utilization History for last 256 minutes (in one minute intervals)  (Query 42) (CPU Utilization History)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.CPUUtilizationHistory') IS NULL
    BEGIN
        CREATE TABLE dbo.CPUUtilizationHistory
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [SQL Server Process CPU Utilization] INT NOT NULL,
            [System Idle Process] INT NOT NULL,
            [Other Process CPU Utilization] INT NOT NULL,
            [Event Time] DATETIME NOT NULL
        ) ON [PRIMARY];
    END;

    DECLARE @ts_now BIGINT =
            (
                SELECT ms_ticks FROM sys.dm_os_sys_info WITH (NOLOCK)
            );
    INSERT INTO dbo.CPUUtilizationHistory
    (
        CollectionDate,
        [SQL Server Process CPU Utilization],
        [System Idle Process],
        [Other Process CPU Utilization],
        [Event Time]
    )
    SELECT TOP (256)
           GETDATE() AS CollectionDate,
           SQLProcessUtilization AS [SQL Server Process CPU Utilization],
           SystemIdle AS [System Idle Process],
           100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization],
           DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time]
    FROM
    (
        SELECT record.value('(./Record/@id)[1]', 'int') AS record_id,
               record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS [SystemIdle],
               record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS [SQLProcessUtilization],
               [timestamp]
        FROM
        (
            SELECT [timestamp],
                   CONVERT(XML, record) AS [record]
            FROM sys.dm_os_ring_buffers WITH (NOLOCK)
            WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
                  AND record LIKE N'%<SystemHealth>%'
        ) AS x
    ) AS y
    ORDER BY record_id DESC
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Page Life Expectancy (PLE) value for each NUMA node in current instance  (Query 44) (PLE by NUMA Node)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.PLEByNUMANode') IS NULL
    BEGIN
        CREATE TABLE dbo.PLEByNUMANode
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [Server Name] NVARCHAR(128) NOT NULL,
            [Object Name] NCHAR(128) NULL,
            instance_name NCHAR(128) NULL,
            [Page Life Expectancy] BIGINT NOT NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.PLEByNUMANode
    (
        CollectionDate,
        [Server Name],
        [Object Name],
        instance_name,
        [Page Life Expectancy]
    )
    SELECT GETDATE(),
           @@SERVERNAME,
           RTRIM([object_name]),
           instance_name,
           cntr_value
    FROM sys.dm_os_performance_counters WITH (NOLOCK)
    WHERE [object_name] LIKE N'%Buffer Node%' -- Handles named instances
          AND counter_name = N'Page life expectancy'
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Memory Clerk Usage for instance  (Query 46) (Memory Clerk Usage)
    -- Look for high value for CACHESTORE_SQLCP (Ad-hoc query plans)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.MemoryClerkUsage') IS NULL
    BEGIN
        CREATE TABLE dbo.MemoryClerkUsage
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [Memory Clerk Type] NVARCHAR(60) NOT NULL,
            [Memory Usage (MB)] DECIMAL(15, 2) NOT NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.MemoryClerkUsage
    (
        CollectionDate,
        [Memory Clerk Type],
        [Memory Usage (MB)]
    )
    SELECT TOP (10)
           GETDATE(),
           mc.[type],
           CAST((SUM(mc.pages_kb) / 1024.0) AS DECIMAL(15, 2))
    FROM sys.dm_os_memory_clerks AS mc WITH (NOLOCK)
    GROUP BY mc.[type]
    ORDER BY SUM(mc.pages_kb) DESC
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Look at UDF execution statistics (Query 50) (UDF Stats by DB)
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.UDFStatsByDatabase') IS NULL
    BEGIN
        CREATE TABLE dbo.UDFStatsByDatabase
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [Database Name] NVARCHAR(128) NOT NULL,
            [Function Name] sysname NOT NULL,
            total_worker_time BIGINT NOT NULL,
            execution_count BIGINT NOT NULL,
            total_elapsed_time BIGINT NOT NULL,
            [avg_elapsed_time] BIGINT NOT NULL,
            last_elapsed_time BIGINT NOT NULL,
            last_execution_time DATETIME NULL,
            cached_time DATETIME NULL,
            [type_desc] NVARCHAR(60) NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.UDFStatsByDatabase
    (
        CollectionDate,
        [Database Name],
        [Function Name],
        total_worker_time,
        execution_count,
        total_elapsed_time,
        avg_elapsed_time,
        last_elapsed_time,
        last_execution_time,
        cached_time,
        type_desc
    )
    SELECT TOP (25)
           GETDATE(),
           DB_NAME(database_id),
           OBJECT_NAME(object_id, database_id),
           total_worker_time,
           execution_count,
           total_elapsed_time,
           total_elapsed_time / execution_count,
           last_elapsed_time,
           last_execution_time,
           cached_time,
           [type_desc]
    FROM sys.dm_exec_function_stats WITH (NOLOCK)
    ORDER BY total_worker_time DESC
    OPTION (RECOMPILE);

    -------------------------------------------------------------------------------
    -- Who is Active logging
    -------------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'WhoIsActive')
    BEGIN
        CREATE TABLE dbo.WhoIsActive
        (
            id INT IDENTITY(1, 1) PRIMARY KEY,
            [dd hh:mm:ss:mss] VARCHAR(20) NULL,
            session_id SMALLINT NOT NULL,
            sql_text XML NULL,
            login_name sysname NULL,
            wait_info NVARCHAR(4000) NULL,
            CPU VARCHAR(30) NULL,
            tempdb_allocations VARCHAR(30) NULL,
            tempdb_current VARCHAR(30) NULL,
            blocking_session_id SMALLINT NULL,
            blocked_session_count VARCHAR(30) NULL,
            reads VARCHAR(30) NULL,
            writes VARCHAR(30) NULL,
            physical_reads VARCHAR(30) NULL,
            query_plan XML NULL,
            locks XML NULL,
            used_memory VARCHAR(30) NULL,
            [status] VARCHAR(30) NULL,
            open_tran_count VARCHAR(30) NULL,
            percent_complete VARCHAR(30) NULL,
            [host_name] sysname NULL,
            [database_name] sysname NULL,
            [program_name] sysname NULL,
            start_time DATETIME NULL,
            login_time DATETIME NULL,
            request_id SMALLINT NULL,
            collection_time DATETIME NULL
        );

        CREATE INDEX idx_collection_time ON dbo.WhoIsActive (collection_time);
    END;

    /* Load data into table.
If you want to change parameters, you will likely need to add columns to table
*/
    EXEC dbo.sp_WhoIsActive @get_locks = 1,
                            @find_block_leaders = 1,
                            @get_plans = 1,
                            @destination_table = 'WhoIsActive';

    DELETE dbo.WhoIsActive
    WHERE collection_time < DATEADD(MONTH, -1, GETDATE());

    -------------------------------------------------------------------------------
    -- Monitoring identity columns for room to grow
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.IdentityColumns') IS NULL
    BEGIN
        CREATE TABLE dbo.IdentityColumns
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [Database] sysname NOT NULL,
            [Table] sysname NOT NULL,
            [Column] sysname NULL,
            [Type] sysname NOT NULL,
            [Identity] NUMERIC(18, 0) NULL,
            [Percent Full] NUMERIC(18, 2) NULL
        ) ON [PRIMARY];
    END;

    CREATE TABLE #t2
    (
        [CollectionDate] DATETIME NOT NULL,
        [Database] sysname NOT NULL,
        [Table] sysname NOT NULL,
        [Column] sysname NULL,
        [Type] sysname NOT NULL,
        [Identity] NUMERIC(18, 0) NULL,
        [Percent Full] NUMERIC(18, 2) NULL
    );

    EXEC sp_MSforeachdb @command1 = 'USE ?; 
		INSERT INTO #t2
		SELECT GETDATE() AS CollectionDate,
				DB_NAME() AS [Database],	
				t.name AS [Table],
				c.name AS [Column],
				ty.name AS [Type],
				IDENT_CURRENT(t.name) AS [Identity],
				100 * IDENT_CURRENT(t.name) / 2147483647 AS [Percent Full]
		FROM [?].sys.tables t
		JOIN [?].sys.columns c ON c.object_id = t.object_id
		JOIN [?].sys.types ty ON ty.system_type_id = c.system_type_id
		WHERE c.is_identity = 1
				AND ty.name = ''int''
				AND 100 * IDENT_CURRENT(t.name) / 2147483647 > 80 /* Change threshold here */
		ORDER BY t.name;';

    INSERT INTO dbo.IdentityColumns
    (
        [CollectionDate],
        [Database],
        [Table],
        [Column],
        [Type],
        [Identity],
        [Percent Full]
    )
    SELECT [CollectionDate],
           [Database],
           [Table],
           [Column],
           [Type],
           [Identity],
           [Percent Full]
    FROM #t2;

    DROP TABLE #t2;

    -------------------------------------------------------------------------------
    -- List all database triggers
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.DatabaseTriggers') IS NULL
    BEGIN
        CREATE TABLE dbo.DatabaseTriggers
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [TriggerName] sysname NOT NULL,
            [Database] sysname NULL,
            [Table] sysname NULL,
            [Activation] NVARCHAR(10) NOT NULL,
            [Event] NVARCHAR(30) NULL,
            [Class] NVARCHAR(30) NOT NULL,
            [Type] NVARCHAR(30) NOT NULL,
            [Status] NVARCHAR(10) NOT NULL,
            [Definition] NVARCHAR(MAX) NULL
        ) ON [PRIMARY];
    END;

    CREATE TABLE #t3
    (
        [CollectionDate] DATETIME2(0) NOT NULL,
        [TriggerName] sysname NOT NULL,
        [Database] sysname NULL,
        [Table] sysname NULL,
        [Activation] NVARCHAR(10) NOT NULL,
        [Event] NVARCHAR(30) NULL,
        [Class] NVARCHAR(30) NOT NULL,
        [Type] NVARCHAR(30) NOT NULL,
        [Status] NVARCHAR(10) NOT NULL,
        [Definition] NVARCHAR(MAX) NULL
    );

    EXEC sp_MSforeachdb @command1 = 'USE ?; 
								INSERT INTO #t3
								SELECT GETDATE() AS CollectionDate,
								trg.name AS trigger_name,
								DB_NAME() as [Database],
								SCHEMA_NAME(tab.schema_id) + ''.'' + tab.name AS [Table],
								CASE
								   WHEN is_instead_of_trigger = 1 THEN
									   ''Instead of''
								   ELSE
									   ''After''
								END AS [Activation],
								(CASE
									WHEN OBJECTPROPERTY(trg.object_id, ''ExecIsUpdateTrigger'') = 1 THEN
										''Update ''
									ELSE
										''''
								END + CASE
										  WHEN OBJECTPROPERTY(trg.object_id, ''ExecIsDeleteTrigger'') = 1 THEN
											  ''Delete ''
										  ELSE
											  ''''
									  END + CASE
												WHEN OBJECTPROPERTY(trg.object_id, ''ExecIsInsertTrigger'') = 1 THEN
													''Insert''
												ELSE
													''''
											END
								) AS [Event],
								CASE
								   WHEN trg.parent_class = 1 THEN
									   ''Table trigger''
								   WHEN trg.parent_class = 0 THEN
									   ''Database trigger''
								END [class],
								CASE
								   WHEN trg.[type] = ''TA'' THEN
									   ''Assembly (CLR) trigger''
								   WHEN trg.[type] = ''TR'' THEN
									   ''SQL trigger''
								   ELSE
									   ''''
								END AS [type],
								CASE
								   WHEN is_disabled = 1 THEN
									   ''[Disabled]''
								   ELSE
									   ''[Active]''
								END AS [Status],
								OBJECT_DEFINITION(trg.object_id) AS [Definition]
						FROM [?].sys.triggers trg
						LEFT JOIN [?].sys.objects tab ON trg.parent_id = tab.object_id
						ORDER BY trg.name;';

    INSERT INTO dbo.DatabaseTriggers
    (
        [CollectionDate],
        [TriggerName],
        [Database],
        [Table],
        [Activation],
        [Event],
        [Class],
        [Type],
        [Status],
        [Definition]
    )
    SELECT [CollectionDate],
           [TriggerName],
           [Database],
           [Table],
           [Activation],
           [Event],
           [Class],
           [Type],
           [Status],
           [Definition]
    FROM #t3;

    DROP TABLE #t3;

    -------------------------------------------------------------------------------
    -- Performance monitor counters
    -------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.PerformanceCounters') IS NULL
    BEGIN
        CREATE TABLE dbo.PerformanceCounters
        (
            [CollectionDate] DATETIME2(0) NOT NULL,
            [Counter] NVARCHAR(770) NOT NULL,
            [Type] INT NULL,
            [Value] DECIMAL(38, 2) NULL
        ) ON [PRIMARY];
    END;

    INSERT INTO dbo.PerformanceCounters
    (
        CollectionDate,
        Counter,
        Type,
        Value
    )
    SELECT GETDATE(),
           RTRIM(object_name) + N':' + RTRIM(counter_name) + N':' + RTRIM(instance_name),
           cntr_type,
           cntr_value
    FROM sys.dm_os_performance_counters
    WHERE counter_name IN ( 'Page life expectancy', 'Lazy writes/sec', 'Page reads/sec', 'Page writes/sec',
                            'Free Pages', 'Free list stalls/sec', 'User Connections', 'Lock Waits/sec',
                            'Number of Deadlocks/sec', 'Transactions/sec', 'Forwarded Records/sec',
                            'Index Searches/sec', 'Full Scans/sec', 'Batch Requests/sec', 'SQL Compilations/sec',
                            'SQL Re-Compilations/sec', 'Total Server Memory (KB)', 'Target Server Memory (KB)',
                            'Latch Waits/sec'
                          )
    ORDER BY object_name + N':' + counter_name + N':' + instance_name;

END;