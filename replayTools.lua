local sim = ac.getSim()
local app_folder = ac.getFolder(ac.FolderID.ACApps) .. '/lua/replayTools/'
local resultsPage = nil
local penaltyTable = {}
local resultsFile = JSON.parse(ac.load("resultsFile"))
local page = 0
local selectedDriver = ""
local resultsFilepath = ""
local replaySyncTime = 0
local settings = ac.storage{
  URL = "http://162.19.220.231:8772",
  serverNumber = "0"
}
local URL = settings.URL
local serverNumber = settings.serverNumber
local collisionTable = {{car1 = 0, car2 = 0, speed = 0, timestamp = sim.currentSessionTime}}
local penaltyLinkEnabled = false
local penaltyLinkTimeout = 0
local softTime = 0

local replaystream = ac.ReplayStream({
  ac.StructItem.key("replayLinkSync"),
  time = ac.StructItem.int32()
}, function() end)

function script.windowMain(dt)

  ui.tabBar("Replay Tools", function()
   ui.tabItem("ACSM Link", function()
      if ui.button("Autofill") then
        searchQuery = "+" .. ac.getTrackID()
      end
      local URL, URLChanged, URLConfirm = ui.inputText("Server URL", URL, ui.InputTextFlags.RetainSelection) 
      if URLConfirm then
        settings.URL = URL
      end

      local serverNumber, serverNumberChanged, serverNumberConfirm = ui.inputText("Server Number", serverNumber, ui.InputTextFlags.RetainSelection) 
      if serverNumberConfirm then
        settings.serverNumber = serverNumber
      end
      local searchQuery, searchChanged, searchConfirm = ui.inputText("Search for results", searchQuery,
        ui.InputTextFlags.RetainSelection)
      local searchConfirmButton = ui.button("Search Results")

      --ac.debug("c", ui.combo("Session Type", "Session Type", ui.ComboFlags.None, function() ui.menuItem()end))


      if resultsPage ~= nil then
        ui.childWindow("Results List", vec2(400, 300), function()
          if resultsPage["results"] ~= nil then
            for index, v in ipairs(resultsPage["results"]) do
              if ui.menuItem(isoTimetoReadable(v["date"]) .. " | " .. (v["session_type"]) .. " at " .. v["track"], selectedResults == index) then
                selectedResults = index
                resultsFilepath = v["results_json_url"]
              end
            end
          else
            ui.text("No Results Found or Too Many Requests!")
          end
        end) --end Results List Window

        ui.combo("page", page, ui.ComboFlags.None, function()
          for index = 0, resultsPage["num_pages"], 1 do
            if ui.selectable(index) then
              page = index
            end
          end
        end)
        if ui.button("Load Results File") then
          loadResults(resultsFilepath)
        end
      end --Results Availiable end
      if ui.checkbox("Connect To Penalties Log", penaltyLinkEnabled) then
        penaltyLinkEnabled = not penaltyLinkEnabled
      end


      if searchConfirm or searchConfirmButton then
        loadResultsList(searchQuery, page, serverNumber)
        ac.log(searchQuery)
      end
    end) --End results File Tab

    ui.tabItem("Replay Data", function()
      ui.tabBar("ReplayControls", function()
        ui.tabItem("Events", function()
          --ac.debug("frame", sim.replayCurrentFrame)
          --ac.debug("total", sim.replayFrames)
          ui.columns(2, true, "columnlayout")
          ui.combo("Driver", selectedDriver, function()
            if ui.selectable("None") then
              selectedDriver = ""
            end
            for index, value in ipairs(resultsFile["Cars"]) do
              if ui.selectable(value["Driver"]["Name"]) then
                selectedDriver = value["Driver"]["Name"]
              end
            end
          end)
          ui.childWindow("Event Table", vec2(500, 500), function()
            if resultsFile ~= nil then
              local replayStartTime = (resultsFile["Laps"][1]["Timestamp"] - (resultsFile["Laps"][1]["LapTime"] / 1000)) -
                  resultsFile["SessionConfig"]["wait_time"]
              --ac.log(replayStartTime)
              ac.debug("Events", resultsFile["Laps"])
              for index, value in ipairs(resultsFile["Events"]) do
                if (value["Driver"]["Name"] ~= resultsFile["Events"][math.min(index + 1, #resultsFile["Events"])]["OtherDriver"]["Name"]) and ((selectedDriver == "") or (value["Driver"]["Name"] == selectedDriver or value["OtherDriver"]["Name"] == selectedDriver)) then
                  if ui.button(ac.lapTimeToString(((value["Timestamp"] - replayStartTime - 3) - ((value["Timestamp"] - replayStartTime - 3) * 0.0013)) * 1000) .. " " .. value["Driver"]["Name"] .. " " .. ((value["Type"] == "COLLISION_WITH_CAR" and "with") or (value["Type"] == "COLLISION_WITH_ENV" and "With Environment. lmao.")) .. " " .. value["OtherDriver"]["Name"] .. " at " .. math.round(value["ImpactSpeed"],2) .. " km/h") then
                    --ac.log(((value["Timestamp"]-replayStartTime-1)-((value["Timestamp"]-replayStartTime-1)*0.004)*1000)/sim.replayFrameMs)
                    ac.setReplayPosition(
                      (((value["Timestamp"] - replayStartTime - 3) - ((value["Timestamp"] - replayStartTime - 3) * 0.0013)) * 1000) /
                      sim.replayFrameMs, 1)
                    ac.focusCar(math.max(ac.getCarByDriverName(value["Driver"]["Name"]),
                      (ac.getCarByDriverName(value["OtherDriver"]["Name"]))))
                  end
                end
              end
            end
          end)
          ui.nextColumn()

          ui.columns(1, true, "columnlayout")
        end) --events tab
      end)   --Replay Controls Tab Bar
    end)     --Replay Data Tab

    ui.tabItem("PenaltyLink", ui.TabItemFlags.None, function()
      --ui.combo("sortPenalties", sortTable, ui.ComboFlags.GoUp, function ()
      penaltySort = ui.inputText("Search", penaltySort)

      if penaltySort == nil then
        sortCheck = false
      else
        sortCheck = true
      end
      for index, value in ipairs(penaltyTable) do
        if (sortCheck and (string.match(JSON.stringify(value), penaltySort))) or (not sortCheck)then
          if ui.button(os.parseDate(value["time"], '%Y-%m-%dT%H:%M:%S') - softTime .. " | " .. value["driver_name"] .. " " .. value["name"] .. " " .. value["context"] .. " | " .. value["type"]) then
            ac.focusCar(ac.getCarByDriverName(value["driver_name"]))
            ac.setReplayPosition(
            sim.replayCurrentFrame +
            ((((os.parseDate(value["time"], '%Y-%m-%dT%H:%M:%S') - softTime) - 10) * 1000)) / sim.replayFrameMs, 1)
          end
        end
      end
    end)
  end)
--ac.debug("time", replaystream.time)
--ac.debug("sestime", sim.currentSessionTime)
end



function script.update(dt)
  ac.debug("a", replaystream.time)
  
  softTime = replaystream.time

  if not sim.isReplayOnlyMode then
    
    replaystream.time = sim.systemTime
    ac.debug(" ", replaystream.time)
  end

  
      if penaltyLinkEnabled and penaltyLinkTimeout < 0 then
        linkToPenaltiesLog(serverNumber)
        ac.log("request")
        penaltyLinkTimeout = 5
      end
      penaltyLinkTimeout = penaltyLinkTimeout - dt
end
--[[ac.onCarCollision(-1, function (carIndex)
  local car = ac.getCar(carIndex)
  --if not(collisionTable[#collisionTable]["car1"] == carIndex and sim.currentSessionTime-collisionTable[#collisionTable]["timestamp"]<1000) then
  table.insert(collisionTable, {car1 = carIndex, car2 = car.collidedWith, speed = car.collisionDepth, timestamp = sim.currentSessionTime}) 
  ac.log(collisionTable[#collisionTable])
  ac.focusCar(carIndex)
  --end
  ac.writeReplayBlob("replayLink", JSON.stringify(collisionTable))
end)]]


ac.onReplay(function(event)
  if event == "start" then
    --[[if replaystream.time ~= 0 then
    replaySyncTime = replaystream.time      
    else
    ac.setReplayPosition(5000/sim.replayFrameMs,1)
    replaySyncTime = replaystream.time 
    end]]
    replaySyncFrame = sim.replayCurrentFrame
    ac.log("replay start time init to " .. ac.lapTimeToString(replaySyncTime,true ) .. replaySyncFrame)
  end
  if event == "jump" then
    ac.log("jumped to:" .. os.dateGlobal("%H:%M:%S", replaystream.time) .. " sync: " .. ac.lapTimeToString(replaySyncTime,true))
  end

  ac.log(event)
end)

function loadResultsList(input, pageNumber, server)

  local query = string.urlEncode(tostring(input), true)
if input == nil then
  query = "" 
end
  local sort = "date"

  web.get(settings.URL .. "/api/results/list.json?q=" .. query .. "&sort=" .. sort .. "&page=" .. pageNumber .. "&server=" .. server, function(err, response)
    ac.debug("error", error)
    resultsPage = JSON.parse(response.body)
  end)
  ac.log(settings.URL .. "/api/results/list.json?q=" .. query .. "&sort=" .. sort .. "&page=" .. pageNumber .. "&server=" .. server)
end

function linkToPenaltiesLog(server)
  web.get(settings.URL .. "/race-control/penalties-log.json?server=" .. server, function (err, response)
    ac.debug("error", error)
    penaltyTable = JSON.parse(response.body)
  end)

end

function loadResults(file)
  --file = io.load(app_folder .. "/2026_1_3_13_15_RACE.json", "error")
  web.get(settings.URL .. file, function (err, response)
    resultsFile = JSON.parse(response.body)
    ac.store("resultsFile", response.body)
    ac.log(settings.URL .. file)
    ac.debug("file",resultsFile)
  end)

  
end

function script.windowSettings()
  ui.button("true")
end

function isoTimetoReadable(time)
return os.date('%Y-%m-%d %H:%M:%S',(os.parseDate(time,'%Y-%m-%dT%H:%M:%S')))
--return year .. "-" .. month .. "-" .. day .. " " .. hour .. ":" .. minute
end

