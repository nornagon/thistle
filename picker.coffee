hueToRGB = (m1, m2, h) ->
  h = if h < 0 then h + 1 else if h > 1 then h - 1 else h
  if h * 6 < 1 then return m1 + (m2 - m1) * h * 6
  if h * 2 < 1 then return m2
  if h * 3 < 2 then return m1 + (m2 - m1) * (0.66666 - h) * 6
  return m1

hslToRGB = (h, s, l) ->
  m2 = if l <= 0.5 then l * (s + 1) else l + s - l*s
  m1 = l * 2 - m2
  r: hueToRGB m1, m2, h+0.33333
  g: hueToRGB m1, m2, h
  b: hueToRGB m1, m2, h-0.33333

rgbToHSL = (r, g, b) ->
  max = Math.max(r, g, b)
  min = Math.min(r, g, b)
  diff = max - min
  sum = max + min

  h =
    if min is max then 0
    else if r is max then ((60 * (g - b) / diff) + 360) % 360
    else if g is max then (60 * (b - r) / diff) + 120
    else (60 * (r - g) / diff) + 240

  l = sum / 2

  s =
    if l is 0 then 0
    else if l is 1 then 1
    else if l <= 0.5 then diff / sum
    else diff / (2 - sum)

  {h, s, l}

style = (tag, styles) ->
  for n,v of styles
    tag.style[n] = v

fmod = (x, m) ->
  x = x % m
  x += m if x < 0
  x

map = (v, min, max) -> min+(max-min)*Math.min(1,Math.max(0,v))

makeHSLRef = (radius, width, lightness=0.5) ->
  canvas = document.createElement 'canvas'
  canvas.width = canvas.height = radius * 2
  ctx = canvas.getContext '2d'

  imgdata = ctx.createImageData canvas.width, canvas.height
  data = imgdata.data
  for y in [0...canvas.height]
    for x in [0...canvas.width]
      dy = y-radius
      dx = x-radius
      d = Math.sqrt(dy*dy+dx*dx)
      if d > radius+1.5
        continue
      # d<10 maps to 0
      # 10<=d<radius-width maps to [0,1]
      # d>=radius-width maps to 1
      d -= 10
      s = Math.max 0, Math.min 1, d / (radius-width/2-10)
      h = Math.atan2(dy, dx) / (Math.PI*2)
      {r, g, b} = hslToRGB h, s, lightness
      data[(y*canvas.width+x)*4+0] = r*255
      data[(y*canvas.width+x)*4+1] = g*255
      data[(y*canvas.width+x)*4+2] = b*255
      data[(y*canvas.width+x)*4+3] = 255

  ctx.putImageData imgdata, 0, 0
  canvas._radius = radius
  canvas._width = width
  canvas

makeHSLCircle = (ref, s) ->
  radius = ref._radius
  width = ref._width
  r = map(s, width, radius)
  canvas = document.createElement 'canvas'
  canvas.width = canvas.height = radius * 2
  ctx = canvas.getContext '2d'

  ctx.fillStyle = 'rgba(0,0,0,0.3)'
  ctx.beginPath()
  ctx.arc radius, radius, radius, 0, Math.PI*2
  ctx.fill()

  ctx.fillStyle = 'black'
  ctx.beginPath()
  ctx.arc radius, radius, r, 0, Math.PI*2
  ctx.arc radius, radius, r - width, 0, Math.PI*2, true
  ctx.fill()

  ctx.globalCompositeOperation = 'source-in'

  #ctx.clip()
  ctx.drawImage ref, 0, 0
  canvas

knob = (size) ->
  el = document.createElement 'div'
  el.className = 'knob'
  style el,
    position: 'absolute'
    width: size + 'px'
    height: size + 'px'
    backgroundColor: 'red'
    borderRadius: Math.floor(size/2) + 'px'
    cursor: 'pointer'
    backgroundImage: '-webkit-gradient(radial, 50% 0%, 0, 50% 0%, 15, color-stop(0%, rgba(255, 255, 255, 0.8)), color-stop(100%, rgba(255, 255, 255, 0.2)))'
    webkitBoxShadow: 'white 0px 1px 1px inset, rgba(0, 0, 0, 0.4) 0px -1px 1px inset, rgba(0, 0, 0, 0.4) 0px 1px 4px 0px, rgba(0, 0, 0, 0.6) 0 0 2px'
  el

hslToCSS = (h, s, l) ->
  'hsl('+Math.round(h*180/Math.PI)+','+Math.round(s*100)+'%,'+Math.round(l*100)+'%)'

