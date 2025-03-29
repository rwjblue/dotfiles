-- Loading EmmyLua first ensures that any type annotations for hammerspoon
-- itself and all the spoons are available
hs.loadSpoon("EmmyLua")

local currentHotkeys = nil

local orionFilter = hs.window.filter.new("Orion")

orionFilter:subscribe(hs.window.filter.windowFocused, function()
  local hotkey = hs.hotkey.bind({ "cmd", "shift" }, "C", function()
    local script = [[
      function run() {
        const orion = Application('Orion');
        // TODO: fix this, it's not quite right (we should only operate on the foremost window not windows[0])
        if (orion.windows.length > 0 && orion.windows[0].currentTab) {
          return orion.windows[0].currentTab.url();
        } else {
          return null;
        }
      }
    ]]

    local ok, result = hs.osascript.javascript(script)
    if ok and result then
      hs.pasteboard.setContents(result)
    else
      hs.alert.show("Failed to copy URL: " .. (result or "Unknown error"))
      print("JavaScript error:", result)
    end
  end)

  currentHotkeys = currentHotkeys or {}
  currentHotkeys["orionCopyUrl"] = hotkey
end)

-- Unbind the hotkey when leaving Orion
orionFilter:subscribe(hs.window.filter.windowUnfocused, function()
  if currentHotkeys and currentHotkeys["orionCopyUrl"] then
    currentHotkeys["orionCopyUrl"]:delete()
    currentHotkeys["orionCopyUrl"] = nil
  end
end)
