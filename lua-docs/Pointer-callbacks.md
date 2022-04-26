# Pointer callbacks

## When using a mouse
- When pressing down the left button `Pointer.Down` is called and when releasing it `Pointer.Up` is called.
- If the mouse is moved while pressing the left button then `Pointer.Drag` will be called during the motion, with `Pointer.DragBegin` at the beggining of it and `Pointer.DragEnd` at the same time as `Pointer.Up`.
- `Pointer.Drag2` is similar to `Pointer.Drag` but it is used when the right mouse button is pressed.

## When using a touchscreen
- `Pointer.Down`, `Pointer.Up` and `Pointer.Drag` work the same way as with a mouse
- `Pointer.Drag2` is called when touching the screen with 2 fingers (this may also trigger `Pointer.Zoom`).
- At the beggining of a `Pointer.Drag2` motion, if the user has done a `Drag` motion beforehand, then `Pointer.Drag2Begin` will be called right after `Pointer.DragEnd`.
- `Drag` and `Drag2` can happen alternately any number of time between a `Down` and an `Up`.
