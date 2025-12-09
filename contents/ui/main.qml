import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import Qt5Compat.GraphicalEffects
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.mpris as Mpris

PlasmoidItem {
    id: widget
    Plasmoid.status: PlasmaCore.Types.HiddenStatus
    Layout.preferredWidth: row.implicitWidth
    Layout.preferredHeight: row.implicitHeight
    readonly property int volumeStep: 2

    LyricsLrcLib { id: lyricsLrcLib }

    Spotify {
        id: spotify
        onReadyChanged: {
            Plasmoid.status = spotify.ready ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
            if (spotify.ready) refreshMetadata();
            else lyricsRenderer.lyrics = [];
        }
        onPlayingChanged: {
            if (!spotify.playing && spotify.position >= spotify.length - 1000) lyricsRenderer.lyrics = [];
            timeLastPositionChanged = new Date().getTime();
        }
        onTrackChanged: {
            lyricsRenderer.lyrics = [];
            timeLastPositionChanged = new Date().getTime();
            refreshMetadata();
        }
        onArtworkUrlChanged: { refreshMetadata(); }

        function refreshMetadata() {
            if (!spotify.ready) return;
            // Güvenlik: İsimsiz arama yapma
            if (!spotify.track || spotify.track === "" || spotify.track === "Spotify" || !spotify.artist) return;

            let url = spotify.artworkUrl;
            if (url && url.startsWith("https://") && !plasmoid.configuration.fetchAlbumCoverHttps) {
                url = url.replace("https://", "http://");
            }
            artwork.source = url && url.length > 0 ? url : artwork.fallbackSource;

            let reqTrack = spotify.track;
            let reqArtist = spotify.artist;

            lyricsLrcLib.fetchLyrics(reqTrack, reqArtist, spotify.album).then(lyrics => {
                if (spotify.track === reqTrack && spotify.artist === reqArtist) {
                    lyricsRenderer.lyrics = lyrics ? lyrics : [];
                }
            });
        }
    }

    /* --- WATCHDOG 1: Kapak Resmi Koruyucu (3 sn) --- */
    Timer {
        interval: 3000; running: spotify && spotify.ready; repeat: true
        onTriggered: {
            let currentUrl = spotify.artworkUrl;
            if (currentUrl && currentUrl.length > 0) {
                if (currentUrl.startsWith("https://") && !plasmoid.configuration.fetchAlbumCoverHttps)
                    currentUrl = currentUrl.replace("https://", "http://");
                if (artwork.source == artwork.fallbackSource || artwork.source != currentUrl)
                    artwork.source = currentUrl;
            }
        }
    }

    /* --- WATCHDOG 2: Zaman Senkronizasyonu (2 sn) --- */
    /* Bu Timer, Spotify lag'e girerse widget'ın önden gitmesini engeller. */
    Timer {
        id: syncWatchdog
        interval: 2000 // 2 saniye (CPU dostu)
        running: spotify && spotify.playing
        repeat: true
        onTriggered: {
            // Sadece bu özelliğe erişmek bile Plasma'nın veri yolunu (DBus) tazelemesini sağlar.
            // Eğer Spotify takıldıysa ve biz önden gidiyorsak, bu okuma işlemi
            // 'onPositionChanged' sinyalini tetikleyerek zamanı gerçeğe eşitler.
            let syncCheck = spotify.position;

            // Ekstra: Eğer widget'ın iç saati ile sunucu saati arasında uçurum varsa manuel düzeltme tetiklenebilir
            // Ama sadece property'yi okumak genelde binding'i uyandırmak için yeterlidir.
        }
    }
    /* ------------------------------------------------ */

    Timer {
        interval: 500; running: spotify && spotify.playing; repeat: true
        onTriggered: updateProgressIndicator()
    }

    MouseArea {
        z: 100; anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: spotify && spotify.canRaise ? Qt.PointingHandCursor : Qt.ArrowCursor
        hoverEnabled: true
        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) spotify.togglePlayback();
            else if (mouse.button === Qt.LeftButton && spotify.canRaise) spotify.raise();
        }
        onWheel: (wheel) => {
            spotify.changeVolume(wheel.angleDelta.y > 0 ? volumeStep/100 : -volumeStep/100, true);
        }
    }

    RowLayout {
        id: row; anchors.fill: parent; spacing: 0; clip: true

        LyricsRenderer {
            id: lyricsRenderer
            lyrics: []
            spotify: spotify
            visible: plasmoid.configuration.showLyrics && spotify && spotify.ready && lyrics && lyrics.length > 0
            Layout.fillWidth: true
        }

        Image {
            id: artwork
            Layout.preferredWidth: parent.height; Layout.preferredHeight: parent.height
            Layout.rightMargin: 5; Layout.fillWidth: false; fillMode: Image.PreserveAspectFit
            property string fallbackSource: "../assets/icon.svg"
            source: fallbackSource
            visible: plasmoid.configuration.showAlbumCover

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Item { width: artwork.width; height: artwork.height
                    Rectangle { anchors.fill: parent; radius: 8 }
                }
            }
            Rectangle {
                id: progress; visible: spotify && spotify.ready
                x: 2; height: 3; width: artwork.width - 4; anchors.bottom: parent.bottom; color: "#282828"
                Rectangle { id: progressIndicator; anchors.bottom: parent.bottom; height: 2; width: 0; color: "#1db954" }
            }
        }

        Item {
            Layout.preferredWidth: column.implicitWidth; Layout.preferredHeight: column.implicitHeight; Layout.fillWidth: true
            ColumnLayout {
                id: column; anchors.fill: parent; spacing: 0
                Text {
                    text: spotify && spotify.ready ? truncateText(spotify.track, plasmoid.configuration.maxTitleArtistLength) : "Spotify"
                    font.weight: Font.Bold; font.pixelSize: plasmoid.configuration.titleFontSize
                    font.family: plasmoid.configuration.titleFontFamily; color: Kirigami.Theme.textColor
                    Layout.fillWidth: true; Layout.rightMargin: 20
                }
                Text {
                    text: spotify && spotify.ready ? truncateText(spotify.artist, plasmoid.configuration.maxTitleArtistLength) : "..."
                    font.pixelSize: plasmoid.configuration.artistFontSize
                    font.family: plasmoid.configuration.artistFontFamily; color: Kirigami.Theme.textColor
                    Layout.fillWidth: true; Layout.rightMargin: 20
                }
            }
        }
    }

    function updateProgressIndicator() {
        if (spotify.ready) progressIndicator.width = Math.min(1, (spotify.getDaemonPosition() / spotify.length)) * progress.width
    }
    function truncateText(text, maxLen) {
        return text && text.length > maxLen ? text.slice(0, maxLen - 3) + "..." : text;
    }
}
