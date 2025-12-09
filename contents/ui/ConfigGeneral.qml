import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property bool cfg_showLyricsDefault: true
    property bool cfg_highlightCurrentLineDefault: true
    property int cfg_lyricsFontSizeDefault: 12
    property bool cfg_alternativeLineHeightCalculationDefault: false
    property string cfg_lyricsFontFamilyDefault: "Noto Sans"
    property int cfg_lyricsOffsetDefault: 0

    property bool cfg_showAlbumCoverDefault: true
    property bool cfg_fetchAlbumCoverHttpsDefault: false
    property int cfg_maxTitleArtistLengthDefault: 60
    property int cfg_titleFontSizeDefault: 14
    property string cfg_titleFontFamilyDefault: "Noto Sans"
    property int cfg_artistFontSizeDefault: 12
    property string cfg_artistFontFamilyDefault: "Noto Sans"

    property alias cfg_showLyrics: showLyrics.checked
    property alias cfg_highlightCurrentLine: highlightCurrentLine.checked
    property alias cfg_lyricsFontSize: lyricsFontSize.value
    property alias cfg_alternativeLineHeightCalculation: alternativeLineHeightCalculation.checked
    property alias cfg_lyricsFontFamily: lyricsFontFamily.currentText
    property alias cfg_lyricsOffset: lyricsOffset.value

    property alias cfg_showAlbumCover: showAlbumCover.checked
    property alias cfg_fetchAlbumCoverHttps: fetchAlbumCoverHttps.checked
    property alias cfg_maxTitleArtistLength: maxTitleArtistLength.value
    property alias cfg_titleFontSize: titleFontSize.value
    property alias cfg_titleFontFamily: titleFontFamily.currentText
    property alias cfg_artistFontSize: artistFontSize.value
    property alias cfg_artistFontFamily: artistFontFamily.currentText

    ColumnLayout {
        spacing: 20

        GroupBox {
            title: "Lyrics & Display"
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 10

                RowLayout {
                    CheckBox { id: showLyrics; text: "Enable Lyrics" }
                    CheckBox {
                        id: highlightCurrentLine
                        text: "Highlight Active Line"
                        enabled: showLyrics.checked
                    }
                }

                RowLayout {
                    enabled: showLyrics.checked
                    Label { text: "Sync Offset (ms):"; font.bold: true }
                    SpinBox {
                        id: lyricsOffset
                        from: -5000; to: 5000; stepSize: 100; editable: true
                    }
                    Label { text: "(Negative = Earlier)"; font.pixelSize: 10; color: "gray" }
                }

                CheckBox {
                    id: alternativeLineHeightCalculation
                    text: "Alternative scrolling"
                    visible: false
                }
            }
        }

        GroupBox {
            title: "Media Control"
            Layout.fillWidth: true

            RowLayout {
                CheckBox { id: showAlbumCover; text: "Show Album Art" }
                Label { text: "| Max Text Length:"; color: "gray" }
                SpinBox {
                    id: maxTitleArtistLength
                    from: 10; to: 200; stepSize: 5
                }
                CheckBox { id: fetchAlbumCoverHttps; visible: false }
            }
        }

        GroupBox {
            title: "Typography & Fonts"
            Layout.fillWidth: true

            GridLayout {
                columns: 3
                rowSpacing: 10
                columnSpacing: 10
                Layout.fillWidth: true

                Label { text: "Lyrics Font:"; Layout.alignment: Qt.AlignVCenter }
                ComboBox {
                    id: lyricsFontFamily
                    model: Qt.fontFamilies(); editable: true
                    Layout.fillWidth: true
                    Component.onCompleted: currentIndex = model.indexOf(plasmoid.configuration.lyricsFontFamily)
                }
                SpinBox { id: lyricsFontSize; from: 8; to: 72 }

                Label { text: "Title Font:"; Layout.alignment: Qt.AlignVCenter }
                ComboBox {
                    id: titleFontFamily
                    model: Qt.fontFamilies(); editable: true
                    Layout.fillWidth: true
                    Component.onCompleted: currentIndex = model.indexOf(plasmoid.configuration.titleFontFamily)
                }
                SpinBox { id: titleFontSize; from: 8; to: 72 }

                Label { text: "Artist Font:"; Layout.alignment: Qt.AlignVCenter }
                ComboBox {
                    id: artistFontFamily
                    model: Qt.fontFamilies(); editable: true
                    Layout.fillWidth: true
                    Component.onCompleted: currentIndex = model.indexOf(plasmoid.configuration.artistFontFamily)
                }
                SpinBox { id: artistFontSize; from: 8; to: 72 }
            }
        }
    }
}
