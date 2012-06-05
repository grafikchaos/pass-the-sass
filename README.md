# Pass the Sass
---

Pass the Sass is a web service that allows you to pass in SASS files in order to generate CSS on the fly.

The endpoint that matters is at `/api/` - you'll make a POST with the following parameters:

- sass
- vars
- compass
- domain
- origin


## sass

As it sounds like, you'll be posting your sass files. Put them in the sass parameter.

## vars

You'll post any updated variables to this parameter in an array format. (Ex. $color1=#abcabc,$color2=#000, ...)

## domain

You'll post the requesting domain - this will help with tracking and not getting wires crossed.

## origin

This is mostly for internal use, to track what themes/locations requests are coming from. It's an arbitrary identifier mostly.