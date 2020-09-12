/******************************************************************************

 Helpful System Stored Procedures divided by category.

 * Database Engine Stored Procedures
 * Catalog Stored Procedures
 * Security Stored Procedures
 * General Extended Stored Procedures
 * SQL Server Agent Stored Procedures

******************************************************************************/

RAISERROR(N'No, don''t just hit F5. Run these demos one at a time.', 20, 1) WITH LOG;
GO

USE StackOverflow2013;
GO

-------------------------------------------------------------------------------
-- Database Engine Stored Procedures
-------------------------------------------------------------------------------

-- Reports information about a database object (any object listed in the 
-- sys.sysobjects compatibility view), a user-defined data type, or a data type
EXEC sys.sp_help;

EXEC sp_help @objname = 'dbo.Posts';

-- Returns a list of all constraint types, their user-defined or system-supplied 
-- name, the columns on which they have been defined, and the expression that 
-- defines the constraint (for DEFAULT and CHECK constraints only).
EXEC sys.sp_helpconstraint @objname = 'dbo.Posts';

-- Reports information about a specified database or all databases
EXEC sys.sp_helpdb;

EXEC sys.sp_helpdb @dbname = 'StackOverflow2013';

-- Stores a new user-defined error message in an instance of the SQL Server 
-- Database Engine. Messages stored by using sp_addmessage can be viewed by 
-- using the sys.messages catalog view.
EXEC sys.sp_addmessage @msgnum = 50001,
                       @severity = 16,
                       @msgtext = N'Percentage expects a value between 20 and 
					   100. Please reexecute with a more appropriate value.';

-- Reports the currently defined extended stored procedures and the name of the 
-- dynamic-link library (DLL) to which the procedure (function) belongs.
EXEC sys.sp_helpextendedproc;

-- Returns the physical names and attributes of files associated with the 
-- current database. Use this stored procedure to determine the names of files 
-- to attach to or detach from the server.
EXEC sys.sp_helpfile;

EXEC sys.sp_helpfile @filename = 'StackOverflow2013_log';

-- Returns the names and attributes of filegroups associated with the current 
-- database.
EXEC sys.sp_helpfilegroup;
EXEC sys.sp_helpfilegroup @filegroupname = 'PRIMARY';

-- Reports information about the indexes on a table or view.
EXEC sys.sp_helpindex @objname = 'dbo.Posts';

-- Reports information about a particular remote or replication server, 
-- or about all servers of both types.
EXEC sys.sp_helpserver;

-- Displays or changes the automatic statistics update option, 
-- AUTO_UPDATE_STATISTICS, for an index, a statistics object, a table, 
-- or an indexed view.
EXEC sys.sp_autostats @tblname = 'dbo.Posts';

EXEC sys.sp_autostats @tblname = 'dbo.Posts', @flagc = 'ON';

EXEC sys.sp_autostats @tblname = 'Production.Product',
                      @flagc = 'OFF',
                      @indname = AK_Product_Name;

-- Displays the sort order and character set for the instance of SQL Server.
EXEC sys.sp_helpsort;

-- Displays the definition of a user-defined rule, default, unencrypted 
-- Transact-SQL stored procedure, user-defined Transact-SQL function, trigger, 
-- computed column, CHECK constraint, view, or system object such as a system 
-- stored procedure.
EXEC sp_helptext @objname = 'AdventureWorks.HumanResources.dEmployee';

EXEC sp_helptext @objname = N'AdventureWorks.Sales.SalesOrderHeader',
                 @columnname = TotalDue;

-- Returns the type or types of DML triggers defined on the specified table for 
-- the current database. sp_helptrigger cannot be used with DDL triggers. 
EXEC sys.sp_helptrigger @tabname = 'AdventureWorks.HumanResources.Employee';

-- Removes residual information left on database pages because of data 
-- modification routines in SQL Server. sp_clean_db_free_space cleans all 
-- pages in all files of the database.
EXEC sp_clean_db_free_space @dbname = N'AdventureWorks';

