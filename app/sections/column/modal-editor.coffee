{findDOMNode} = require 'react-dom'
{Component, createElement} = require 'react'
{Dialog, Button, Intent, ButtonGroup, Alert} = require '@blueprintjs/core'
{FaciesDescriptionSmall, FaciesContext} = require '../facies-descriptions'
{PickerControl} = require '../settings'
Select = require('react-select').default
require 'react-select/dist/react-select.css'

{grainSizes} = require './grainsize'
h = require 'react-hyperscript'
d3 = require 'd3'
{db, storedProcedure, query} = require '../db'
fmt = d3.format('.1f')

{dirname} = require 'path'
baseDir = dirname require.resolve '..'
sql = (id)-> storedProcedure(id, {baseDir})
{helpers} = require '../../db/backend'

floodingSurfaceOrders = [-1,-2,-3,-4,-5,null,5,4,3,2,1]

class ModalEditor extends Component
  @defaultProps: {onUpdate: ->}
  constructor: (props)->
    super props
    @state = {
      facies: [],
      isAlertOpen: false
    }
  render: ->
    h FaciesContext.Consumer, null, ({surfaces})=>
      @renderMain(surfaces)

  renderMain: (surfaces)=>
    {interval, height, section} = @props
    return null unless interval?
    console.log interval
    {id, top, bottom, facies} = interval
    hgt = fmt(height)

    options = surfaces.map (d)->
      {value: d.id, label: d.note}

    h Dialog, {
      className: 'pt-minimal'
      title: "Section #{section}: #{bottom} - #{top} m"
      isOpen: @props.isOpen
      onClose: @props.closeDialog
      style: {top: '10%'}
    }, [
      h 'div', {className:"pt-dialog-body"}, [
        h 'h3', [
          "ID "
          h 'code', interval.id
        ]
        h FaciesDescriptionSmall, {
          options: {isEditable: true}
          onClick: @updateFacies
          selected: facies
        }
        h 'label.pt-label', [
          'Grainsize'
          h PickerControl, {
            vertical: false,
            isNullable: true,
            states: grainSizes.map (d)->
              {label: d, value: d}
            activeState: interval.grainsize
            onUpdate: (grainsize)=>
              @update {grainsize}
          }
        ]
        h 'label.pt-label', [
          'Flooding surface (negative is regression)'
          h PickerControl, {
            vertical: false,
            isNullable: true,
            states: floodingSurfaceOrders.map (d)->
              lbl = "#{d}"
              lbl = 'None' if not d?
              {label: d, value: d}
            activeState: interval.flooding_surface_order
            onUpdate: (flooding_surface_order)=>
              @update {flooding_surface_order}
          }
        ]
        h 'label.pt-label', [
          'Correlated surface'
          h Select, {
            id: "state-select"
            ref: (ref) => @select = ref
            options
            clearable: true
            searchable: true
            name: "selected-state"
            value: interval.surface
            onChange: (surface)=>
              if surface?
                surface = surface.value
              @update {surface}
          }
        ]
        h 'div', [
          h 'h5', "Interval"
          h 'div.pt-button-group.pt-vertical', [
            h Button, {
              onClick: =>
                return unless @props.addInterval?
                @props.addInterval(height)
            }, "Add interval starting at #{fmt(height)} m"
            h Button, {
              onClick: =>
                @setState {isAlertOpen: true}
              intent: Intent.DANGER}, "Remove interval starting at #{bottom} m"
            h Alert, {
                iconName: "trash"
                intent: Intent.PRIMARY
                isOpen: @state.isAlertOpen
                confirmButtonText: "Delete interval"
                cancelButtonText: "Cancel"
                onConfirm: =>
                  @setState {isAlertOpen: false}
                  return unless @props.removeInterval?
                  @props.removeInterval(id)
                onCancel: => @setState {isAlertOpen: false}
            }, [
              h 'p', "Are you sure you want to delete the interval
                      beginning at #{hgt} m?"
            ]
          ]
        ]
      ]
    ]
  updateFacies: (facies)=>
    {interval} = @props
    selected = facies.id
    if selected == interval.facies
      selected = null
    @update {facies: selected}

  update: (columns)=>
    {TableName, update} = helpers
    tbl = new TableName("section_lithology", "section")
    id = @props.interval.id
    section = @props.section
    s = helpers.update columns, null, tbl
    s += " WHERE id=#{id} AND section='#{section}'"
    console.log s
    await db.none(s)
    @props.onUpdate()

module.exports = {ModalEditor}
