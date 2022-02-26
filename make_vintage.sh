#!/bin/bash

convert -density 130 Techrider/Macro_Feedback.pdf -rotate 0.33 -attenuate 0.15 +noise Multiplicative -colorspace Gray macro_notes.pdf