-- Displays or changes global configuration settings for the current server.
EXEC sys.sp_configure;

EXEC sys.sp_configure @configname = 'show advanced option',
                      @configvalue = '1';

-- Causes stored procedures, triggers, and user-defined functions to be 
-- recompiled the next time that they are run. It does this by dropping the 
-- existing plan from the procedure cache forcing a new plan to be created the 
-- next time that the procedure or trigger is run.
EXEC sys.sp_recompile @objname = 'dbo.DropIndexes';

-- Closes the current error log file and cycles the error log extension numbers 
-- just like a server restart. The new error log contains version and copyright 
-- information and a line indicating that the new log has been created.
EXEC sys.sp_cycle_errorlog;

-- Returns information about the data types supported by the current environment.
EXEC sp_datatype_info;

-- 
EXEC sp_rename @objname = 'Sales.SalesTerritory', @newname = 'SalesTerr'; -- Table

EXEC sp_rename @objname = 'Sales.SalesTerritory.TerritoryID',
               @newname = 'TerrID',
               @objtype = 'COLUMN'; -- Column

EXEC sp_rename @objname = N'Purchasing.ProductVendor.IX_ProductVendor_VendorID',
               @newname = N'IX_VendorID',
               @objtype = N'INDEX'; -- Index

EXEC sp_rename @objname = N'Phone',
               @newname = N'Telephone',
               @objtype = N'USERDATATYPE'; -- Alias

EXEC sp_rename @objname = 'HumanResources.CK_Employee_BirthDate',
               @newname = 'CK_BirthDate'; -- Constraint

EXEC sp_rename @objname = 'Person.Person.ContactMail1',
               @newname = 'NewContact',
               @objtype = 'Statistics'; -- Statistic

-- Reduces the size of the backup and restore history tables by deleting the 
-- entries for backup sets older than the specified date. 
EXEC msdb..sp_delete_backuphistory @oldest_date = '01/14/2010';

-- Returns the metadata for the first possible result set of the Transact-SQL batch.
EXEC sys.sp_describe_first_result_set @tsql = N'SELECT object_id, name, type_desc 
												FROM sys.indexes';

-- Detaches a database that is currently not in use from a server instance and, 
-- optionally, runs UPDATE STATISTICS on all tables before detaching.
EXEC sys.sp_detach_db @dbname = 'AdventureWorks', @skipchecks = 'true';

-- Runs UPDATE STATISTICS against all user-defined and internal tables in the 
-- current database.
EXEC sys.sp_updatestats;

-- Provides information about current users, sessions, and processes in an 
-- instance of the Microsoft SQL Server Database Engine.
EXEC sys.sp_who;

EXEC sys.sp_who @loginame = 'Mary'; -- Login

EXEC sys.sp_who @loginame = 51; -- Session ID

EXEC sys.sp_who @loginame = 'active'; -- Excludes sessions that are waiting for 
                                      -- the next command from the user.


-- 
EXEC sys.sp_who2;

-- Displays statistics about Microsoft SQL Server.
EXEC sys.sp_monitor;

-- Drops a specified user-defined error message from an instance of the SQL 
-- Server Database Engine.
EXEC sys.sp_dropmessage @msgnum = 50001;

-- Executes a Transact-SQL statement or batch that can be reused many times, 
-- or one that has been built dynamically. The Transact-SQL statement or batch 
-- can contain embedded parameters.
DECLARE @IntVariable INT;
DECLARE @SQLString NVARCHAR(500);
DECLARE @ParmDefinition NVARCHAR(500);

SET @SQLString
    = N'SELECT BusinessEntityID, NationalIDNumber, JobTitle, LoginID  
       FROM AdventureWorks2012.HumanResources.Employee   
       WHERE BusinessEntityID = @BusinessEntityID';
SET @ParmDefinition = N'@BusinessEntityID tinyint';

/* Execute the string with the first parameter value. */
SET @IntVariable = 197;
EXECUTE sp_executesql @stmt = @SQLString,
                      @params = @ParmDefinition,
                      @BusinessEntityID = @IntVariable;

