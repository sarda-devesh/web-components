d3 = require 'd3'
require 'd3-selection-multi'
h = require 'react-hyperscript'
{findDOMNode} = require 'react-dom'
Measure = require('react-measure').default
{Component, createElement, createRef} = require 'react'

{BaseSVGSectionComponent} = require '../summary-sections/column'
{SectionAxis} = require '../column/axis'
{GeneralizedSectionColumn, FaciesColumn} = require '../column/lithology'
{FaciesContext} = require '../facies-descriptions'
{SVGNamespaces} = require '../util'
{SequenceStratConsumer} = require '../sequence-strat-context'
{TriangleBars} = require '../column/flooding-surface'

class GeneralizedSVGSectionBase extends Component
  @defaultProps: {pixelsPerMeter: 20, zoom: 1}
  constructor: (props)->
    super props

  renderTriangleBars: ->
    {showTriangleBars,
     id, divisions,
     scale, sequenceStratOrder} = @props
    return null unless showTriangleBars
    h TriangleBars, {
      id, divisions, scale, order: sequenceStratOrder
    }

  render: ->
    { id,
      showFacies,
      divisions,
      position,
      facies } = @props

    {x: left, y: top, width, height, heightScale} = position

    scale = heightScale.local

    divisions = divisions.filter (d)->not d.schematic

    transform = "translate(#{left} #{top})"

    h "g.section", {transform, key: id}, [
      h FaciesColumn, {
        width
        height
        facies
        divisions
        showFacies
        scale
        id
      }
      @renderTriangleBars()
    ]

class GeneralizedSVGSection extends Component
  render: ->
    h FaciesContext.Consumer, null, ({facies})=>
      h SequenceStratConsumer, null, ({actions, rest...})=>
        props = {@props..., facies, rest...}
        h GeneralizedSVGSectionBase, props


module.exports = {GeneralizedSVGSection}
