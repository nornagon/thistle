Thistle is an HSL color picker. [Try it out](http://nornagon.github.com/thistle)!

![A screenshot of the color picker](http://i.imgur.com/CdbYg.png)

Inspired by Brandon Mathis's excellent [hslpicker](http://hslpicker.com).

## API

```html
<script src='http://nornagon.github.com/thistle/picker.js'></script>
<script>
  var picker = thistle.makePicker('rgb(129,34,203)')
  document.body.appendChild(picker.el)
  picker.on('changed', function() {
    document.body.style.backgroundColor = picker.cssColor
  })
</script>
```

There are three methods in the thistle API:

- `thistle.makePicker(color)` creates a picker object but doesn't attach it to
  the DOM. You're free to put it wherever you like in your page, animate it,
  hide it, whatever. The argument `color` can be either a string representing a
  CSS color like `#fff`, `mediumseagreen`, `hsl(34,20%,45%)` or
  `rgb(234,221,193)`, or an object specifying hsl components like
  `{h:231, s:1, l:0.5}`.
- `thistle.presentModalPickerBeneath(element, color)` creates a picker object
  for `color` like `thistle.makePicker`, and then adds it to the DOM, animates
  it into being just beneath `element`, and creates a modalness that means if
  the user clicks anywhere except inside the picker, the picker will be
  dismissed.
- `thistle.presentModalPicker(x, y, color)` is just like
  `thistle.presentModalPickerBeneath`, but you get to choose the precise x/y
  coordinates at which the picker will appear.

Once you have created your picker object, you can listen to events on it. To be
notified when the user changes the color, listen to `picker.on('changed')`. If
you created a modal picker, you can listen to `picker.on('closed')` to be
notified when the user dismisses the picker.

To fetch the current color of the picker, you can enquire with any of
`picker.rgb`, `picker.hsl` or `picker.cssColor`.

- `picker.rgb` is an object like `{r:0.5, g:0.3, b:0.9}`.
- `picker.hsl` is an object like `{h:180, s:0.5, l:0.5}`.
- `picker.cssColor` will return a string which you can assign to, say,
  `element.style.backgroundColor`.

You can also set any of these properties with an object like the one they
return:

```javascript
picker.cssColor = 'mintcream'
picker.cssColor = '#d8bfd8'
picker.rgb = {r:1.0, g:0.4, b:0.0}
picker.hsl = {h:45, s:0.9, l:0.6}
```

Amusingly, 'thistle' is a [valid CSS color](http://dev.w3.org/csswg/css3-color/#svg-color).