/* Execute the same string with the second parameter value. */
SET @IntVariable = 109;
EXECUTE sp_executesql @stmt = @SQLString,
                      @params = @ParmDefinition,
                      @BusinessEntityID = @IntVariable;

-------------------------------------------------------------------------------
-- Catalog Stored Procedures
-------------------------------------------------------------------------------

EXEC sp_columns @table_name = 'Posts';

EXEC sys.sp_databases;

EXEC sys.sp_server_info;

EXEC sys.sp_special_columns @table_name = 'Posts';

-- Returns column information for a single stored procedure or user-defined 
-- function in the current environment
EXEC sys.sp_sproc_columns;
EXEC sys.sp_sproc_columns @procedure_name = 'DropIndexes';
EXEC sys.sp_sproc_columns @procedure_owner = 'dbo';

-- Returns a list of all indexes and statistics on a specified table or 
-- indexed view
EXEC sys.sp_statistics @table_name = 'Posts';

-- Returns a list of table permissions (such as INSERT, DELETE, UPDATE, SELECT, 
-- REFERENCES) for the specified table or tables.
EXEC sys.sp_table_privileges @table_name = 'Post%';

-- Returns a list of objects that can be queried in the current environment. 
-- This means any table or view, except synonym objects
EXEC sys.sp_tables;
EXEC sys.sp_tables @table_name = 'Posts';

-------------------------------------------------------------------------------
-- Security Stored Procedures
-------------------------------------------------------------------------------

-- Returns a list of the fixed database roles
EXEC sys.sp_helpdbfixedrole;

-- Provides information about logins and the users associated with them in 
-- each database.
EXEC sys.sp_helplogins;
EXEC sys.sp_helplogins @LoginNamePattern = 'Mary';

-- Returns information about the direct members of a role in the 
-- current database
EXEC sys.sp_helprolemember;
EXEC sys.sp_helprolemember @rolename = 'sproc_exec';

-- Returns information about the roles in the current database
EXEC sys.sp_helprole;
EXEC sys.sp_helprole @rolename = 'sproc_exec';

-- Returns a list of the SQL Server fixed server roles
EXEC sys.sp_helpsrvrole;
EXEC sys.sp_helpsrvrole @srvrolename = 'sysadmin';

-- Returns information about the members of a SQL Server fixed server role
EXEC sys.sp_helpsrvrolemember;
EXEC sys.sp_helpsrvrolemember @srvrolename = 'sysadmin';

-- Reports information about Windows users and groups that are mapped to 
-- SQL Server principals but no longer exist in the Windows environment.
EXEC sys.sp_validatelogins;

-------------------------------------------------------------------------------
-- General Extended Stored Procedures
-------------------------------------------------------------------------------

-- Spawns a Windows command shell and passes in a string for execution. 
-- Any output is returned as rows of text.
EXEC master..xp_cmdshell 'dir *.exe';

EXEC xp_cmdshell 'copy c:\SQLbcks\AdvWorks.bck \\server2\backups\SQLbcks',
                 NO_OUTPUT;

DECLARE @result INT;
EXEC @result = xp_cmdshell 'dir *.exe';
IF (@result = 0)
    PRINT 'Success';
ELSE
    PRINT 'Failure';

DECLARE @cmd sysname,
        @var sysname;
SET @var = 'Hello world';
SET @cmd = 'echo ' + @var + ' > var_out.txt';
EXEC master..xp_cmdshell @cmd;

DECLARE @cmd2 sysname,
        @var2 sysname;
SET @var2 = 'dir/p';
SET @cmd2 = @var2 + ' > dir_out.txt';
EXEC master..xp_cmdshell @cmd2;

-- Returns information about Windows users and Windows groups.
EXEC xp_logininfo @acctname = 'BUILTIN\Administrators';

-- Provides a list of local Microsoft Windows groups or a list of global groups 
-- that are defined in a specified Windows domain.
EXEC xp_enumgroups 'ZKH';

