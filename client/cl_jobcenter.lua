--[[
    App: Job Center
]]

JobCenter = {
    Jobs = {},
    CurrentJob = nil,
    CurrentGroup = nil,
    IsSearching = false,
    HasJobOffer = false,
    CurrentJobTasks = nil,
    CurrentTaskNotify = nil,
}

-- Loops
Citizen.CreateThread(function()
    while true do
        if LocalPlayer.state.LoggedIn then
            if JobCenter.CurrentJob ~= nil then
                if not exports['quantum-inventory']:HasEnoughOfItem('vpn', 1) then
                    local IsRequired = CallbackModule.SendCallback("quantum-phone/server/jobcenter/is-vpn-required", JobCenter.CurrentJob)
                    if IsRequired then
                        TriggerServerEvent('quantum-phone/server/jobcenter/check-out')
                    end
                end
            end
        end

        Citizen.Wait(2000)
    end
end)

-- Functions
function JobCenter.Render()
    local Jobs = CallbackModule.SendCallback("quantum-phone/server/jobcenter/get-jobs")
    local FilteredJobs = FilterJobs(Jobs)
    JobCenter.Jobs = FilteredJobs

    exports['quantum-ui']:SendUIMessage("Phone", "RenderJobCenterApp", {
        Jobs = JobCenter.Jobs
    })

    if JobCenter.CurrentJob ~= nil and JobCenter.CurrentGroup == nil then
        local Groups = CallbackModule.SendCallback("quantum-phone/server/jobcenter/get-groups", JobCenter.CurrentJob)
        exports['quantum-ui']:SendUIMessage("Phone", "UpdateJobCenterAvailableGroups", Groups)
    end
end

function FilterJobs(Jobs)
    local FilteredJobs = {}
    local VPNItem = exports['quantum-inventory']:HasEnoughOfItem('vpn', 1)
    for k, v in pairs(Jobs) do
        if v['RequiresVPN'] then
            if VPNItem then
                FilteredJobs[k] = v
            end
        else
            FilteredJobs[k] = v
        end
    end
    return FilteredJobs
end

-- Events


RegisterNetEvent("quantum-phone/client/jobcenter/update", function()
    local Jobs = CallbackModule.SendCallback("quantum-phone/server/jobcenter/get-jobs")
    local FilteredJobs = FilterJobs(Jobs)
    JobCenter.Jobs = FilteredJobs
end)

RegisterNetEvent('quantum-phone/client/jobcenter/check-out', function()
    if JobCenter.CurrentGroup then
        TriggerEvent('quantum-phone/client/hide-notification', JobCenter.CurrentTaskNotify)
        TriggerServerEvent('quantum-phone/server/jobcenter/leave-group', JobCenter.CurrentJob)
        JobCenter.IsSearching = false
        Citizen.Wait(500)
    end

    JobCenter.CurrentJob = nil
    JobCenter.CurrentGroup = nil
    
    exports['quantum-ui']:SendUIMessage("Phone", "SetJobCenterAppPage", {
        Jobs = true,
        Groups = false,
        Tasks = false,
        GroupMembers = false,
    })
end)

RegisterNetEvent('quantum-phone/client/jobcenter/check-in', function(Job)
    JobCenter.CurrentJob = Job

    if exports['quantum-inventory']:HasEnoughOfItem('phone', 1) then
        exports['quantum-ui']:SendUIMessage('Phone', 'Notification', {
            Title = "Job Center",
            Message = "Checked In as a " .. (Job:gsub("^%l", string.upper)) .. " Worker",
            Icon = "fas fa-house",
            IconBgColor = "#171717",
            IconColor = "white",
            Sticky = false,
            Duration = 3000,
        })
    end
    
    exports['quantum-ui']:SendUIMessage("Phone", "SetJobCenterAppPage", {
        Jobs = false,
        Groups = true,
        Tasks = false,
        GroupMembers = false,
    })
end)


