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

# Diagram
[![](https://mermaid.ink/img/pako:eNqNU02LwjAQ_Sshp-oq7PbYw4KS4gqlFrV4KZRgxlrWJpLGXRbrf9-k2Zb6uTaXyfDemzfTyRGvBQPs4UzS_RYtxwlH-us7qIeGw3dUvaFNzjOQiIlvXpHZKnSIjnoWZ-6XOEmzisxHk3TsT6ZhakKH6OQYspyjF2TiKzoXqBBfUABXVTALJ9HcXyycQPAsklCWDf5c9l7lB2CXs_OGDGg1XX6kYRwEKfGD5ah2i14RgZ2i3coXOK1oNa9b90NSF3U7Btxa19cG7Azc7kDcbp2bbHSnlpV9li9hB7QE1AzNShiGldH2Okr_kh4O5wZTd9sad7qL0PygO8Vag-f-TLqmxVHHdJu91oojJ973bmIfLrBlxFEN7dtbu6ZP8xNujonwABcgC5oz_fSOJpdgtdXrn2BPh4zKzwQn_KRxhz2jCnyWKyGxt6G7EgaYHpRY_PA19pQ8QAMiOdXPuPhDnX4BDeYn2Q)](https://mermaid.live/edit#pako:eNqNU02LwjAQ_Sshp-oq7PbYw4KS4gqlFrV4KZRgxlrWJpLGXRbrf9-k2Zb6uTaXyfDemzfTyRGvBQPs4UzS_RYtxwlH-us7qIeGw3dUvaFNzjOQiIlvXpHZKnSIjnoWZ-6XOEmzisxHk3TsT6ZhakKH6OQYspyjF2TiKzoXqBBfUABXVTALJ9HcXyycQPAsklCWDf5c9l7lB2CXs_OGDGg1XX6kYRwEKfGD5ah2i14RgZ2i3coXOK1oNa9b90NSF3U7Btxa19cG7Azc7kDcbp2bbHSnlpV9li9hB7QE1AzNShiGldH2Okr_kh4O5wZTd9sad7qL0PygO8Vag-f-TLqmxVHHdJu91oojJ973bmIfLrBlxFEN7dtbu6ZP8xNujonwABcgC5oz_fSOJpdgtdXrn2BPh4zKzwQn_KRxhz2jCnyWKyGxt6G7EgaYHpRY_PA19pQ8QAMiOdXPuPhDnX4BDeYn2Q)
