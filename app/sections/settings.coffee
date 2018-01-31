{Component} = require 'react'
h = require 'react-hyperscript'
CSSTransition = require 'react-addons-css-transition-group'
{Switch} = require '@blueprintjs/core'
{format} = require 'd3'
{FaciesDescriptionSmall} = require './facies-descriptions'

require './settings.styl'


class PickerControl extends Component
  @defaultProps: {
    states : [
      {label: 'State 1', value: 'state1'}
      {label: 'State 2', value: 'state2'}
    ]
  }
  render: ->
    {states, activeState} = @props
    opts = states.map (d)=>
      props = {
        type: 'button'
        className: 'pt-button'
        onClick: @onUpdate(d.value)
      }
      if @props.activeState == d.value
        props.className += ' pt-active'
      h 'button', props, d.label

    h 'div.picker-control', [
      h 'div.pt-vertical.pt-button-group.pt-align-left.pt-fill', opts
    ]
  onUpdate: (value)=> =>
    return if value == @props.activeState
    return unless @props.onUpdate?
    @props.onUpdate(value)

fmt = format('.2f')

class SettingsPanel extends Component
  render: ->
    body = []
    if @props.settingsPanelIsActive
      body = [
        h 'div#settings', {key: 'settings'}, [
          h 'h2', 'Settings'
          h 'hr'
          @renderControls()
        ]
      ]

    props = {
      transitionName: "settings"
      transitionEnterTimeout: 1000
      transitionLeaveTimeout: 1000
    }
    h CSSTransition, props, body

  viewParams: =>
    h 'div#view-params', [
      h 'h5', 'View info'
      h 'table.pt-table', [
        h 'tbody', [
          h 'tr', [
            h 'td', 'Zoom'
            h 'td', fmt(@props.zoom)
          ]
        ]
      ]
    ]

  renderControls: =>
    return [
      h 'h5', "Components"
      @createSwitch 'showCarbonIsotopes', "Carbon isotopes"
      @createSwitch 'showFloodingSurfaces', "Sequence boundaries"
      @createSwitch 'showFacies', "Facies"
      @createSwitch 'showSymbols', 'Symbols'
      @createSwitch 'showNotes', "Notes"
      @createPicker 'displayModes', 'activeDisplayMode'
      h 'hr'
      @createSwitch 'inEditMode', "Allow editing"
      @createSwitch 'serializedQueries', "Serialized queries"
      h 'hr'
      h 'h5', 'Display mode'
      @createPicker 'modes', 'activeMode'
    ]

  createSwitch: (id, label)=>
    h Switch, {
      checked: @props[id]
      label: label
      key: id
      onChange: @switchHandler(id)
    }

  switchHandler: (name)=> =>
    v = {}
    v[name] = {$apply: (d)->not d}
    @props.update v

  createPicker: (modes, active)=>
    onUpdate = (value)=>
      v = {}
      v[active] = {$set: value}
      @props.update v

    h PickerControl, {
      states: @props[modes]
      activeState: @props[active]
      onUpdate
    }

class SummarySectionsSettings extends SettingsPanel
  renderControls: =>
    return [
      h 'h5', "Components"
      @createSwitch 'showCarbonIsotopes', "Carbon isotopes"
      @createSwitch 'showFloodingSurfaces', "Sequence boundaries"
      @createSwitch 'showSymbols', 'Symbols'
      @createSwitch 'showFacies', 'Facies'
      h 'hr'
      @createSwitch 'serializedQueries', "Serialized queries"
      h 'hr'
      h 'h5', 'Display mode'
      @createPicker 'modes', 'activeMode'
      h FaciesDescriptionSmall, {}, null
    ]

module.exports = {SettingsPanel, SummarySectionsSettings}