RegisterNetEvent("quantum-phone/client/jobcenter/refresh-group", function(Data)
    exports['quantum-ui']:SendUIMessage("Phone", "UpdateJobCenterGroup", Data)
end)

RegisterNetEvent("quantum-phone/client/jobcenter/refresh-all-groups", function(Job)
    if JobCenter.CurrentJob ~= Job then return end
    
    local Groups = CallbackModule.SendCallback("quantum-phone/server/jobcenter/get-groups", JobCenter.CurrentJob)
    exports['quantum-ui']:SendUIMessage("Phone", "UpdateJobCenterAvailableGroups", Groups)
end)

-- Canceling through the UI source
RegisterNetEvent('quantum-phone/client/jobcenter/cancel-join-request', function(Data)
    exports['quantum-ui']:SendUIMessage("Phone", "JobCenterResetJoinRequest", {})
    TriggerServerEvent("quantum-phone/server/jobcenter/cancel-join-request", JobCenter.CurrentJob, Data)
end)

RegisterNetEvent('quantum-phone/client/jobcenter/accept-join-request', function(Data) -- Server side trigger
    TriggerServerEvent('quantum-phone/server/jobcenter/answer-request', JobCenter.CurrentJob, Data, true)
end)

RegisterNetEvent('quantum-phone/client/jobcenter/decline-job-request', function(Data) -- Server side trigger
    TriggerServerEvent('quantum-phone/server/jobcenter/answer-request', JobCenter.CurrentJob, Data, false)
end)

RegisterNetEvent('quantum-phone/client/jobcenter/request-task-success', function(TaskId, Finished)
    if JobCenter.CurrentJobTasks == nil then LoggerModule.Error("Phone/Jobcenter(SuccessTask)", "Can't set task Finished, player is not doing any tasks.") return end
    TriggerServerEvent('quantum-phone/server/jobcenter/success-task', JobCenter.CurrentJob, TaskId, Finished)
end)

RegisterNetEvent('quantum-phone/client/jobcenter/success-task', function(TaskId, Finished)
    if JobCenter.CurrentJobTasks == nil then LoggerModule.Error("Phone/Jobcenter(SuccessTask)", "Can't set task Finished, player is not doing any tasks.") return end
    JobCenter.CurrentJobTasks.Tasks[tonumber(TaskId)].Finished = Finished

    local TaskData = JobCenter.CurrentJobTasks.Tasks[tonumber(TaskId + 1)]
    TriggerEvent('quantum-phone/client/hide-notification', JobCenter.CurrentTaskNotify)
    JobCenter.CurrentTaskNotify = math.random(111111, 999999)
    if TaskData ~= nil then
        TriggerEvent('quantum-phone/client/notification', {
            Title = "CURRENT",
            Message = TaskData.Text .. (TaskData.ExtraRequired ~= nil and (' (%s/%s)'):format(TaskData.ExtraDone, TaskData.ExtraRequired) or ''),
            Icon = "fas fa-people-carry",
            IconBgColor = "#a3c8e5",
            IconColor = "white",
            Sticky = true,
            Id = JobCenter.CurrentTaskNotify,
        })
        TriggerEvent('quantum-phone/client/jobcenter/on-task-done', JobCenter.CurrentJob, TaskId, TaskId + 1, JobCenter.CurrentGroup)
    else
        EventsModule.TriggerServer("quantum-phone/server/jobcenter/job-done", JobCenter.CurrentJob)
        exports['quantum-ui']:SendUIMessage("Phone", "SetJobCenterAppPage", {
            Jobs = false,
            Groups = false,
            Tasks = false,
            GroupMembers = true,
        })
        TriggerServerEvent('quantum-phone/server/jobcenter/set-ready', JobCenter.CurrentJob, true)
    end
        
    exports['quantum-ui']:SendUIMessage("Phone", "JobCenterUpdateTasks", JobCenter.CurrentJobTasks)
    if TaskData == nil then TriggerEvent('quantum-phone/client/jobcenter/job-tasks-done', JobCenter.CurrentJob, JobCenter.CurrentGroup) end
end)