-- Returns version information about Microsoft SQL Server. xp_msver also returns 
-- information about the actual build number of the server and information about 
-- the server environment.
EXEC sys.xp_msver;

-- Grants or revoke a Windows group or user access to SQL Server.
EXEC sys.xp_grantlogin @loginame = 'mboom';
EXEC sys.xp_revokelogin @loginame = 'mboom';

-- Logs a user-defined message in the SQL Server log file and in the 
-- Windows Event Viewer.
DECLARE @@TABNAME VARCHAR(30),
        @@USERNAME VARCHAR(30),
        @@MESSAGE VARCHAR(255);
SET @@TABNAME = 'customers';
SET @@USERNAME = USER_NAME();
SELECT @@MESSAGE = 'The table ' + @@TABNAME + ' is not owned by the user ' + @@USERNAME + '.';
EXEC master..xp_logevent 60000, @@MESSAGE, informational;

-- Formats and stores a series of characters and values in the string output parameter. 
-- Each format argument is replaced with the corresponding argument.
DECLARE @a AS VARCHAR(20) = 'SQL SERVER RIDER';
DECLARE @b AS VARCHAR(50);
EXEC xp_sprintf @b OUTPUT, 'My blog name is %s', @a;
SELECT @b AS "Heading";

DECLARE @a2 AS VARCHAR(20);
DECLARE @b2 AS VARCHAR(10) = CAST(GETDATE() AS DATE);
EXEC xp_sprintf @a2 OUTPUT, 'Today : %s', @b2;
SELECT @a2 AS "Page Header";

-- Reads data from the string into the argument locations specified by 
-- each format argument.
DECLARE @filename VARCHAR(20),
        @message VARCHAR(20);
EXEC xp_sscanf 'sync -b -fproducts10.tmp -rrandom',
               'sync -b -f%s -r%s',
               @filename OUTPUT,
               @message OUTPUT;
SELECT @filename,
       @message;

-------------------------------------------------------------------------------
-- SQL Server Agent Stored Procedures
-------------------------------------------------------------------------------

-- SELECT * FROM sys.messages

-- Creates an alert and tests it.
EXEC msdb.dbo.sp_add_alert @name = N'Test Alert',
                           @message_id = 50001,
                           @severity = 0,
                           @notification_message = N'Error 55001 has occurred. Index user statistics will be gathered...',
                           @job_name = N'Collect Index Usage Statistics';
RAISERROR(50001, 16, 1) WITH LOG;

-- Adds the specified category of jobs, alerts, or operators to the server.
EXEC msdb.dbo.sp_add_category @class = N'JOB',
                              @type = N'LOCAL',
                              @name = N'AdminJobs';

-- Adds a new job executed by the SQL Agent service.
EXEC msdb.dbo.sp_add_job @job_name = N'NightlyBackups';

EXEC msdb.dbo.sp_add_job @job_name = N'Ad hoc Sales Data Backup',
                         @enabled = 1,
                         @description = N'Ad hoc backup of sales data',
                         @owner_login_name = N'sa',
                         @notify_level_eventlog = 2,
                         @notify_level_email = 2,
                         @notify_level_netsend = 2,
                         @notify_level_page = 2,
                         @notify_email_operator_name = N'Mark Boomaars',
                         @notify_netsend_operator_name = N'Mark Boomaars',
                         @notify_page_operator_name = N'Mark Boomaars',
                         @delete_level = 1;

-- Creates a schedule for a SQL Agent job.
EXEC msdb.dbo.sp_add_jobschedule @job_name = N'Ad hoc Sales Data Backup', -- Job name
                                 @name = N'Ad hoc backup of sales data',  -- Schedule name
                                 @freq_type = 8,                          -- Weekly
                                 @freq_interval = 64,                     -- Saturday
                                 @freq_recurrence_factor = 1,             -- every week
                                 @active_start_time = 20000;              -- 2:00 AM

