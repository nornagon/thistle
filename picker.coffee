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


makeHSLCircle = (radius, width) ->
  canvas = document.createElement 'canvas'
  canvas.width = canvas.height = radius * 2
  ctx = canvas.getContext '2d'

  imgdata = ctx.createImageData canvas.width, canvas.height
  data = imgdata.data
  for y in [0...canvas.height]
    for x in [0...canvas.width]
      h = Math.atan2(y-radius, x-radius) / (Math.PI*2)
      {r, g, b} = hsl h, 1, 0.5
      data[(y*canvas.width+x)*4+0] = r*255
      data[(y*canvas.width+x)*4+1] = g*255
      data[(y*canvas.width+x)*4+2] = b*255
      data[(y*canvas.width+x)*4+3] = 255

  ctx.putImageData imgdata, 0, 0
  img = canvas

  canvas = document.createElement 'canvas'
  canvas.width = canvas.height = radius * 2
  ctx = canvas.getContext '2d'
  ctx.arc radius, radius, radius, 0, Math.PI*2
  ctx.arc radius, radius, radius - width, 0, Math.PI*2, true
  ctx.fill()
  ctx.globalCompositeOperation = 'source-in'

  #ctx.clip()
  ctx.drawImage img, 0, 0
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
  radius = 100
  width = 25
  div = document.createElement 'div'
  div.className = 'picker'
  circle = makeHSLCircle radius, width
  div.appendChild circle
  div.style.position = 'relative'

  k = knob 27
  div.appendChild k
  div.setH = (h) ->
    r = radius - width/2
    k.style.left = Math.round(r + Math.cos(h)*r + 6 - 1) + 'px'
    k.style.top = Math.round(r + Math.sin(h)*r + 6 - 1) + 'px'
    k.style.backgroundColor = 'hsl('+Math.round(h*180/Math.PI)+',100%,50%)'

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
  div.setH Math.PI
  div

window.makePicker = makePicker