RegisterNetEvent('quantum-phone/client/jobcenter/reset-group', function()
    TriggerEvent('quantum-phone/client/hide-notification', JobCenter.CurrentTaskNotify)
    JobCenter.CurrentGroup = nil
    JobCenter.IsSearching = false
    JobCenter.HasJobOffer = false
    JobCenter.CurrentJobTasks = nil
    JobCenter.CurrentTaskNotify = nil

    exports['quantum-ui']:SendUIMessage("Phone", "SetJobCenterAppPage", {
        Jobs = false,
        Groups = true,
        Tasks = false,
        GroupMembers = false,
    })
end)

RegisterNetEvent('quantum-phone/client/jobcenter/request-task-update', function(TaskId, ExtraDone)
    if JobCenter.CurrentJobTasks == nil then LoggerModule.Error("Phone/Jobcenter(UpdateTask)", "Can't set task ExtraDone, player is not doing any tasks.") return end
    TriggerServerEvent('quantum-phone/server/jobcenter/update-task', JobCenter.CurrentJob, TaskId, ExtraDone)
end)

RegisterNetEvent('quantum-phone/client/jobcenter/update-task', function(TaskId, ExtraDone)
    if JobCenter.CurrentJobTasks == nil then LoggerModule.Error("Phone/Jobcenter(UpdateTask)", "Can't set task ExtraDone, player is not doing any tasks.") return end
    if JobCenter.CurrentJobTasks.Tasks[tonumber(TaskId)].Finished then return end
    
    JobCenter.CurrentJobTasks.Tasks[tonumber(TaskId)].ExtraDone = JobCenter.CurrentJobTasks.Tasks[tonumber(TaskId)].ExtraDone + ExtraDone

    local TaskData = JobCenter.CurrentJobTasks.Tasks[tonumber(TaskId)]
    exports['quantum-ui']:SendUIMessage('Phone', 'SetNotificationText', {
        NotificationId = JobCenter.CurrentTaskNotify,
        Text = TaskData.Text .. (TaskData.ExtraRequired ~= nil and (' (%s/%s)'):format(TaskData.ExtraDone, TaskData.ExtraRequired) or ''),
    })
    
    if TaskData.ExtraDone == JobCenter.CurrentJobTasks.Tasks[tonumber(TaskId)].ExtraRequired then
        TaskData = JobCenter.CurrentJobTasks.Tasks[tonumber(TaskId + 1)]
        JobCenter.CurrentJobTasks.Tasks[tonumber(TaskId)].Finished = true
        TriggerEvent('quantum-phone/client/hide-notification', JobCenter.CurrentTaskNotify)
        JobCenter.CurrentTaskNotify = math.random(111111, 999999)
        if TaskData ~= nil then
            TriggerEvent('quantum-phone/client/notification', {
                Title = "CURRENT",
                Message = TaskData.Text .. (TaskData.ExtraRequired ~= nil and (' (%s/%s)'):format(TaskData.ExtraDone, TaskData.ExtraRequired) or ''),
                Icon = "fas fa-people-carry",
                IconBgColor = "#a3c8e5",
                IconColor = "white",
                Sticky = true,
                Id = JobCenter.CurrentTaskNotify,
            })
            TriggerEvent('quantum-phone/client/jobcenter/on-task-done', JobCenter.CurrentJob, TaskId, TaskId + 1, JobCenter.CurrentGroup)
        else
            EventsModule.TriggerServer("quantum-phone/server/jobcenter/job-done", JobCenter.CurrentJob)
            exports['quantum-ui']:SendUIMessage("Phone", "SetJobCenterAppPage", {
                Jobs = false,
                Groups = false,
                Tasks = false,
                GroupMembers = true,
            })
            TriggerServerEvent('quantum-phone/server/jobcenter/set-ready', JobCenter.CurrentJob, true)
        end
    end

    exports['quantum-ui']:SendUIMessage("Phone", "JobCenterUpdateTasks", JobCenter.CurrentJobTasks)
    if TaskData == nil then TriggerEvent('quantum-phone/client/jobcenter/job-tasks-done', JobCenter.CurrentJob, JobCenter.CurrentGroup) end
end)

