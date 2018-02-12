{findDOMNode} = require 'react-dom'
d3 = require 'd3'
require 'd3-selection-multi'
{Component, createElement} = require 'react'
h = require 'react-hyperscript'
Measure = require('react-measure').default
{SectionAxis} = require '../column/axis'
{BaseSectionComponent} = require '../column/base'
{SymbolColumn} = require '../column/symbol-column'
{LithologyColumn, CoveredColumn, GeneralizedSectionColumn} = require '../column/lithology'
{withRouter} = require 'react-router-dom'

class SVGSectionComponent extends BaseSectionComponent
  @defaultProps: {
    BaseSectionComponent.defaultProps...
    trackVisibility: false
    innerWidth: 100
    height: 100 # Section height in meters
    lithologyWidth: 40
    showFacies: true
    onResize: ->
    marginLeft: -25
    padding:
      left: 30
      top: 10
      right: 10
      bottom: 10
  }
  constructor: (props)->
    super props
    @state = {
      @state...
      visible: not @props.trackVisibility
      scale: d3.scaleLinear().domain(@props.range)
    }
    @state.scale.clamp()

  onClick: (event)=>
    {history} = @props
    {scale} = @state
    {top} = event.target.getBoundingClientRect()
    {clientY} = event
    height = scale.invert(clientY-top)
    console.log "Clicked Section #{@props.id} @ #{height}"
    history.push("/sections/#{@props.id}/height/#{height}")

  render: ->
    {id, zoom, padding, lithologyWidth,
     innerWidth, onResize, marginLeft,
     showFacies, height, clip_end} = @props

    innerHeight = height*@props.pixelsPerMeter*@props.zoom

    {left, top, right, bottom} = padding

    scaleFactor = @props.scaleFactor/@props.pixelsPerMeter

    @state.scale.range [innerHeight, 0]
    outerHeight = innerHeight+(top+bottom)
    outerWidth = innerWidth+(left+right)

    {heightOfTop} = @props
    marginTop = heightOfTop*@props.pixelsPerMeter*@props.zoom

    [bottom,top] = @props.range

    txt = id

    {scale,visible, divisions} = @state
    divisions = divisions.filter (d)->not d.schematic
    zoom = @props.zoom

    {skeletal} = @props

    # Set up number of ticks
    nticks = (height*@props.zoom)/10

    style = {
      width: outerWidth
      height: outerHeight
      marginLeft
    }

    transform = "translate(#{@props.padding.left} #{@props.padding.top})"

    minWidth = outerWidth
    h "div.section-container", {
      className: if @props.skeletal then "skeleton" else null
      style: {minWidth}
    }, [
      h 'div.section-header', [h "h2", txt]
      h 'div.section-outer', [
        h Measure, {
          bounds: true,
          onResize: @onResize
        }, ({measureRef})=>
          h "svg.section", {
            style, ref: measureRef
            onClick: @onClick
          }, [
            h 'g.backdrop', {transform}, [
              h CoveredColumn, {
                height: innerHeight
                divisions
                scale
                id
                width: 6
              }
              h GeneralizedSectionColumn, {
                width: innerWidth
                height: innerHeight
                divisions
                showFacies
                scale
                id
                grainsizeScaleStart: 40
              }
              h SymbolColumn, {
                scale
                height: innerHeight
                left: 90
                id
              }
              h SectionAxis, {scale, ticks: nticks}
            ]
          ]
      ]
    ]

SVGSectionComponent = withRouter(SVGSectionComponent)

module.exports = {SVGSectionComponent}

