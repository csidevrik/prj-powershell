CreateTaskSckedule
===================


La mejor manera segun el tutorial es 

- 1. Create schedule.service object

```powershell
$scheduleObject = New-Object -ComObject schedule.service
```

- 2. Connect to the schedule service.

```shell
$scheduleObject.connect()
```


- 3. Create a folder object.

```powershell
$rootFolder = $scheduleObject.GetFolder("\")
```

- 4. Create a new folder
```powershell
$rootFolder.CreateFolder("PoshTasks")
```




Bibliografia
-------------------

- [powershell to create schedule tasks folder](https://devblogs.microsoft.com/scripting/use-powershell-to-create-scheduled-tasks-folders/)