hueToRGB = (m1, m2, h) ->
  h = if h < 0 then h + 1 else if h > 1 then h - 1 else h
  if h * 6 < 1 then return m1 + (m2 - m1) * h * 6
  if h * 2 < 1 then return m2
  if h * 3 < 2 then return m1 + (m2 - m1) * (0.66666 - h) * 6
  return m1

hsl = (h, s, l) ->
  m2 = if l <= 0.5 then l * (s + 1) else l + s - l*s
  m1 = l * 2 - m2
  r: hueToRGB m1, m2, h+0.33333
  g: hueToRGB m1, m2, h
  b: hueToRGB m1, m2, h-0.33333

map = (v, min, max) -> min+(max-min)*Math.min(1,Math.max(0,v))

makeHSLRef = (radius, width) ->
  canvas = document.createElement 'canvas'
  canvas.width = canvas.height = radius * 2
  ctx = canvas.getContext '2d'

  begin = window.performance.now()
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
      {r, g, b} = hsl h, s, 0.5
      data[(y*canvas.width+x)*4+0] = r*255
      data[(y*canvas.width+x)*4+1] = g*255
      data[(y*canvas.width+x)*4+2] = b*255
      data[(y*canvas.width+x)*4+3] = 255

  ctx.putImageData imgdata, 0, 0
  console.log performance.now() - begin
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

  ctx.fillStyle = 'rgba(0,0,0,0.2)'
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
  el.style.position = 'absolute'
  el.style.width = el.style.height = size + 'px'
  el.style.backgroundColor = 'red'
  el.style.borderRadius = Math.floor(size/2) + 'px'
  el.style.cursor = 'pointer'
  el.style.backgroundImage = '-webkit-gradient(radial, 50% 0%, 0, 50% 0%, 15, color-stop(0%, rgba(255, 255, 255, 0.8)), color-stop(100%, rgba(255, 255, 255, 0.2)))'
  el.style.webkitBoxShadow = 'white 0px 1px 1px inset, rgba(0, 0, 0, 0.4) 0px -1px 1px inset, rgba(0, 0, 0, 0.4) 0px 1px 4px 0px, rgba(0, 0, 0, 0.6) 0 0 2px'
  el

makePicker = ->
  origRadius = 100
  radius = 100
  width = 25
  div = document.createElement 'div'
  div.className = 'picker'
  ref = makeHSLRef radius, width
  circle = makeHSLCircle ref, 1
  circleContainer = document.createElement 'div'
  circleContainer.appendChild circle
  div.appendChild circleContainer
  div.style.position = 'relative'

  currentH = Math.PI
  currentS = 1

  k = knob 27
  circleContainer.appendChild k
  div.setH = (h) ->
    r = map(currentS, width, radius) - width / 2
    oR = origRadius - width / 2
    k.style.left = Math.round(oR + Math.cos(h)*r + 6 - 1) + 'px'
    k.style.top = Math.round(oR + Math.sin(h)*r + 6 - 1) + 'px'
    k.style.backgroundColor = 'hsl('+Math.round(h*180/Math.PI)+','+Math.floor(currentS*100)+'%,50%)'
    currentH = h

  div.setS = (s) ->
    newCircle = makeHSLCircle ref, s
    circleContainer.replaceChild newCircle, circle
    circle = newCircle
    currentS = s
    div.setH currentH

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
        div.setS s
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
      div.setH Math.atan2 e.clientY-cy, e.clientX-cx
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
  div.setS 1
  div

window.makePicker = makePicker
