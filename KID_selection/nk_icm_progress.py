import sys
import time
from progressbar import AnimatedMarker, Bar, BouncingBar, Counter, ETA, \
                        FileTransferSpeed, FormatLabel, Percentage, \
                        ProgressBar, ReverseBar, RotatingMarker, \
                        SimpleProgress, Timer

def progress_bar():
    class CrazyFileTransferSpeed(FileTransferSpeed):
        "It's bigger between 45 and 80 percent"
        def update(self, pbar):
            return FileTransferSpeed.update(self,pbar)

    widgets = [CrazyFileTransferSpeed(),' <<<', Bar(), '>>> ',
               Percentage(),' ', ETA()]
    pbar = ProgressBar(widgets=widgets, maxval=10000000)
    return pbar
