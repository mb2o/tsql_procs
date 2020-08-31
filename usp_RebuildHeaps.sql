create procedure dbo.sp_RebuildHeaps 
	@DatabaseName            nvarchar(100) = null, 
	@MinNumberOfPages        int           = 1000, 
	@LogToTable              nvarchar(max) = 'N', 
	@LogMessagePriority      nvarchar(max) = 100, 
	@LogMessageFindingsGroup nvarchar(max) = 'Maintenance', 
	@LogMessageFinding       nvarchar(max) = 'Rebuild Heap', 
	@DryRun                  nvarchar(max) = 'N'
as
begin

	----------------------------------------------------------------------------------------------------
	--// Source:  https://www.bravisziekenhuis.nl                                                   //--
	--// License: MIT																				//--
	--// Author:  M. Boomaars																		//--
	--// Version: 2020-01-03 13:00																	//--
	----------------------------------------------------------------------------------------------------

	set nocount on;
	set arithabort on;
	set numeric_roundabort off;

	declare @db_id                    int, 
			@db_name                  sysname        = @DatabaseName, 
			@object_id                int, 
			@schema_name              sysname, 
			@table_name               sysname, 
			@page_count               bigint, 
			@record_count             bigint, 
			@forwarded_record_count   bigint, 
			@forwarded_record_percent decimal(10, 2), 
			@sql                      nvarchar(max), 
			@msg                      nvarchar(max), 
			@EndMessage               nvarchar(max), 
			@ErrorMessage             nvarchar(max), 
			@EmptyLine                nvarchar(max)  = CHAR(9), 
			@Error                    int            = 0, 
			@ReturnCode               int            = 0, 
			@startTime                datetime;


	if @DatabaseName is null
	begin
		set @ErrorMessage = 'The @DatabaseName parameter must be specified and cannot be NULL. Stopping execution...';
		raiserror('%s', 16, 1, @ErrorMessage) with nowait;
		set @Error = @@ERROR;
		raiserror(@EmptyLine, 10, 1) with nowait;
	end;

	if @Error <> 0
	begin
		set @ReturnCode = @Error;
		goto Logging;
	end;

	-- Prepare our working table
	------------------------------------------------------------------------------------------------------
	if OBJECT_ID(N'FragmentedHeaps', N'U') is null
	begin
		raiserror('Creating work table', 10, 1) with nowait;

		create table FragmentedHeaps
		(
			object_id                int not null, 
			page_count               bigint not null, 
			record_count             bigint not null, 
			forwarded_record_count   bigint not null, 
			forwarded_record_percent decimal(10, 2));

		declare heapdb cursor static
		for select d.database_id, 
				   d.name
			from sys.databases as d
			where d.name = @db_name;

		open heapdb;

		while 1 = 1
		begin
			fetch next from heapdb into @db_id, 
										@db_name;

			if @@FETCH_STATUS <> 0
				break;

			-- Loop through all heaps
			raiserror('Looping through all heaps', 10, 1) with nowait;

			set @sql = '
				DECLARE heaps CURSOR GLOBAL STATIC FOR
					SELECT i.object_id 
					FROM ' + QUOTENAME(DB_NAME(@db_id)) + '.sys.indexes AS i 
					INNER JOIN ' + QUOTENAME(DB_NAME(@db_id)) + '.sys.objects AS o ON o.object_id = i.object_id
					WHERE i.type_desc = ''HEAP''
						AND o.type_desc = ''USER_TABLE''
			';
			execute sp_executesql @sql;

			open heaps;

			while 1 = 1
			begin
				fetch next from heaps into @object_id;

				if @@FETCH_STATUS <> 0
					break;

				insert into FragmentedHeaps (object_id, 
											 page_count, 
											 record_count, 
											 forwarded_record_count, 
											 forwarded_record_percent) 
				select P.object_id, 
					   P.page_count, 
					   P.record_count, 
					   P.forwarded_record_count, 
					   ( CAST(P.forwarded_record_count as decimal(10, 2)) / CAST(P.record_count as decimal(10, 2)) ) * 100
				from sys.dm_db_index_physical_stats(@db_id, @object_id, 0, null, 'DETAILED') as P
				where P.page_count > @MinNumberOfPages
					  and P.forwarded_record_count > 0;
			end;

			close heaps;
			deallocate heaps;
		end;

		close heapdb;
		deallocate heapdb;
	end;

	-- Start the actual hard work
	------------------------------------------------------------------------------------------------------
	if @DryRun = 'Y'
		raiserror('Performing a dry run. Nothing will be executed or logged...', 10, 1) with nowait;

	raiserror('Starting the hard work', 10, 1) with nowait;

	select @db_id = d.database_id
	from sys.databases as d
	where d.name = @db_name;

	declare worklist cursor static
	for select top 2 object_id, 
					 page_count, 
					 record_count, 
					 forwarded_record_count, 
					 forwarded_record_percent
		from FragmentedHeaps
		order by forwarded_record_percent desc;

	open worklist;

	while 1 = 1
	begin
		fetch next from worklist into @object_id, 
									  @page_count, 
									  @record_count, 
									  @forwarded_record_count, 
									  @forwarded_record_percent;

		if @@FETCH_STATUS <> 0
			break;

		set @schema_name = OBJECT_SCHEMA_NAME(@object_id, @db_id);
		set @table_name = OBJECT_NAME(@object_id, @db_id);
		set @startTime = GETDATE();

		set @msg = CONCAT('Rebuilding [', @db_name, '].[', @schema_name, '].[', @table_name, '] because of ', @forwarded_record_count, ' forwarded records (', @forwarded_record_percent, ')');
		if @DryRun = 'N'
		   and @LogToTable = 'Y'
		begin
			exec sp_BlitzFirst @LogMessage = @msg, @LogMessagePriority = @LogMessagePriority, @LogMessageFindingsGroup = @LogMessageFindingsGroup, @LogMessageFinding = @LogMessageFinding;
		end;
		raiserror(@msg, 10, 1) with nowait;

		set @sql = 'ALTER TABLE ' + QUOTENAME(@db_name) + '.' + QUOTENAME(@schema_name) + '.' + QUOTENAME(@table_name) + ' REBUILD WITH (ONLINE = ON);';
		if @DryRun = 'N'
			execute sp_executesql @sql;

		raiserror(@sql, 10, 1) with nowait;

		set @msg = CONCAT('[', @db_name, '].[', @schema_name, '].[', @table_name, '] was rebuilt successfully');
		if @DryRun = 'N'
		   and @LogToTable = 'Y'
		begin
			exec sp_BlitzFirst @LogMessage = @msg, @LogMessagePriority = @LogMessagePriority, @LogMessageFindingsGroup = @LogMessageFindingsGroup, @LogMessageFinding = @LogMessageFinding;
		end;
		raiserror(@msg, 10, 1) with nowait;

		-- Remove processed heap from working table
		if @DryRun = 'N'
		begin
			delete from FragmentedHeaps
			where object_id = @object_id;
		end;

		if @DryRun = 'N'
		begin
			set @sql = QUOTENAME(@schema_name) + '.' + QUOTENAME(@table_name);
			execute sp_recompile @sql;
		end;

		-- @TODO Clean up worktable when no more entries, so process can start over
	end;

	close worklist;
	deallocate worklist;

	----------------------------------------------------------------------------------------------------
	--// Log completing information                                                                 //--
	----------------------------------------------------------------------------------------------------

	Logging:
	set @EndMessage = 'Date and time: ' + CONVERT(nvarchar, GETDATE(), 120);
	raiserror('%s', 10, 1, @EndMessage) with nowait;

	raiserror(@EmptyLine, 10, 1) with nowait;

	if @ReturnCode <> 0
	begin
		return @ReturnCode;
	end;

end;