RegisterNetEvent('quantum-phone/client/jobcenter/start-job-offer', function() -- Server triggered
    local Tasks = exports['quantum-jobs']:GetJobTasks(JobCenter.CurrentJob, JobCenter.CurrentGroup)
    JobCenter.CurrentJobTasks = Tasks
    
    TriggerEvent('quantum-phone/client/jobcenter/on-job-start', JobCenter.CurrentJob, JobCenter.CurrentGroup)
    
    exports['quantum-ui']:SendUIMessage("Phone", "SetJobCenterAppPage", {
        Jobs = false,
        Groups = false,
        Tasks = true,
        GroupMembers = false,
    })
    
    local TaskData = JobCenter.CurrentJobTasks.Tasks[1]
    JobCenter.CurrentTaskNotify = math.random(111111, 999999)
    TriggerEvent('quantum-phone/client/notification', {
        Title = "CURRENT",
        Message = TaskData.Text .. (TaskData.ExtraRequired ~= nil and (' (%s/%s)'):format(TaskData.ExtraDone, TaskData.ExtraRequired) or ''),
        Icon = "fas fa-people-carry",
        IconBgColor = "#a3c8e5",
        IconColor = "white",
        Sticky = true,
        Id = JobCenter.CurrentTaskNotify,
    })
    
    exports['quantum-ui']:SendUIMessage("Phone", "JobCenterRenderTasks", Tasks)

    Citizen.CreateThread(function()
        local SecondsSpent = 0
        local MinutesSpent = 0
        local HoursSpent = 0 -- for them grinders lmfao

        while JobCenter.CurrentJobTasks ~= nil do
            if SecondsSpent + 1 >= 60 then
                SecondsSpent = 0
                if MinutesSpent + 1 >= 60 then
                    MinutesSpent = 0
                    HoursSpent = HoursSpent + 1
                else
                    MinutesSpent = MinutesSpent + 1
                end
            else
                SecondsSpent = SecondsSpent + 1
            end

            local SecondsString = SecondsSpent < 10 and "0" .. tostring(SecondsSpent) or tostring(SecondsSpent)
            local MinutesString = MinutesSpent < 10 and "0" .. tostring(MinutesSpent) or tostring(MinutesSpent)
            local HoursString = HoursSpent < 10 and "0" .. tostring(HoursSpent) or tostring(HoursSpent)

            exports['quantum-ui']:SendUIMessage("Phone", "JobCenterUpdateTimer", {
                Hours = HoursString,
                Minutes = MinutesString,
                Seconds = SecondsString,
            })

            Citizen.Wait(1000)
        end
    end)
end)

RegisterNetEvent('quantum-phone/client/jobcenter/accept-job-offer', function()
    local HasJob = CallbackModule.SendCallback("quantum-phone/server/jobcenter/start-job-offer", JobCenter.CurrentJob)
    if not HasJob then
        JobCenter.HasJobOffer = false
    else
        JobCenter.IsSearching = false
    end
end)

RegisterNetEvent('quantum-phone/client/jobcenter/reject-job-offer', function()
    JobCenter.HasJobOffer = false
end)

RegisterNetEvent('quantum-phone/client/jobcenter/job-tasks-done', function()
    JobCenter.CurrentJobTasks = nil
    JobCenter.CurrentTaskNotify = nil
end)

RegisterNetEvent('quantum-phone/client/jobcenter/quit-task', function()
    TriggerEvent('quantum-phone/client/hide-notification', JobCenter.CurrentTaskNotify)
    TriggerEvent('quantum-phone/client/jobcenter/job-tasks-done', JobCenter.CurrentJob, JobCenter.CurrentGroup)

    exports['quantum-ui']:SendUIMessage("Phone", "SetJobCenterAppPage", {
        Jobs = false,
        Groups = false,
        Tasks = false,
        GroupMembers = true,
    })
    JobCenter.CurrentJobTasks = nil
    JobCenter.CurrentTaskNotify = nil
end)

