import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Text {
    id: textElement
    Layout.fillWidth: true
    Layout.preferredHeight: parent.height

    Layout.rightMargin: 10
    Layout.leftMargin: 10
    width: parent.width
    wrapMode: Text.WordWrap
    horizontalAlignment: Text.AlignRight
    // --------------------------------

    textFormat: Text.RichText
    text: "Lyrics"
    color: Kirigami.Theme.textColor
    font.pixelSize: plasmoid.configuration.lyricsFontSize
    font.family: plasmoid.configuration.lyricsFontFamily
    lineHeightMode: Text.FixedHeight
    lineHeight: font.pixelSize + font.pixelSize * 0.2

    property var lyrics: null
    property var spotify: null
    property var transitionDuration: 1000
    property var lineCount: 0
    property var renderedLineIndex: -2

    property int userOffset: plasmoid.configuration.lyricsOffset

    Timer {
        interval: 100
        running: spotify.ready && spotify.playing && lyrics !== null
        repeat: true
        onTriggered: {
            updateTargetPosition()
        }
    }

    NumberAnimation on y {
        id: animation
        duration: transitionDuration
        easing.type: Easing.OutCubic
    }

    onLyricsChanged: {
        updateText();
        updateTargetPosition(false);
    }

    function updateText() {
        let builder = "";
        let lines = 0;
        let currentLineIndex = getCurrentLineIndex(0);
        let highlight = plasmoid.configuration.highlightCurrentLine;

        if (lyrics !== null && lyrics) {
            lyrics.forEach((line, i) => {
                let isCurrent = (i === currentLineIndex);

                if (isCurrent && highlight) {

                    builder += `<b>${line.text}</b>`;
                } else {

                    builder += `<span style="color:#909090">${line.text}</span>`;
                }

                if (i < lyrics.length - 1) {
                    builder += "<br/>";
                }
                lines++;
            });
        }

        lineCount = lines;
        textElement.text = builder;
        renderedLineIndex = currentLineIndex;
    }

    function updateTargetPosition(animated = true) {
        let currentY = y;

        if (canUpdateText()) {
            updateText();
        }

        let targetY = calculateTargetY();

        if (textElement.parent !== null && lineCount > 0) {
            if (animated) {
                if (Math.abs(animation.to - targetY) > 1) {
                    animation.from = currentY;
                    animation.to = targetY;
                    animation.start();
                }
            } else {
                animation.stop();
                y = targetY;
            }
        } else {
            y = textElement.parent.height / 2 - textElement.lineHeight / 2;
        }
    }

    function canUpdateText() {
        let currentLineIndex = getCurrentLineIndex(0);
        if (renderedLineIndex !== currentLineIndex) {
            return true;
        }
        return false;
    }

    function getCurrentLineIndex(offset = 0) {
        if (lyrics === null || lyrics.length === 0) {
            return -1;
        }

        let magicOffset = -0.2;
        let position = (spotify.getDaemonPosition() / 1_000_000) + offset + magicOffset + (userOffset / 1000);

        let target = -1;

        for (let i = 0; i < lyrics.length; i++) {
            if (lyrics[i].time <= position) {
                target = i;
            } else {
                break;
            }
        }
        return target;
    }

    function calculateTargetY() {
        let currentLineIndex = getCurrentLineIndex(0);
        let effectiveIndex = (currentLineIndex === -1) ? 0 : currentLineIndex;

        if (!(lineCount > 0)) {
            return textElement.parent.height / 2 - textElement.lineHeight / 2;
        }

        if (plasmoid.configuration.alternativeLineHeightCalculation) {
            let lineHeight = (textElement.contentHeight) / textElement.lineCount;
            let offsetY = lineHeight * (effectiveIndex);
            return (textElement.parent.height / 2) - offsetY - (lineHeight / 2);
        }

        let lineHeight = textElement.lineHeight;

        let visibleLines = Math.floor(textElement.height / lineHeight);
        let targetLineInView = Math.floor(visibleLines * 0.4);

        let targetScrollIndex = effectiveIndex - targetLineInView;
        return -targetScrollIndex * lineHeight;
    }
}
