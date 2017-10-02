{query} = require '../db'
d3 = require 'd3'
{Component} = require 'react'
h = require 'react-hyperscript'

fmt = d3.format('+.1f')

class Samples extends Component
  constructor: (props)->
    super props
    @state =
      samples: []
    @getSamples()

  getSamples: ->
    query 'section-samples', [@props.id]
      .then (data)=>
        @setState samples: data

  render: ->
    {scale, zoom} = @props
    {samples} = @state

    h 'g.samples', {},
      samples.map (d)->
        y = scale(d.height)
        x = -30
        transform = "translate(#{x} #{y})"
        h "g.sample", {transform, key: d.sample_id}, [
          h "circle", {cx: 0, cy: 0, r: 2*zoom}
          h "text", {x: -10, y: -5}, "∂¹³C "+fmt(d.avg_delta13c)
          h "text", {x: -10, y: 5}, "∂¹⁸O "+fmt(d.avg_delta18o)
        ]

module.exports = Samples
