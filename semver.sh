#!/usr/bin/env bash

#The MIT License (MIT)
#Copyright (c) 2023 Grillo del Mal
#
#Permission is hereby granted, free of charge, to any person obtaining a copy of this 
#software and associated documentation files (the "Software"), to deal in the Software 
#without restriction, including without limitation the rights to use, copy, modify, 
#merge, publish, distribute, sublicense, and/or sell copies of the Software, and to 
#permit persons to whom the Software is furnished to do so, subject to the following 
#conditions:
#
#The above copyright notice and this permission notice shall be included in all 
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
#INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
#PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO #EVENT SHALL THE AUTHORS OR COPYRIGHT 
#HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
#CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE 
#OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


function semver() {
    local DESCRIBE=`git -C $1 describe --tags --exclude nightly --always`
    if [[ "${DESCRIBE}" =~ ^[v] ]]; then
        DESCRIBE="${DESCRIBE:1}"
    fi

    # increment the build number (ie 115 to 116)
    local VERSION=`echo $DESCRIBE | awk '{split($0,a,"-"); print a[1]}'`
    local BUILD=`echo $DESCRIBE | awk '{split($0,a,"-"); print a[2]}'`
    local PATCH=`echo $DESCRIBE | awk '{split($0,a,"-"); print a[3]}'`
    local MODE=

    if [[ "${DESCRIBE}" =~ ^[A-Fa-f0-9]+$ ]]; then
        VERSION="0.0.0"
        BUILD=`git rev-list HEAD --count`
        PATCH=${DESCRIBE}
    fi

    if [ "${BUILD}" = "" ]; then
        BUILD='0'
        if [ ! -z "$2" ]; then
            echo ${2}+build.0-og.${VERSION}
            return
        fi
        echo ${VERSION}
        return
    fi

    if [[ ! "${BUILD}" =~ ^[0-9]+$ ]]; then
        MODE=`echo $DESCRIBE | awk '{split($0,a,"-"); print a[2]}'`
        BUILD=`echo $DESCRIBE | awk '{split($0,a,"-"); print a[3]}'`
        PATCH=`echo $DESCRIBE | awk '{split($0,a,"-"); print a[4]}'`

        if [ "${BUILD}" = "" ]; then

            if [[ "${MODE}" =~ ^pre || "${MODE}" =~ ^rc ]]; then
                RESULT="${VERSION}-${MODE}"
            else
                RESULT="${VERSION}+${MODE}"
            fi

            if [ ! -z "$2" ]; then
                echo ${2}+build.0-og.${RESULT}
            else
                echo ${RESULT}
            fi

        else
            if [[ "${MODE}" =~ ^pre || "${MODE}" =~ ^rc ]]; then
                RESULT="${VERSION}-${MODE}"
            else
                RESULT="${VERSION}+${MODE}"
            fi

            if [ ! -z "$2" ]; then
                echo ${2}+build.0-og.${RESULT}.build.${BUILD}.${PATCH}
            else
                echo ${RESULT}.build.${BUILD}.${PATCH}
            fi
        fi
        return
    fi

    if [ "${BUILD}" = "" ]; then
        PATCH=$DESCRIBE
    fi

    if [ ! -z "$2" ]; then
        echo ${2}+build.0-og.${VERSION}.build.${BUILD}.${PATCH}
        return
    fi

    echo ${VERSION}+build.${BUILD}.${PATCH}
}