-- Adds a step (operation) to a SQL Agent job
EXEC msdb.dbo.sp_add_jobstep @job_name = N'Ad hoc Sales Data Backup',
                             @step_name = N'Set database to read only',
                             @subsystem = N'TSQL',
                             @command = N'ALTER DATABASE SALES SET READ_ONLY',
                             @retry_attempts = 5,
                             @retry_interval = 5;

-- Sets up a notification for an alert.
EXEC msdb.dbo.sp_add_notification @alert_name = N'Test Alert',
                                  @operator_name = N'Mark Boomaars',
                                  @notification_method = 1;

-- Creates an operator (notification recipient) for use with alerts and jobs.
EXEC msdb.dbo.sp_add_operator @name = N'Dan Wilson',
                              @enabled = 1,
                              @email_address = N'mboomaars@gmail.com',
                              @pager_address = N'5551290AW@pager.Adventure-Works.com',
                              @weekday_pager_start_time = 080000,
                              @weekday_pager_end_time = 170000,
                              @pager_days = 62;

-- Adds the specified SQL Server Agent proxy.
--
-- A SQL Server Agent proxy manages security for job steps that involve subsystems 
-- other than the Transact-SQL subsystem. Each proxy corresponds to a security 
-- credential. A proxy may have access to any number of subsystems.
EXEC msdb.dbo.sp_add_proxy @proxy_name = 'Catalog application proxy',
                           @enabled = 1,
                           @description = 'Maintenance tasks on catalog application.',
                           @credential_name = 'CatalogApplicationCredential';

-- Creates a schedule that can be used by any number of jobs.
EXEC msdb.dbo.sp_add_schedule @schedule_name = N'RunOnce',
                              @freq_type = 1,
                              @active_start_time = 233000;

EXEC msdb.dbo.sp_add_schedule @schedule_name = N'NightlyJobs',
                              @freq_type = 4,
                              @freq_interval = 1,
                              @active_start_time = 010000;

-- Sets a schedule for a job.
EXEC msdb.dbo.sp_attach_schedule @job_name = N'BackupDatabase',
                                 @schedule_name = N'NightlyJobs';

EXEC msdb.dbo.sp_attach_schedule @job_name = N'RunReports',
                                 @schedule_name = N'RunOnce';

-- Closes the current SQL Server Agent error log file and cycles the SQL 
-- Server Agent error log extension numbers just like a server restart.
EXEC msdb.dbo.sp_cycle_agent_errorlog;

-- Closes the current error log file and cycles the error log extension 
-- numbers just like a server restart.
EXEC msdb.dbo.sp_cycle_errorlog;

-- Removes an alert.
EXEC msdb.dbo.sp_delete_alert @name = N'Test Alert';

-- Deleting a category recategorizes any jobs, alerts, or operators in that 
-- category to the default category for the class.
EXEC msdb.dbo.sp_delete_category @name = N'AdminJobs', @class = N'JOB';

-- Deletes a job.
EXEC msdb.dbo.sp_delete_job @job_name = N'Ad hoc Sales Data Backup';

-- Deletes a schedule for a job.
EXEC msdb.dbo.sp_delete_schedule;

-- Removes a job step from a job.
EXEC msdb.dbo.sp_delete_jobstep @job_name = N'Weekly Sales Data Backup',
                                @step_id = 1;

-- Removes all SQL Server Agent job step logs that are specified with the arguments.
EXEC msdb.dbo.sp_delete_jobsteplog @job_name = N'Weekly Sales Data Backup';

EXEC msdb.dbo.sp_delete_jobsteplog @job_name = N'Weekly Sales Data Backup',
                                   @step_id = 2;

-- Removes a SQL Server Agent notification definition for a specific 
-- alert and operator.
EXEC msdb.dbo.sp_delete_notification @alert_name = 'Test Alert',
                                     @operator_name = 'Mark Boomaars';

-- Removes an operator.
EXEC msdb.dbo.sp_delete_operator @name = 'Dan Wilson';

-- Removes the specified proxy.
EXEC msdb.dbo.sp_delete_proxy @proxy_name = N'Catalog application proxy';

