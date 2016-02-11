class window.Buffer
  getMatchedTabs = (tabs, keyword) ->
    if /^\d+$/.test keyword
      [tabs[Number(keyword) - 1]]
    else
      regexp = new RegExp keyword, 'i'
      tabs.filter (tab) -> regexp.test(tab.url) or regexp.test tab.title


  @gotoFirstMatch: (msg) ->
    chrome.tabs.query windowId: msg.tab.windowId, (tabs) ->
      msg.tab = getMatchedTabs(tabs, msg.keyword)[0]
      Tab.select msg

  @deleteMatch: (msg) ->
    chrome.tabs.query windowId: msg.tab.windowId, (tabs) ->
      Tab.close tab for tab in getMatchedTabs tabs, msg.keyword
      return

  @deleteNotMatch: (msg) ->
    chrome.tabs.query windowId: msg.tab.windowId, (tabs) ->
      matchedTabs = getMatchedTabs tabs, msg.keyword
      Tab.close tab for tab in tabs when tab not in matchedTabs
      return
