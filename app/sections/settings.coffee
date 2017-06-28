{Component} = require 'react'
h = require 'react-hyperscript'
CSSTransition = require 'react-addons-css-transition-group'
{Switch} = require '@blueprintjs/core'

require './settings.styl'


class ModeControl extends Component
  render: ->
    opts = @props.modes.map (d)=>
      props =
        type: 'button'
        className: 'pt-button'
        onClick: =>@update(d.value)
      if @props.activeMode == d.value
        props.className += ' pt-active'
      h 'button', props, d.label

    h 'div.mode-control', [
      h 'h5', 'Display mode'
      h 'div.pt-vertical.pt-button-group.pt-align-left.pt-fill', opts
    ]
  update: (value)=>
    return if value == @props.value
    @props.update activeMode: {$set: value}

class SettingsPanel extends Component
  render: ->
    body = []
    if @props.settingsPanelIsActive
      body = [
        h 'div#settings', {key: 'settings'}, [
          h 'h2', 'Settings'
          h ModeControl, @props
          h Switch, {
            checked: @props.showNotes
            label: "Show Notes"
            onChange: @switchHandler('showNotes')
          }
        ]
      ]

    props = {
      transitionName: "settings"
      transitionEnterTimeout: 1000
      transitionLeaveTimeout: 1000
    }
    h CSSTransition, props, body

  switchHandler: (name)=> =>
    v = {}
    v[name] = {$apply: (d)->not d}
    @props.update v

module.exports = SettingsPanel
