# ImageReader
App to extract images from old iOS devices. There are two pieces:
- Very simple webserver written in Python. This webserver expects POST requestes with PNG images, and saved them in the the folder when it's running.
- An iOS app, compiled in iOS 10.0, that extract imagaes and videos, and POST them to an external webserver.