-- Deletes a schedule
EXEC msdb.dbo.sp_delete_schedule @schedule_name = N'NightlyJobs';
EXEC msdb.dbo.sp_delete_schedule @schedule_name = 'RunOnce',
                                 @force_delete = 1;

-- Removes an association between a schedule and a job.
EXEC msdb.dbo.sp_detach_schedule @job_name = 'BackupDatabase',
                                 @schedule_name = 'NightlyJobs';

-- Lists associations between security principals and proxies.
EXEC msdb.dbo.sp_enum_login_for_proxy;
EXEC msdb.dbo.sp_enum_login_for_proxy @name = 'terrid';

-- Grants a security principal access to a proxy.
EXEC msdb.dbo.sp_grant_login_to_proxy @login_name = N'adventure-works\terrid',
                                      @proxy_name = N'Catalog application proxy';

-- Reports information about the alerts defined for the server.
EXEC msdb.dbo.sp_help_alert;
EXEC msdb.dbo.sp_help_alert @alert_name = 'Demo: Sev. 25 Errors';

-- Provides information about the specified classes of jobs, alerts, or operators.
EXEC msdb.dbo.sp_help_category @type = N'LOCAL';
EXEC msdb.dbo.sp_help_category @class = N'ALERT', @name = N'Replication';

-- Returns information about jobs that are used by SQL Server Agent to 
-- perform automated activities in SQL Server.
EXEC msdb.dbo.sp_help_job;

EXEC msdb.dbo.sp_help_job @job_type = N'LOCAL',
                          @owner_login_name = N'sa',
                          @enabled = 1,
                          @execution_status = 1; -- Executing

EXEC msdb.dbo.sp_help_job @job_name = N'Output File Cleanup',
                          @job_aspect = N'ALL';

-- Lists information about the runtime state of SQL Server Agent jobs.
EXEC msdb.dbo.sp_help_jobactivity;

-- Provides the number of jobs that a schedule is attached to.
EXEC msdb.dbo.sp_help_jobcount @schedule_name = N'NightlyJobs';

-- Provides information about the jobs for servers in the multiserver 
-- administration domain.
EXEC msdb.dbo.sp_help_jobhistory @job_name = N'NightlyBackups';

EXEC msdb.dbo.sp_help_jobhistory @sql_message_id = 50100,
                                 @sql_severity = 20,
                                 @run_status = 0,
                                 @mode = N'FULL';

-- Returns information about the jobs that a particular schedule is attached to.
EXEC msdb.dbo.sp_help_jobs_in_schedule @schedule_name = N'NightlyJobs';

-- Returns information about the scheduling of jobs used by SQL Server 
-- Management Studio to perform automated activities.
EXEC msdb.dbo.sp_help_jobschedule @job_name = N'IndexOptimize - USER_DATABASES';

EXEC msdb.dbo.sp_help_jobschedule @job_name = N'RunReports',
                                  @schedule_name = N'NightlyJobs';

EXEC msdb.dbo.sp_help_jobschedule @job_name = N'RunReports',
                                  @schedule_name = N'NightlyJobs',
                                  @include_description = 1;

-- Returns information for the steps in a job used by SQL Server Agent 
-- service to perform automated activities.
EXEC msdb.dbo.sp_help_jobstep @job_name = N'IndexOptimize - USER_DATABASES';

EXEC msdb.dbo.sp_help_jobstep @job_name = N'StatisticsOptimize - USER_DATABASES',
                              @step_id = 1;

-- Returns metadata about a specific SQL Server Agent job step log.
EXEC msdb.dbo.sp_help_jobsteplog @job_name = N'CommandLog Cleanup';

EXEC msdb.dbo.sp_help_jobsteplog @job_name = N'Weekly Sales Data Backup',
                                 @step_id = 1;

-- Reports a list of alerts for a given operator or a list of operators for a given alert.
EXEC msdb.dbo.sp_help_notification @object_type = N'ALERTS',
                                   @name = N'Mark Boomaars',
                                   @enum_type = N'ACTUAL',
                                   @notification_method = 7; -- Listing alerts for a specific operator

