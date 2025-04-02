-- Loading EmmyLua first ensures that any type annotations for hammerspoon
-- itself and all the spoons are available
hs.loadSpoon("EmmyLua")

local currentHotkeys = nil

local braveFilter = hs.window.filter.new("Brave Browser")

braveFilter:subscribe(hs.window.filter.windowFocused, function()
  local hotkey = hs.hotkey.bind({ "cmd", "shift" }, "C", function()
    local script = [[
      function run() {
        const brave = Application('Brave Browser');
        if (brave.windows.length > 0) {
          const win = brave.windows[0];
          const activeTab = win.activeTab;
          if (activeTab) {
            return activeTab.url();
          }
        }
        return null;
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
  currentHotkeys["braveCopyUrl"] = hotkey
end)

-- Unbind the hotkey when leaving Orion
braveFilter:subscribe(hs.window.filter.windowUnfocused, function()
  if currentHotkeys and currentHotkeys["braveCopyUrl"] then
    currentHotkeys["braveCopyUrl"]:delete()
    currentHotkeys["braveCopyUrl"] = nil
  end
end)