makePicker = (color={h:180,s:1,l:0.5}) ->
  radius = 80
  width = 25

  currentH = Math.PI
  currentS = 1
  currentL = 0.5

  if color.r? and color.g? and color.b?
    hsl = rgbToHSL color.r, color.g, color.b
    currentH = hsl.h * Math.PI/180
    currentS = hsl.s
    currentL = hsl.l
  else if color.h? and color.s? and color.l?
    currentH = color.h * Math.PI/180
    currentS = color.s
    currentL = color.l

  originalColor = hslToCSS(currentH, currentS, currentL)

  div = document.createElement 'div'
  div.className = 'picker'
  style div,
    display: 'inline-block'
    background: 'hsl(0, 0%, 97%)'
    padding: '6px'
    borderRadius: '6px'
    boxShadow: '1px 1px 5px hsla(0, 0%, 39%, 0.2), hsla(0, 0%, 100%, 0.9) 0px 0px 1em 0.3em inset'
    border: '1px solid hsla(0, 0%, 59%, 0.2)'
    position: 'absolute'
    backgroundImage: '-webkit-gradient(linear, 0% 0%, 100% 100%, color-stop(25%, hsla(0, 0%, 0%, 0.05)), color-stop(25%, transparent), color-stop(50%, transparent), color-stop(50%, hsla(0, 0%, 0%, 0.05)), color-stop(75%, hsla(0, 0%, 0%, 0.05)), color-stop(75%, transparent), color-stop(100%, transparent))'
    backgroundSize: '40px 40px'

  ref = makeHSLRef radius, width
  circle = makeHSLCircle ref, 1
  circleContainer = document.createElement 'div'
  style circleContainer,
    display: 'inline-block'
    width: radius*2+'px'
    height: radius*2+'px'
    borderRadius: radius+'px'
    boxShadow: '0px 0px 7px rgba(0,0,0,0.3)'

  circleContainer.appendChild circle
  div.appendChild circleContainer

  lSlider = div.appendChild document.createElement 'div'
  style lSlider,
    display: 'inline-block'
    width: '20px'
    height: radius*2-22 + 'px'
    marginLeft: '6px'
    borderRadius: '10px'
    boxShadow: 'hsla(0, 100%, 100%, 0.1) 0 1px 2px 1px inset, hsla(0, 100%, 100%, 0.2) 0 1px inset, hsla(0, 0%, 0%, 0.4) 0 -1px 1px inset, hsla(0, 0%, 0%, 0.4) 0 1px 1px'
    position: 'relative'
    top: '-11px'
  lSlider._height = radius*2-22

  lKnob = knob 22
  style lKnob, left: '-1px'
  lSlider.appendChild lKnob

  console.log(originalColor)
  colorPreview = document.createElement 'div'
  div.appendChild colorPreview
  style colorPreview,
    boxShadow: 'hsla(0, 0%, 0%, 0.5) 0 1px 5px, hsla(0, 100%, 100%, 0.4) 0 1px 1px inset, hsla(0, 0%, 0%, 0.3) 0 -1px 1px inset'
    height: '25px'
    marginTop: '6px'
    borderRadius: '3px'
    backgroundImage: '-webkit-gradient(linear, 0% -100%, 100% 200%, from(transparent), color-stop(0.7, transparent), color-stop(0.7, '+originalColor+'), to('+originalColor+'))'

  k = knob 27
  circleContainer.appendChild k

  setH = (h) ->
    r = map(currentS, width, radius) - width / 2
    oR = radius - width / 2
    k.style.left = Math.round(oR + Math.cos(h)*r + 6 - 1) + 'px'
    k.style.top = Math.round(oR + Math.sin(h)*r + 6 - 1) + 'px'
    currentH = h
    k.style.backgroundColor = hslToCSS(currentH, currentS, currentL)
    colorPreview.style.backgroundColor = lKnob.style.backgroundColor = k.style.backgroundColor
    picker.emit 'changed'

    b = hslToCSS(currentH,currentS,0.5)
    lSlider.style.backgroundImage = '-webkit-gradient(linear, 50% 100%, 50% 0%, from(black),color-stop(0.5,'+b+'),to(white))'

  setS = (s) ->
    newCircle = makeHSLCircle ref, s
    circleContainer.replaceChild newCircle, circle
    circle = newCircle
    currentS = s
    setH currentH

  setL = (l) ->
    ref = makeHSLRef radius, width, l
    currentL = l
    lKnob.style.top = (1-l) * lSlider._height - 11 + 'px'
    setS currentS


  lKnob.onmousedown = (e) ->
    document.documentElement.style.cursor = 'pointer'
    window.addEventListener('mousemove', move = (e) ->
      r = lSlider.getBoundingClientRect()
      y = e.clientY - r.top
      setL Math.max 0, Math.min 1, 1-(y / (lSlider._height))
    )
    window.addEventListener('mouseup', up = (e) ->
      window.removeEventListener('mousemove', move)
      window.removeEventListener('mouseup', up)
      window.removeEventListener('blur', up)
      document.documentElement.style.cursor = ''
    )
    window.addEventListener('blur', up)
    e.preventDefault()
    e.stopPropagation()

  attachSaturationControl = (c) ->
    updateCursor = (e) ->
      x = e.offsetX; y = e.offsetY
      dx = x-radius; dy = y-radius; d = Math.sqrt(dx*dx+dy*dy)
      t = Math.atan2 dy, dx
      r = map(currentS, width, radius)
      if r-width < d < r
        if -Math.PI/8 < t < Math.PI/8 or t >= 7*Math.PI/8 or t <= -7*Math.PI/8
          c.style.cursor = 'ew-resize'
        else if Math.PI/8 <= t < 3*Math.PI/8 or -7*Math.PI/8 < t <= -5*Math.PI/8
          c.style.cursor = 'nwse-resize'
        else if 3*Math.PI/8 <= t < 5*Math.PI/8 or -5*Math.PI/8 < t <= -3*Math.PI/8
          c.style.cursor = 'ns-resize'
        else if 5*Math.PI/8 <= t < 7*Math.PI/8 or -3*Math.PI/8 < t <= -Math.PI/8
          c.style.cursor = 'nesw-resize'
      else
        c.style.cursor = ''
    c.addEventListener 'mouseover', (e) ->
      updateCursor e
      c.addEventListener 'mousemove', move = (e) ->
        updateCursor e
      c.addEventListener 'mouseout', out = (e) ->
        c.style.cursor = ''
        c.removeEventListener 'mousemove', move
        c.removeEventListener 'mouseout', out
    c.addEventListener 'mousedown', (e) ->
      e.preventDefault()
      document.documentElement.style.cursor = c.style.cursor
      window.addEventListener('mousemove', move = (e) ->
        r = circle.getBoundingClientRect()
        cx = r.left + r.width/2
        cy = r.top + r.height/2
        dx = e.clientX-cx
        dy = e.clientY-cy
        d = Math.sqrt(dx*dx+dy*dy)
        # TODO: this is copied from above
        d -= 10
        s = Math.max 0, Math.min 1, d / (radius-width/2-10)
        setS s
      )
      window.addEventListener('mouseup', up = (e) ->
        window.removeEventListener('mousemove', move)
        window.removeEventListener('mouseup', up)
        window.removeEventListener('blur', up)
        document.documentElement.style.cursor = ''
      )
      window.addEventListener('blur', up)
  attachSaturationControl circleContainer

  k.onmousedown = (e) ->
    document.documentElement.style.cursor = 'pointer'
    window.addEventListener('mousemove', move = (e) ->
      r = circle.getBoundingClientRect()
      cx = r.left + r.width/2
      cy = r.top + r.height/2
      setH Math.atan2 e.clientY-cy, e.clientX-cx
    )
    window.addEventListener('mouseup', up = (e) ->
      window.removeEventListener('mousemove', move)
      window.removeEventListener('mouseup', up)
      window.removeEventListener('blur', up)
      document.documentElement.style.cursor = ''
    )
    window.addEventListener('blur', up)
    e.preventDefault()
    e.stopPropagation()

  listeners = {}

  picker =
    el: div
    on: (e, l) ->
      (listeners[e] ?= []).push l
    emit: (e, args...) ->
      l.call(this, args...) for l in listeners[e] ? []
    removeListener: (e, l) ->
      listeners[e] = (k for k in listeners[e] when k isnt l) if listeners[e]
    set: (h, s, l) ->
      currentH = fmod(h,360) * Math.PI/180
      currentS = Math.max 0, Math.min 1, s
      currentL = Math.max 0, Math.min 1, l
      setL l

  Object.defineProperty picker, 'hsl',
    get: ->
      { h: fmod(currentH * 180/Math.PI, 360), s: currentS, l: currentL }
    set: ({h,s,l}) -> @set h, s, l

  Object.defineProperty picker, 'rgb',
    get: -> hslToRGB currentH/(Math.PI*2), currentS, currentL
    set: ({r,g,b}) ->
      {h, s, l} = rgbToHSL r, g, b
      @set h*Math.PI/180, s, l

  picker.set currentH * 180/Math.PI, currentS, currentL

  picker

window.makePicker = makePicker