EXEC msdb.dbo.sp_help_notification @object_type = N'OPERATORS',
                                   @name = N'LT-RSD-01 Alert - Error 823: The operating system returned an error',
                                   @enum_type = N'ACTUAL',
                                   @notification_method = 7; -- Listing operators for a specific alert

-- Reports information about the operators defined for the server
EXEC msdb.dbo.sp_help_operator @operator_name = N'Mark Boomaars';

-- Lists information for one or more proxies.
EXEC msdb.dbo.sp_help_proxy;
EXEC msdb.dbo.sp_help_proxy @proxy_name = N'Catalog application proxy';

-- Lists information about schedules.
EXEC msdb.dbo.sp_help_schedule;
EXEC msdb.dbo.sp_help_schedule @schedule_name = N'15 minuten';

-- Deletes or reassigns jobs that belong to the specified login
EXEC msdb.dbo.sp_manage_jobs_by_login @action = N'REASSIGN', -- DELETE
                                      @current_owner_login_name = N'danw',
                                      @new_owner_login_name = N'sa';

-- Sends an e-mail message to an operator using Database Mail.
EXEC msdb.dbo.sp_notify_operator @profile_name = N'KPNMail',
                                 @name = N'Mark Boomaars',
                                 @subject = N'Test Notification',
                                 @body = N'This is a test of notification via e-mail.';

-- Removes the history records for a job.
EXEC msdb.dbo.sp_purge_jobhistory;
EXEC msdb.dbo.sp_purge_jobhistory @job_name = N'NightlyBackups';

-- Removes access to a proxy for a security principal.
EXEC msdb.dbo.sp_revoke_login_from_proxy @name = N'terrid',
                                         @proxy_name = N'Catalog application proxy';

-- Instructs SQL Server Agent to execute a job immediately
EXEC msdb.dbo.sp_start_job N'CommandLog Cleanup';

-- Instructs SQL Server Agent to stop the execution of a job
EXEC msdb.dbo.sp_stop_job N'Weekly Sales Data Backup';

-- Updates the settings of an existing alert
EXEC msdb.dbo.sp_update_alert @name = N'Test Alert', @enabled = 0;

-- Changes the name of a category.
EXEC msdb.dbo.sp_update_category @class = N'JOB',
                                 @name = N'AdminJobs',
                                 @new_name = N'Administrative Jobs';

-- Changes the attributes of a job
EXEC msdb.dbo.sp_update_job @job_name = N'NightlyBackups',
                            @new_name = N'NightlyBackups -- Disabled',
                            @description = N'Nightly backups disabled during server migration.',
                            @enabled = 0;

-- Changes the setting for a step in a job that is used to perform 
-- automated activities.
EXEC msdb.dbo.sp_update_jobstep @job_name = N'Weekly Sales Data Backup',
                                @step_id = 1,
                                @retry_attempts = 10;

-- Updates the notification method of an alert notification.
EXEC msdb.dbo.sp_update_notification @alert_name = N'Test Alert',
                                     @operator_name = N'Mark Boomaars',
                                     @notification_method = 7;

-- Updates information about an operator (notification recipient) 
-- for use with alerts and jobs.
EXEC msdb.dbo.sp_update_operator @name = N'Mark Boomaars',
                                 @enabled = 1,
                                 @email_address = N'mboomaars@gmail.com',
                                 @pager_address = N'5551290AW@pager.Adventure-Works.com',
                                 @weekday_pager_start_time = 080000,
                                 @weekday_pager_end_time = 170000,
                                 @pager_days = 64;

-- Changes the properties of an existing proxy.
EXEC msdb.dbo.sp_update_proxy @proxy_name = 'Catalog application proxy',
                              @enabled = 0;

-- Changes the settings for a SQL Server Agent schedule.
EXEC msdb.dbo.sp_update_schedule @name = 'NightlyJobs',
                                 @enabled = 0,
                                 @owner_login_name = 'terrid';

