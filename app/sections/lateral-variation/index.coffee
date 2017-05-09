d3 = require 'd3'
require 'd3-selection-multi'
Promise = require 'bluebird'
Query = require '../database'
chroma = require 'chroma-js'
_ = require 'underscore'
fs = require 'fs'
require './main.styl'
yaml = require 'js-yaml'

createVisualization = (el, units, sections, surfaces)->

  labels = yaml.safeLoad fs.readFileSync("#{__dirname}/labels.yaml", 'utf8')

  wrap = d3.select el

  size =
    width: 1200
    height: 1000

  svg = wrap.append "svg"
    .attrs size

  f = fs.readFileSync("#{__dirname}/patterns.svg")

  defs = svg.append "defs"
    .html f.toString()


  locations = d3.nest()
    .key (d)->d.location
    .entries sections

  marginX = 20
  scaleSize = 100
  padding = 500
  per_section = (size.width-padding-marginX-2*scaleSize)//(sections.length)

  # Construct lateral scale
  domain = []
  range = []
  i = 20+scaleSize
  for l in locations
    l.values.sort (a,b)-> a.section > b.section
    for s in l.values
      val = s.section.trim()
      domain.push val
      range.push i
      i += per_section
    i += padding//(locations.length-1)

  x = d3.scaleOrdinal()
    .domain domain
    .range range

  y = d3.scaleLinear()
    .domain [-50,800]
    .range [size.height-50,0]

  areaPath = d3.area()
    .x (d)->d[0]
    .y0 (d)->y(d[1])
    .y1 (d)->y(d[2])

  linePath = d3.line()
    .x (d)->d[0]
    .y (d)->y d[1]

  applyEdges = (v)->
    i = v[0].slice()
    j = v[v.length-1].slice()
    i[0] -= marginX
    j[0] += marginX
    v.unshift i
    v.push j

  double = (a,b)->
    b ?= a
    _.flatten _.zip a, b

  createX = (d)->
    xv = d.section.map x
    double xv, xv.map (d)->d+20

  areaGenerator = (d)->
    v = _.zip createX(d), double(d.start), double(d.end)
    applyEdges(v)
    areaPath(v)

  lineGenerator = (d)->
    v = _.zip createX(d), double(d.height)
    applyEdges(v)
    linePath(v)

  sv = [0,700]
  ys = d3.scaleLinear()
    .domain sv
    .range sv.map(y)

  yAxis = d3.axisLeft()
      .scale ys
      .ticks 10
      .tickSize 10

  ax = svg.append 'g'
    .attrs
      class: 'axis'
      transform: "translate(#{scaleSize-20} 0)"

  ax.append 'g'
    .call yAxis

  ax.append 'text'
      .text "Stratigraphic Height (m)"
      .attrs
        class: 'label'
        transform: "translate(-50,#{y(350)}) rotate(-90)"

  mid = svg.append "g"

  sel = mid.selectAll "g"
    .data units
  g = sel.enter()
    .append 'g'

  g.append "path"
    .attrs
      d: areaGenerator
      fill: (d)->d.color
      'fill-opacity': 0.7
      stroke: 'transparent'

  g.append 'path'
    .attrs
      d: areaGenerator
      fill: (d)->"url(##{d.dominant_lithology})"
      'fill-opacity': 0.7
      stroke: 'transparent'

  v = svg.append 'g'
  sel = v.selectAll 'path'
    .data surfaces

  sel.enter()
    .append 'path'
    .attrs
      d: lineGenerator
      fill: 'transparent'
      stroke: 'black'
      'stroke-width': (d)->d.weight

  # Lay out sections
  bkg = svg.append "g"
  sel = bkg.selectAll "g.section"
    .data sections

  xloc = (d)->x(d.section.trim())

  g = sel.enter()
    .append 'g'
    .attrs
      class: 'section'
      transform: (d)->"translate(#{xloc(d)} #{y(d.end)})"

  g.append "rect"
    .attrs
      fill: 'black'
      stroke: 'black'
      'stroke-width': 2
      width: 20
      height: (d)->y(d.start)-y(d.end)

  g = bkg.append "g"
    .attrs
      class: 'sections'
      transform: "translate(0 #{size.height-60})"

  g.append 'text'
    .attrs class: 'label smaller'
    .text 'Section'

  names = g.selectAll "text.name"
    .data sections

  names.enter()
    .append "text"
    .attrs
      class: 'name'
      x: xloc
    .text (d)->d.section.trim()

  locales = svg.append 'g'
    .attrs
      class: 'locality'
      transform: "translate(0 #{size.height-10})"

  locales.append 'text'
    .attrs class: 'label smaller'
    .text 'Locality'

  sel = locales.selectAll 'text.loc'
    .data labels.locality

  g = sel.enter()
    .append "text"
    .attrs
      class: 'loc'
      transform: (d)->"translate(#{d.x} 0)"

  g.append 'tspan'
    .text (d)->d.t1

  g.append 'tspan'
    .text (d)->" (#{d.t2})"
    .attrs class: 'label'

  fm = svg.append 'g'
    .attrs
      class: 'formations'
      transform: 'rotate(90) translate(0 -1110)'

  fm.append 'text'
    .attrs
      class: 'label smaller'
      transform: "translate(#{y(350)} -50)"
    .text 'Formation'

  sel = fm.selectAll 'text.fm'
    .data labels.formation

  sel.enter()
    .append "text"
    .text (d)->d.name
    .attrs
      class: 'fm'
      transform: (d)->"translate(#{y(d.h)} 0)"

module.exports = (el,cb)->
  Promise.all([
    Query "#{__dirname}/sql/unit-heights.sql"
    Query "#{__dirname}/sql/sections.sql"
    Query "#{__dirname}/sql/boundary-heights.sql"])
    .spread (heights, sections, surfaces)->
      createVisualization(el, heights.rows,sections.rows, surfaces.rows)
    .then -> cb()

