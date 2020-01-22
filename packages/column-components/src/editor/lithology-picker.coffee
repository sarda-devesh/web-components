import {Component, createElement, useContext} from "react"
import hyper from "@macrostrat/hyper"
import {RaisedSelect} from './util'

import {symbolIndex} from "../lithology"
import {GeologicPatternContext} from '../lithology'
import {LithologyContext} from "../context"

import styles from './main.styl'

h = hyper.styled(styles)

LithologySwatch = ({symbolID, style, rest...})->
  {resolvePattern} = useContext(GeologicPatternContext)
  src = resolvePattern(symbolID)
  style ?= {}
  style.backgroundImage = "url(\"#{src}\")"
  h 'div.lithology-swatch', {style, rest...}

LithologyItem = (props)->
  {symbol, lithology} = props
  h 'span.facies-picker-row', [
    h LithologySwatch, {symbolID: symbol}
    h 'span.facies-picker-name', lithology
  ]

class LithologyPicker extends Component
  @contextType: LithologyContext
  render: ->
    {interval, onChange} = @props

    {lithologies} = @context

    options = for item in lithologies
      {id, pattern} = item
      symbol = symbolIndex[pattern]
      continue unless symbol?
      {value: id, label: h(LithologyItem, {lithology: id, symbol})}

    value = options.find (d)->d.value == interval.lithology
    value ?= null

    h RaisedSelect, {
      id: 'lithology-select'
      options
      value
      isClearable: true
      onChange: (res)->
        f = if res? then res.value else null
        onChange f
    }


class LithologySymbolPicker extends Component
  render: ->
    {interval} = @props
    isUserSet = false
    console.log interval
    text = "No pattern set"
    if interval.pattern?
      symbol = interval.pattern
      isUserSet = true
      text = "Symbol #{symbol}"
    if interval.lithology?
      symbol = symbolIndex[interval.lithology]
      text = "Default for lithology"

    h 'div.lithology-symbol-picker', [
      h.if(symbol?) LithologySwatch, {symbolID: symbol}
      h "div.picker-label.text", text
    ]

export {LithologyPicker, LithologySymbolPicker}
