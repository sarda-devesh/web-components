{findDOMNode} = require 'react-dom'
{Component} = require 'react'
require './main.styl'
{select} = require 'd3-selection'
h = require 'react-hyperscript'
ElementPan = require 'react-element-pan'
{NavLink} = require '../nav'
{Icon} = require 'react-fa'
SettingsPanel = require './settings'
update = require 'immutability-helper'
{SectionNavigationControl} = require './util'
LocalStorage = require './storage'
{db, storedProcedure, query} = require './db'
d3 = require 'd3'
classNames = require 'classnames'
{SwatchesPicker} = require 'react-color'
{Popover} = require '@blueprintjs/core'

class FaciesDescriptionPage extends Component
  constructor: (props)->
    super props
    @state = {
      options: {
        isEditable: false
      }
      facies: []
    }

    @updateData()
    @optionsStorage = new LocalStorage 'facies-descriptions'
    v = @optionsStorage.get()
    return unless v?
    @state = update @state, options: {$merge: v}

  updateData: =>
    query('facies').then (facies)=>
      @setState {facies}

  render: ->
    h 'div.page.facies-descriptions.text-page', [
      h SectionNavigationControl
      h 'h1', 'Facies descriptions'
      h 'div', @state.facies.map (d)=>
        h 'div.facies-card.pt-card', {key: d.id}, [
          h 'div.header', [
            h Popover, [
              h 'div.color-swatch', {style: {backgroundColor: d.color or 'black', width: '2em', height: '2em'}}
              h 'div', [
                h SwatchesPicker, {color: d.color or 'black', onChangeComplete: @onChangeColor(d.id)}
              ]
            ]
            h 'h2', d.name
          ]
          h 'p', d.description or "No description"
        ]
    ]

  onChangeColor: (id)=>(color)=>
    sql = storedProcedure('set-facies-color', {baseDir: __dirname})
    color = color.hex
    await db.none sql, {id,color}
    @updateData()

class FaciesDescriptionSmall extends Component
  @defaultProps: {selected: null}
  constructor: (props)->
    super props
    @state = {
      options: {
        isEditable: false
      }
      facies: []
    }

    @updateData()
    @optionsStorage = new LocalStorage 'facies-descriptions'
    v = @optionsStorage.get()
    return unless v?
    @state = update @state, options: {$merge: v}

  updateData: =>
    query('facies').then (facies)=>
      @setState {facies}

  render: ->
    h 'div.facies-description-small', [
      h 'h5', 'Facies'
      h 'div', @state.facies.map (d)=>
        onClick = null
        style = {}
        if @props.onClick?
          onClick = =>@props.onClick(d)
          style.cursor = 'pointer'
        {selected} = @props
        if selected == d.id
          style.backgroundColor = d.color
          style.color = 'white'
        className = classNames({selected: selected == d.id})

        h 'div.facies.pt-card.pt-elevation-0', {
          key: d.id, onClick, style, className
        }, [
          h 'div.header', [
            h Popover, {
              tetherOptions:{
                constraints: [{ attachment: "together", to: "scrollParent" }]
              }
            }, [
              h 'div.color-swatch', {style: {backgroundColor: d.color or 'black', width: '2em', height: '2em'}}
              h 'div', [
                h SwatchesPicker, {
                  color: d.color or 'black'
                  onChangeComplete: @onChangeColor(d.id)
                  styles: {
                    width: 500
                    height: 570
                  }
                }
              ]
            ]
            h 'p', {style: {marginLeft: 20}}, d.name
          ]
        ]
    ]

  onChangeColor: (id)=>(color)=>
    sql = storedProcedure('set-facies-color', {baseDir: __dirname})
    color = color.hex
    await db.none sql, {id,color}
    @updateData()


module.exports = {FaciesDescriptionPage, FaciesDescriptionSmall}

