local sim = ac.getSim()
local app_folder = ac.getFolder(ac.FolderID.ACApps) .. '/lua/replayTools/'
local resultsPage = nil
local resultsFile = JSON.parse(ac.load("resultsFile"))
local page = 0
local resultsFilepath = ""
local server = 0
local settings = ac.storage{
  URL = "http://162.19.220.231:8772"
}


function script.windowMain(dt)

  ui.tabBar("Replay Tools", function()


    ui.tabItem("Replay Data", function()
      ui.tabBar("ReplayControls", function()
        ui.tabItem("Events", function()
          ac.debug("frame", sim.replayCurrentFrame)
          ac.debug("total", sim.replayFrames)
          ui.columns(2, true, "columnlayout")
          ui.childWindow("Event Table", vec2(500, 500), function()
            if resultsFile ~= nil then
              local replayStartTime = (resultsFile["Laps"][1]["Timestamp"] - (resultsFile["Laps"][1]["LapTime"] / 1000)) -
              resultsFile["SessionConfig"]["wait_time"]
              --ac.log(replayStartTime)
              ac.debug("Events", resultsFile["Laps"])
              for index, value in ipairs(resultsFile["Events"]) do
                if value["Driver"]["Name"] ~= resultsFile["Events"][math.min(index + 1, #resultsFile["Events"])]["OtherDriver"]["Name"] then
                  if ui.button(ac.lapTimeToString(((value["Timestamp"] - replayStartTime - 1) - ((value["Timestamp"] - replayStartTime - 1) * 0.0013)) * 1000) .. " " .. value["Driver"]["Name"] .. " " .. ((value["Type"] == "COLLISION_WITH_CAR" and "with") or (value["Type"] == "COLLISION_WITH_ENV" and "With Environment. lmao.")) .. " " .. value["OtherDriver"]["Name"]) then
                    --ac.log(((value["Timestamp"]-replayStartTime-1)-((value["Timestamp"]-replayStartTime-1)*0.004)*1000)/sim.replayFrameMs)
                    ac.setReplayPosition(
                    (((value["Timestamp"] - replayStartTime - 2) - ((value["Timestamp"] - replayStartTime - 2) * 0.0013)) * 1000) /
                    sim.replayFrameMs, 1)
                    ac.focusCar(math.max(ac.getCarByDriverName(value["Driver"]["Name"]),
                      (ac.getCarByDriverName(value["OtherDriver"]["Name"]))))
                  end
                end
              end
            end
          end)
          ui.nextColumn()
          for index, value in ipairs(resultsFile["Events"]) do
            
          end
          ui.columns(1, true, "columnlayout")
        end) --events tab
      end)   --Replay Controls Tab Bar
    end)     --Replay Data Tab



    ui.tabItem("Results File", function()
      if ui.button("Autofill") then
        searchQuery = "+" .. ac.getTrackID()
      end

      local searchQuery, searchChanged, searchConfirm = ui.inputText("Search for results", searchQuery,
        ui.InputTextFlags.RetainSelection)
      local searchConfirmButton = ui.button("Search Results")

      --ac.debug("c", ui.combo("Session Type", "Session Type", ui.ComboFlags.None, function() ui.menuItem()end))

      ac.debug("results", resultsPage)
      ac.debug("selected", searchQuery)
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

      if searchConfirm or searchConfirmButton then
        loadResultsList(searchQuery, page)
        ac.log(searchQuery)
      end
    end) --End results File Tab
  end)
end

function loadResultsList(input, pageNumber)

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

