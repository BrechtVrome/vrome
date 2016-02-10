class window.InsertMode
  [storedValues, nextEditId, elem, caretPosition, value, lineStart,
    prevLineStart, nextLineStart, next2LineStart] = [[], 0]

  storeLastValue = ->
    storedValues.push value if value isnt storedValues[storedValues.length - 1]

  currentElement = =>
    elem = document.activeElement
    try
      if elem
        caretPosition = elem.selectionEnd
        value = elem.value or elem.innerText
        lineStart = caretPositionOfCurrentLine()
        prevLineStart = caretPositionOfAboveLine()
        nextLineStart = caretPositionOfNextLine()
        next2LineStart = caretPositionOfNext2Line()
        do storeLastValue
    catch err
      Debug err
    elem

  caretPositionOfCurrentLine = ->
    value[0...caretPosition].lastIndexOf('\n') + 1

  caretPositionOfAboveLine = ->
    value[0..caretPositionOfCurrentLine() - 2].lastIndexOf('\n') + 1

  caretPositionOfNextLine = ->
    position = value[caretPosition..-1].indexOf('\n')
    return value.length + 1 if position is -1
    caretPosition + position + 1

  caretPositionOfNext2Line = ->
    position = value[nextLineStart..-1].indexOf('\n')
    return value.length + 1 if position is -1
    nextLineStart + position + 1

  @blurFocus: ->
    $(currentElement()).blur()

  getFocusableElements = (inFullPage) ->
    $('input[type="text"],input[type="password"],input[type="search"],textarea,input:not([type]),[contenteditable]').
      filter (_, e) -> isElementVisible $(e), inFullPage

  @focusFirstTextInput: ->
    do Unfocus.didReceiveInput
    # first try to focus a currently visible element
    elems = getFocusableElements false
    # if that fails, focus a visible element anywhere on the page
    elems = getFocusableElements true if elems.length is 0
    $(elems[times() - 1]).focus().select().get(0)?.scrollIntoViewIfNeeded()
  desc @focusFirstTextInput, 'Focus the {count} input field'

  @restoreLastValue: ->
    elem.value = storedValues.pop() ? value
  desc @restoreLastValue, 'Undo last change'

  # Move <(C|M)-(a|e)>
  @moveToFirstOrSelectAll: ->
    currentElement()?.setSelectionRange 0, (if caretPosition is 0 then value.length else 0)
  desc @moveToFirstOrSelectAll, 'Move to first word or select all'

  @moveToEnd: ->
    elem = currentElement()
    elem?.setSelectionRange value.length, value.length
  desc @moveToEnd, 'Move to end'

  @moveToBeginCurrentLine: ->
    elem = currentElement()
    elem?.setSelectionRange lineStart, lineStart
  desc @moveToBeginCurrentLine, 'Move to the beginning of the line'

  @moveToEndCurrentLine: ->
    elem = currentElement()
    elem?.setSelectionRange nextLineStart-1, nextLineStart-1
  desc @moveToEndCurrentLine, 'Move forwards to end of the line'

  @deleteToBeginCurrentLine: ->
    elem = currentElement()
    elem.value = value[0...lineStart] + value[caretPosition..-1]
    elem?.setSelectionRange lineStart, lineStart
  desc @deleteToBeginCurrentLine, 'Delete to the beginning of the line'

  @deleteToEndCurrentLine: ->
    elem = currentElement()
    elem.value = value[0...caretPosition] + value[nextLineStart-1..-1]
    elem?.setSelectionRange caretPosition, caretPosition
  desc @deleteToEndCurrentLine, 'Delete forwards to end of the line'

  @deleteForwardChar: ->
    elem = currentElement()
    elem.value = value.substr(0, caretPosition) + value.substr(caretPosition + 1)
    elem?.setSelectionRange caretPosition, caretPosition
  desc @deleteForwardChar, 'Delete forward char. <M-(yuio)> for delete back/forward a word/char'

  @deleteBackwardChar: ->
    elem = currentElement()
    elem.value = value.substr(0, caretPosition - 1) + value.substr(caretPosition)
    elem?.setSelectionRange(caretPosition - 1, caretPosition - 1)
  desc @deleteBackwardChar, 'Delete backward char. <M-(yuio)> for delete back/forward a word/char'

  @deleteBackwardWord: ->
    elem = currentElement()
    elem.value = value.substr(0, caretPosition).replace(/[^\s\n.,]*?.\s*$/, '') + value.substr(caretPosition)
    position = elem.value.length - (value.length - caretPosition)
    elem?.setSelectionRange position, position
  desc @deleteBackwardWord, 'Delete backward word. <M-(yuio)> for delete back/forward a word/char'

  @deleteForwardWord: ->
    elem = currentElement()
    elem.value = value.substr(0, caretPosition) + value.substr(caretPosition).replace(/^\s*.[^\s\n.,]*/, '')
    elem?.setSelectionRange caretPosition, caretPosition
  desc @deleteForwardWord, 'Delete forward word. <M-(yuio)> for delete back/forward a word/char'

  @moveBackwardWord: ->
    elem = currentElement()
    str = value.substr(0, caretPosition).replace(/[^\s\n.,]*?.\s*$/, '')
    elem?.setSelectionRange str.length, str.length
  desc @moveBackwardWord, 'Move backward word. <M-(hjkl)> for move back/forward a word/char'

  @moveForwardWord: ->
    elem = currentElement()
    position = value.length - value.substr(caretPosition).replace(/^\s*.[^\s\n.,]*/, '').length
    elem?.setSelectionRange position, position
  desc @moveForwardWord, 'Move forward word. <M-(hjkl)> for move back/forward a word/char'

  @moveBackwardChar: ->
    elem = currentElement()
    elem.setSelectionRange caretPosition - 1, caretPosition - 1
  desc @moveBackwardChar, 'Move backward char. <M-(hjkl)> for move back/forward a word/char'

  @moveForwardChar: ->
    elem = currentElement()
    elem.setSelectionRange caretPosition + 1, caretPosition + 1
  desc @moveForwardChar, 'Move forward char. <M-(hjkl)> for move back/forward a word/char'

  @moveForwardLine: ->
    elem = currentElement()
    start = Math.min(nextLineStart + (caretPosition - lineStart), next2LineStart - 1)
    elem.setSelectionRange start, start
  desc @moveForwardLine, 'Move forward line. <M-(nm)> for move back/forward a line'

  @moveBackwardLine: ->
    elem = currentElement()
    start = Math.min(prevLineStart + (caretPosition - lineStart), lineStart - 1)
    elem.setSelectionRange start, start
  desc @moveBackwardLine, 'Move backward line. <M-(nm)> for move back/forward a line'

  # The next three functions handle 'contenteditable' elements specially;
  # they do not have a 'value' property and their selection should be
  # taken in a different way
  # Example could be GMail's reply text field
  @externalEditorCallBack: (msg) ->
    element = $("[vrome_edit_id='#{msg.editId}']").removeAttr('vrome_edit_id')[0]
    if element
      if element.value?
        element.value = msg.value
      else
        element.innerText = msg.value

  getElementText = (element) ->
    element.value ? element.innerText

  getElementSelection = (element) ->
    if element.value?
      element.value.substr 0, elem.selectionStart
    else
      range = window.getSelection().getRangeAt(0)
      preCaretRange = range.cloneRange()
      preCaretRange.selectNodeContents element
      preCaretRange.setEnd(range.endContainer, range.endOffset)
      contents = preCaretRange.cloneContents()
      div = document.createElement 'div'
      div.appendChild contents
      div.innerHTML.replace /<br>/g, '\n'

  @externalEditor: ->
    elem   = currentElement()
    editId = String nextEditId++
    text   = getElementSelection elem
    line   = 1 + (text.match(/\n/g) or []).length
    col    = 1 + text.match(/\n?(.*?)$/)[1].length
    elem.setAttribute 'vrome_edit_id', editId

    Post { action: 'Editor.open', callbackAction: 'InsertMode.externalEditorCallBack', data: getElementText(elem), editId, line, col }
  desc @externalEditor, 'Launch the external editor'
