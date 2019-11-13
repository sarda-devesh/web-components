import {findDOMNode} from "react-dom"
import {Component, createElement, useContext, createRef, forwardRef} from "react"
import h from "../hyper"
import T from "prop-types"
import {NoteLayoutContext} from './layout'
import {NoteEditorContext} from './editor'
import {hasSpan} from './utils'
import {ForeignObject} from '../util'
import {NoteShape} from './types'

NoteBody = (props)->
  {note} = props
  {setEditingNote, editingNote} = useContext(NoteEditorContext)
  {noteComponent} = useContext(NoteLayoutContext)
  isEditing = editingNote == note

  onClick = ->
    setEditingNote(note)

  visibility = if isEditing then 'hidden' else 'inherit'
  h noteComponent, {visibility, note, onClick}

NotePositioner = forwardRef (props, ref)->
  {offsetY, noteHeight, children} = props
  {width, paddingLeft} = useContext(NoteLayoutContext)
  noteHeight ?= 0
  outerPad = 5

  h ForeignObject, {
    width: width-paddingLeft+2*outerPad
    x: paddingLeft-outerPad
    y: offsetY-noteHeight/2-outerPad
    height: 1
    style: {overflowY: 'visible'}
  }, [
    h 'div.note-inner', {
      ref,
      style: {margin: '5px', position: 'relative'}
    }, children
  ]

class NoteSpan extends Component
  render: ->
    {height, transform} = @props
    if height > 5
      el = h 'line', {
       x1: 0, x2: 0, y1: 2.5,
       y2: height-2.5
      }
    else
      el = h 'circle', {r: 2}
    h 'g', {transform}, el

findIndex = (note)->
  {notes} = useContext(NoteLayoutContext)
  notes.indexOf(note)

NoteConnector = (props)->
  {note, node, index} = props
  # Try to avoid scanning for index if we can
  index ?= findIndex(note)
  {scale, nodes, columnIndex, generatePath} = useContext(NoteLayoutContext)

  startHeight = scale(note.height)
  height = 0
  if hasSpan(note)
    height = Math.abs(scale(note.top_height)-startHeight)

  node ?= nodes[index]
  offsetX = (columnIndex[index] or 0)*5

  pos = 0
  if node?
    pos = node.centerPos or node.idealPos

  h [
    h NoteSpan, {
      transform: "translate(#{offsetX} #{pos-height/2})"
      height
    }
    h 'path.link', {
      d: generatePath(node, offsetX)
      transform: "translate(#{offsetX})"
    }
  ]

NoteMain = forwardRef (props, ref)->
  {note, offsetY, noteHeight} = props
  {editingNote} = useContext(NoteEditorContext)
  return null if editingNote == note
  h "g.note", [
    h NoteConnector, {note}
    h NotePositioner, {
      offsetY
      noteHeight
      ref
    }, [
      h NoteBody, {note}
    ]
  ]

class Note extends Component
  @propTypes: {
    editable: T.bool
    note: NoteShape.isRequired
    index: T.number.isRequired
    editHandler: T.func
  }
  @contextType: NoteLayoutContext
  constructor: (props)->
    super props
    @element = createRef()
    @state = {height: null}

  render: ->
    {style, note, index, editHandler, editable} = @props
    {scale, nodes, columnIndex, width, paddingLeft} = @context

    node = nodes[index]
    offsetY = scale(note.height)
    if node?
      offsetY = node.currentPos

    noteHeight = (@state.height or 0)

    h NoteMain, {
      offsetY
      note
      noteHeight
      ref: @element
    }

  componentDidMount: =>
    node = @element.current
    return unless node?
    height = node.offsetHeight
    return unless height?
    return if @state.height == height
    @setState {height}
    @context.registerHeight(@props.index, height)

NotesList = (props)->
  {inEditMode: editable, rest...} = props
  editable ?= false
  {notes} = useContext(NoteLayoutContext)
  h 'g', notes.map (note, index)=>
    h Note, {note, index, editable, rest...}

export {Note, NotesList, NotePositioner, NoteConnector}