RegisterNetEvent('quantum-phone/client/jobcenter/check-for-jobs', function(IsSearching, IsLeader)
    exports['quantum-ui']:SendUIMessage("Phone", "SetJobCenterSearchJobs", IsSearching)
    JobCenter.IsSearching = IsSearching

    if IsLeader and JobCenter.IsSearching then
        Citizen.CreateThread(function()
            JobCenter.HasJobOffer = false
            while JobCenter.CurrentJob ~= nil and JobCenter.IsSearching do
                local WaitTime = math.random(2000, 4000) -- math.random(15000, 120000)
                Citizen.Wait(WaitTime)
                if JobCenter.Jobs and JobCenter.CurrentJob and JobCenter.Jobs[JobCenter.CurrentJob] and JobCenter.Jobs[JobCenter.CurrentJob].IsAvailable and (JobCenter.IsSearching and not JobCenter.HasJobOffer) then
                    JobCenter.HasJobOffer = true
                    if JobCenter.CurrentGroup == nil then return end
                    if exports['quantum-inventory']:HasEnoughOfItem('phone', 1) then
                        exports['quantum-ui']:SendUIMessage('Phone', 'Notification', {
                            Title = "JOB OFFER",
                            Message = JobCenter.Jobs[JobCenter.CurrentJob].Label,
                            Icon = "fas fa-people-carry",
                            IconBgColor = "#a3c8e5",
                            IconColor = "white",
                            Sticky = true,
                            Buttons = {
                                {
                                    Icon = "fas fa-times-circle",
                                    Event = "quantum-phone/client/jobcenter/reject-job-offer",
                                    Tooltip = "Reject",
                                    Color = "#f2a365",
                                    CloseOnClick = true,
                                },
                                {
                                    Icon = "fas fa-check-circle",
                                    Event = "quantum-phone/client/jobcenter/accept-job-offer",
                                    Tooltip = "Accept",
                                    Color = "#2ecc71",
                                    CloseOnClick = true,
                                },
                            },
                        })
                    end
                end
            end
        end)
    end
end)

-- NUI Callbacks
RegisterNUICallback("JobCenter/LocateJob", function(Data, Cb)
    if JobCenter.Jobs[Data.Job] ~= nil then
        SetNewWaypoint(JobCenter.Jobs[Data.Job].Location.x, JobCenter.Jobs[Data.Job].Location.y)
        exports['quantum-ui']:Notify("jobcenter-waypoint", "Waypoint set!")
    end
    Cb('ok')
end)

RegisterNUICallback("JobCenter/CheckOut", function(Data, Cb)
    JobCenter.CurrentJob = nil
    JobCenter.CurrentGroup = nil
    JobCenter.IsSearching = false

    exports['quantum-ui']:SendUIMessage("Phone", "SetJobCenterAppPage", {
        Jobs = true,
        Groups = false,
        Tasks = false,
        GroupMembers = false,
    })

    Cb('Ok')
end)

RegisterNUICallback("JobCenter/CreateGroup", function(Data, Cb)
    Citizen.Wait(math.random(1000, 2500))

    local Created = CallbackModule.SendCallback("quantum-phone/server/jobcenter/create-group", JobCenter.CurrentJob)
    if not Created then return Cb(false) end

    JobCenter.CurrentGroup = PlayerModule.GetPlayerData().CitizenId

    exports['quantum-ui']:SendUIMessage("Phone", "SetJobCenterAppPage", {
        Jobs = false,
        Groups = false,
        Tasks = false,
        GroupMembers = true,
    })

    Cb(true)
end)

RegisterNUICallback("JobCenter/ReadyGroup", function(Data, Cb)
    TriggerServerEvent('quantum-phone/server/jobcenter/set-ready', JobCenter.CurrentJob)
    Cb('Ok')
end)

