local sim = ac.getSim()
local app_folder = ac.getFolder(ac.FolderID.ACApps) .. '/lua/replayTools/'
local resultsPage = nil
local page = 0
local settings = ac.storage{
  URL = ""
}


function script.windowMain(dt)

  ui.tabBar("Replay Tools", function()
    ui.tabItem("Replay Data", function ()
      
    end)
    ui.tabItem("Results File", function()
      local searchQuery, searchChanged, searchConfirm = ui.inputText("Search for results", searchQuery,
        ui.InputTextFlags.RetainSelection)
      local searchConfirmButton = ui.button("Search Results")
      --ac.debug("c", ui.combo("Session Type", "Session Type", ui.ComboFlags.None, function() ui.menuItem()end))



      ac.debug("results", resultsPage)
      ac.debug("selected", searchQuery)
      if resultsPage ~= nil then
        ui.childWindow("Results List", vec2(300, 300), function()
          if resultsPage["results"] ~= nil then
            for index, value in ipairs(resultsPage["results"]) do
              if ui.menuItem(value["track"], selectedResults == index) then
                selectedResults = index
              end
            end
          else
            ui.text("No Results Found or Too Many Requests!")
          end


        end) --end Results List Window
        
        ui.combo("page", page, ui.ComboFlags.None, function() 
          for index=0, resultsPage["num_pages"],1  do
            if ui.selectable(index) then
              page = index
            end 
          end

         end)

      end    --Results Availiable end

      if searchConfirm or searchConfirmButton then
        loadResultsList(searchQuery, page)
        ac.log(searchQuery)
      end

      
    end)--End results File Tab
  end)

end

function loadResultsList(input, pageNumber)
  local serverURL = "http://162.19.220.231:8772"
  local query = string.urlEncode(tostring(input), true)
if input == nil then
  query = "" 
end
  local sort = "date"

  web.get(serverURL .. "/api/results/list.json?q=" .. query .. "&sort=" .. sort .. "&page=" .. pageNumber, function(err, response)
    ac.debug("error", error)
    resultsPage = JSON.parse(response.body)
  end)
  ac.log(serverURL .. "/api/results/list.json?q=" .. query .. "&sort=" .. sort .. "&page=" .. page)
end

function loadResults()
  file = io.load(app_folder .. "/2026_1_3_13_15_RACE.json", "error")
  resultsFile = JSON.parse(file)
end

function script.windowSettings()
  ui.button("true")
end
