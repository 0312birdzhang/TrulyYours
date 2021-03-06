/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2014 matrixx
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import "Data.js" as Data;

Page {
    id: page
    property string filter: ""
    Component.onCompleted: {
        rootWindow.ambiences.index = -1;
        Data.fillModel(rootWindow.ambiences, filter);
    }

    PageHeader {
        id: header
        title: page.filter == "" ? qsTr("Found ambiences") : qsTr("Ambiences for '%1'").arg(filter)
        height: 80
        width: page.width
        anchors.left: parent.left
        anchors.top: parent.top
    }

    SilicaFlickable {
        id: flickable
        property int lastActivated: -1
        property int currentIndex: -1;
        property int preloadAmount: 10
        property int loadMoreThreshold: 10
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.paddingLarge

        contentWidth: ambienceView.width
        contentHeight: parent.height - header.height - Theme.paddingLarge

        Connections {
            target: rootWindow.ambiences
            onIndexChanged: {
                var index = rootWindow.ambiences.index
                if (index > flickable.currentIndex)
                {
                    var pixels = Math.floor(index * (250 + Theme.paddingMedium))
                    if (pixels < flickable.contentWidth)
                    {
                        flickable.contentX = pixels
                    }
                }
            }
        }

        /*
        PullDownMenu {
            MenuItem {
                text: qsTr("Browse Tags")
                onClicked: pageStack.push(Qt.resolvedUrl("TagCloudPage.qml"))
            }
        }
        */

        ScrollDecorator { flickable: flickable }

        Row {
            id: ambienceView
            property int ambienceCount: Data.filteredCount();
            height: parent.height - Theme.paddingLarge
            anchors.top: header.bottom
            anchors.left: parent.left
            spacing: Theme.paddingMedium

            Repeater {
                model: rootWindow.ambiences
                delegate: Item {
                    id: ambienceItem
                    property bool loading: true
                    property bool active: rootWindow.ambiences.get(index).activated
                    property string fileName: rootWindow.ambiences.get(index).fileName

                    Component.onCompleted: {
                        if (index >= 0 && index < flickable.preloadAmount)
                        {
                            rootWindow.ambiences.get(index).activated = true;
                        }
                    }

                    onActiveChanged:
                    {
                        if (active)
                        {
                            console.debug("activated: " + fileName);
                            if (ambienceMgr.hasThumbnail(fileName))
                            {
                                console.debug("has already thumbnail");
                                previewImage.source = ambienceMgr.thumbnail(fileName);
                            }
                            else
                            {
                                ambienceMgr.saveThumbnailSucceeded.connect(thumbnailReceived);
                                ambienceMgr.saveThumbnail(rootWindow.ambiences.get(index).fullUri, fileName);
                            }
                        }
                    }

                    function thumbnailReceived(name)
                    {
                        if (fileName === name)
                        {
                            console.debug("got successfully thumbnail for: " + name);
                            ambienceMgr.saveThumbnailSucceeded.disconnect(thumbnailReceived);
                            previewImage.source = ambienceMgr.thumbnail(name);
                        }
                    }

                    width: 250
                    height: 740
                    BusyIndicator {
                        anchors.centerIn: parent
                        running: previewImage.source == ""
                    }
                    Image {
                        id: previewImage
                        width: 250
                        height: 740
                        source: ""
                        sourceSize.width: width
                        sourceSize.height: height
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            pageStack.push("AmbienceDetailPage.qml", { "url" : rootWindow.ambiences.get(index).fullUri, "name" : fileName, "mediaId" : rootWindow.ambiences.get(index).id })
                        }
                    }
                }
            }
        }

        onContentXChanged: {
            var curIndex = fromPixelsToIndex(contentX);
            if (curIndex <= currentIndex)
            {
                return;
            }
            currentIndex = curIndex;
            rootWindow.ambiences.index = currentIndex
            var nextToActivate = curIndex + loadMoreThreshold;
            console.debug("next to activate: " + nextToActivate)
            console.debug("amb count: " + Data.filteredCount())
            if (Data.filteredCount() <= nextToActivate)
            {
                nextToActivate = Data.filteredCount() - 1;
            }
            for (var i = lastActivated + 1; i <= nextToActivate; i++)
            {
                console.debug("activating: " + i);
                rootWindow.ambiences.get(i).activated = true;
            }
            lastActivated = nextToActivate;
        }

        function fromPixelsToIndex(pixels)
        {
            return Math.floor(pixels / (250 + Theme.paddingMedium));
        }
    }
}