RegisterNUICallback("JobCenter/RequestJoin", function(Data, Cb)
    local IsAccepted = CallbackModule.SendCallback("quantum-phone/server/jobcenter/request-join", JobCenter.CurrentJob, Data)
    Cb('Ok')
    if IsAccepted then
        exports['quantum-ui']:SendUIMessage("Phone", "SetJobCenterAppPage", {
            Jobs = false,
            Groups = false,
            Tasks = false,
            GroupMembers = true,
        })
        JobCenter.CurrentGroup = Data.Leader
        TriggerServerEvent('quantum-phone/server/jobcenter/join-group', JobCenter.CurrentJob, Data.Leader)
    end
end)

RegisterNUICallback("JobCenter/DisbandGroup", function(Data, Cb)
    exports['quantum-ui']:SendUIMessage("Phone", "SetJobCenterAppPage", {
        Jobs = false,
        Groups = true,
        Tasks = false,
        GroupMembers = false,
    })

    JobCenter.IsSearching = false
    
    TriggerServerEvent('quantum-phone/server/jobcenter/leave-group', JobCenter.CurrentJob)
    Cb('Ok')
end)

RegisterNUICallback("JobCenter/CancelTasks", function(Data, Cb)
    TriggerServerEvent('quantum-phone/server/jobcenter/cancel-task', JobCenter.CurrentJob)
    if JobCenter.CurrentGroup == PlayerModule.GetPlayerData().CitizenId then
        Citizen.SetTimeout(1000, function()
            TriggerServerEvent('quantum-phone/server/jobcenter/set-ready', JobCenter.CurrentJob, true)
        end)
    end
end)

exports('GetCurrentJob', function()
    local Retval = false
    if JobCenter.CurrentJob ~= nil then
        Retval = JobCenter.CurrentJob
    end
    return Retval
end)

exports("IsJobCenterTaskActive", function(Job, TaskId)
    if JobCenter.CurrentJobTasks == nil then return false end
    if JobCenter.CurrentJob ~= Job then return false end

    local Finished = 0

    for i = 1, #JobCenter.CurrentJobTasks.Tasks, 1 do
        local Task = JobCenter.CurrentJobTasks.Tasks[i]
        if Task.Finished then
            Finished = Finished + 1
        end
    end

    return (Finished + 1) == TaskId -- +1 to get the task after the last finished task
end)

exports("GetPaycheckAmount", function()
    local Result = CallbackModule.SendCallback("quantum-phone/server/check-paycheck-amount")
    return Result
end)

--[[
    RegisterNetEvent('quantum-phone/client/jobcenter/job-tasks-done', function(Job, Leader)
        if Job ~= 'job' then return end

        if Leader == PlayerModule.GetPlayerData().CitizenId then
            -- Leader-Only code
        else
            -- Other Code
        end

        -- All code
    end)

    RegisterNetEvent('quantum-phone/client/jobcenter/on-job-start', function(Job, Leader)
        if Job ~= 'job' then return end

        if Leader == PlayerModule.GetPlayerData().CitizenId then
            -- Leader-Only code
        else
            -- Other Code
        end

        -- All code
    end)

    RegisterNetEvent('quantum-phone/client/jobcenter/on-task-done', function(Job, FinishedTaskId, NextTaskId, Leader)
        if Job ~= 'job' then return end

        if Leader == PlayerModule.GetPlayerData().CitizenId then
            -- Leader-Only code
        else
            -- Other Code
        end

        -- All code
    end)

    This gets triggered to the job members if the LEADER disconnects
    RegisterNetEvent('quantum-phone/client/jobcenter/on-crash', function(Job)
        -- Code
    end)

    TriggerEvent('quantum-phone/client/jobcenter/request-task-success', TaskId, Finished)
    TriggerEvent('quantum-phone/client/jobcenter/request-task-update', TaskId, ExtraDone)
    
    exports['quantum-phone']:IsJobCenterTaskActive('job', TaskId)
]]