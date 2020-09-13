# Stored Procedures

## usp_DatabaseBackupChain

Creates a list of `RESTORE` statements that have to be executed in order to return to a particular point in time.

### Syntax

```
usp_DatabaseBackupChain [ @DatabaseName = ] 'name' [, [ @RecoveryPoint = ] datetime ]
```

### Arguments

##### @DatabaseName

The name of the database to be restored. The sproc will automatically append *_Restored* to this name.

##### @RecoveryPoint

The exact point in time to where the database should be restored. Provide this in the format "yyyy-mm-ddThh:mm:ss".

### Example

```sql
EXEC dbo.usp_DatabaseBackupChain @DatabaseName = 'Playground',
								 @RecoveryPoint = '2020-09-10T07:37:09';
```

## usp_ReadCommandLog

Retrieves useful information from Ola Hallengren's **CommandLog** table.

### Syntax

```
usp_ReadCommandLog [ @DatabaseName = ] 'name' [, [ @Days = ] number ]
```

### Arguments

##### @DatabaseName

The name of the database for which you wish to retrieve the performed actions.

##### @Days

The number of days you wish to go back in time.

### Example

```sql
EXEC dbo.usp_ReadCommandLog @DatabaseName = 'StackOverflow2013', @Days = 7; -- Shows all work done in the past week
```

## usp_RebuildHeaps



## Helpful System Stored Procedures

