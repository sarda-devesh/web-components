import {Component, createContext} from 'react'
import h from 'react-hyperscript'
import axios, {get, post} from 'axios'

APIContext = createContext({})
APIConsumer = APIContext.Consumer

class APIProvider extends Component
  @defaultProps: {
    baseRoute: "/api"
    onError: ->
  }
  render: ->
    {baseURL} = @props
    helpers = {buildURL: @buildURL}
    actions = {post: @post, get: @get}
    value = {actions..., helpers, baseURL}
    h APIContext.Provider, {value}, @props.children

  buildURL: (route, params={})=>
    {baseURL} = @props
    return null unless route?
    console.log route
    try
      if not route.startsWith(baseURL)
        route = baseURL+route
    catch
      debugger

    p = new URLSearchParams(params).toString()
    if p != ""
      route += "?"+p
    return route

  post: (route, params, payload, fullResponse=false)=>
    {onError} = @props
    if not payload?
      payload = params
      params = {}
    url = @buildURL route, params

    try
      res = await post url, payload
      {data} = res
      if not data?
        onError(route, res)
      if fullResponse
        return res
      return data
    catch err
      onError(route, {error:err})
      return null

  get: (route, params={}, fullResponse=false)=>
    {onError} = @props
    url = @buildURL route, params
    try
      res = await get url
      {data} = res
      if not data?
        onError(route, res)
      if fullResponse
        return res
      return data
    catch err
      onError(route, {error:err})
      return null

export {
  APIContext,
  APIProvider,
  APIConsumer
}

