#!/bin/sh

echo "Content-type: image/jpeg"
echo ""
getimage |  jpegtran -progressive -optimize
