# Corpse RPG (2014 edition)
This is an old RPG I was working on. I had to go to college, so I stopped
working on it around then.

It's my biggest body of all-mine SNES code, so sometimes when I am talking
about doing stuff on SNES I will reference it; I am putting it on GitHub so
I can link it instead of just talking nonsense.

There is some stuff in here that might be moderately interesting if you are a
SNES dweeb.

A warning, since there's one thing that *looks* pretty cool but isn’t:
don't be fooled by the compression scheme, it was *supposed* to be based on
the Paeth filter from PNG but my Paeth predictor ended up being *dreadfully*
slow which is why I looked into LC_LZ3 and stuff. RLE on the difference between
the Paeth prediction and the actual value ended up being a surprisingly decent
compression scheme on the graphics I tried, but none of the code here is
actually based on it, and I apparently didn't keep the code that was. Whoops!