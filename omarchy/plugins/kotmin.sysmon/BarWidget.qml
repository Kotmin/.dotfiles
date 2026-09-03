import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// CPU / RAM / network / free-disk readout for the Omarchy bar.
// A tiny shell sampler (sample.sh) prints raw counters once per tick; this
// widget keeps the previous sample and turns the deltas into rates.
BarWidget {
  id: root
  moduleName: "kotmin.sysmon"

  // ---------------------------------------------------------------- theme
  readonly property color fg: bar ? bar.barForeground : Color.foreground
  readonly property color dim: Qt.rgba(fg.r, fg.g, fg.b, 0.55)
  readonly property string fam: bar ? bar.fontFamily : Style.font.family

  // ---------------------------------------------------------------- config
  readonly property int intervalMs: Math.max(1000, Number(setting("intervalMs", 2000)))
  readonly property string segments: String(setting("segments", "cpu mem net disk")).toLowerCase()
  readonly property int histLen: 48
  readonly property string scriptPath: Qt.resolvedUrl("sample.sh").toString().replace(/^file:\/\//, "")

  function segEnabled(tag) { return segments.indexOf(String(tag).toLowerCase()) >= 0 }

  // ---------------------------------------------------------------- state
  property bool hasData: false
  property real cpuPct: 0
  property real memUsedG: 0
  property real memTotalG: 0
  property real diskFreeG: 0
  property real rxRate: 0            // bytes / second
  property real txRate: 0
  property var netHist: []           // rx+tx per tick, newest last

  // previous raw counters
  property double prevBusy: -1
  property double prevTotal: -1
  property double prevRx: -1
  property double prevTx: -1
  property double prevMs: 0

  function fmtRate(bps) {
    if (bps >= 1048576) return (bps / 1048576).toFixed(1) + "M"
    if (bps >= 1024) return (bps / 1024).toFixed(0) + "K"
    return Math.max(0, Math.round(bps)) + "B"
  }
  function fmtDisk(g) {
    return g >= 1024 ? (g / 1024).toFixed(1) + "T" : Math.round(g) + "G"
  }

  function ingest(text) {
    var p = String(text).trim().split(/\s+/).map(Number)
    if (p.length < 7 || !(p[1] > 0)) return
    var busy = p[0], total = p[1], memTotK = p[2], memAvK = p[3]
    var diskAv = p[4], rx = p[5], tx = p[6]
    var now = Date.now()

    memTotalG = memTotK / 1048576
    memUsedG = (memTotK - memAvK) / 1048576
    diskFreeG = diskAv / 1073741824

    if (prevTotal >= 0 && total > prevTotal) {
      var dTot = total - prevTotal
      if (dTot > 0) cpuPct = Math.max(0, Math.min(100, 100 * (busy - prevBusy) / dTot))
    }
    if (prevRx >= 0 && prevMs > 0) {
      var secs = (now - prevMs) / 1000
      if (secs > 0) {
        rxRate = Math.max(0, (rx - prevRx) / secs)
        txRate = Math.max(0, (tx - prevTx) / secs)
        var h = netHist.slice()
        h.push(rxRate + txRate)
        while (h.length > histLen) h.shift()
        netHist = h
      }
    }
    prevBusy = busy; prevTotal = total
    prevRx = rx; prevTx = tx; prevMs = now
    hasData = true
  }

  visible: !vertical && hasData
  implicitWidth: (!vertical && hasData) ? content.implicitWidth + Style.space(12) : 0
  implicitHeight: barSize

  Process {
    id: sampler
    running: false
    command: ["sh", root.scriptPath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.ingest(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (text.trim() !== "") console.warn("kotmin.sysmon", text.trim())
    }
  }

  Timer {
    interval: root.intervalMs
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!sampler.running) sampler.running = true
  }

  Row {
    id: content
    anchors.centerIn: parent
    spacing: Style.space(14)

    Seg { tag: "CPU"; value: Math.round(root.cpuPct) + "%"; valueW: Style.space(34) }
    Seg {
      tag: "MEM"
      value: root.memUsedG.toFixed(1) + "/" + root.memTotalG.toFixed(1) + "G"
      valueW: Style.space(78)
    }
    NetSeg {}
    Seg { tag: "DISK"; value: root.fmtDisk(root.diskFreeG); valueW: Style.space(40) }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    onClicked: function(m) {
      if (!root.bar) return
      if (m.button === Qt.MiddleButton) {
        if (!sampler.running) sampler.running = true
        return
      }
      root.bar.run("omarchy-launch-floating-terminal-with-presentation btop")
    }
    onEntered: if (root.bar) root.bar.showTooltip(root, "CPU · RAM used/total · network ↓↑ · free space on /")
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }

  // ------------------------------------------------------------- segments
  component Seg: Item {
    id: seg
    property string tag: ""
    property string value: ""
    property real valueW: Style.space(40)

    visible: root.segEnabled(seg.tag)
    implicitHeight: root.barSize
    implicitWidth: visible ? tagText.implicitWidth + Style.space(5) + valueW : 0
    width: implicitWidth

    Text {
      id: tagText
      text: seg.tag
      color: root.dim
      font.family: root.fam
      font.pixelSize: Style.font.caption
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
    }
    Text {
      text: seg.value
      color: root.fg
      font.family: root.fam
      font.pixelSize: Style.font.bodySmall
      width: seg.valueW
      elide: Text.ElideRight
      anchors.left: tagText.right
      anchors.leftMargin: Style.space(5)
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  component NetSeg: Item {
    id: netSeg
    visible: root.segEnabled("net")
    implicitHeight: root.barSize
    implicitWidth: visible
      ? netTag.implicitWidth + Style.space(5) + spark.width + Style.space(6) + rateText.width
      : 0
    width: implicitWidth

    Text {
      id: netTag
      text: "NET"
      color: root.dim
      font.family: root.fam
      font.pixelSize: Style.font.caption
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
    }

    Canvas {
      id: spark
      width: Style.space(46)
      height: Math.round(root.barSize * 0.6)
      antialiasing: true
      anchors.left: netTag.right
      anchors.leftMargin: Style.space(5)
      anchors.verticalCenter: parent.verticalCenter

      Connections {
        target: root
        function onNetHistChanged() { spark.requestPaint() }
        function onFgChanged() { spark.requestPaint() }
      }

      onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        var data = root.netHist
        var n = data.length
        if (n < 2) return

        var mx = 1
        for (var i = 0; i < n; i++) if (data[i] > mx) mx = data[i]
        var stepX = width / (root.histLen - 1)
        var y0 = height - 1
        var span = height - 2

        ctx.beginPath()
        ctx.moveTo(0, y0)
        for (var j = 0; j < n; j++)
          ctx.lineTo(j * stepX, y0 - (data[j] / mx) * span)
        ctx.lineTo((n - 1) * stepX, y0)
        ctx.closePath()
        ctx.fillStyle = Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.16)
        ctx.fill()

        ctx.beginPath()
        for (var k = 0; k < n; k++) {
          var x = k * stepX
          var y = y0 - (data[k] / mx) * span
          if (k === 0) ctx.moveTo(x, y)
          else ctx.lineTo(x, y)
        }
        ctx.strokeStyle = root.fg
        ctx.lineWidth = 1
        ctx.stroke()
      }
    }

    Text {
      id: rateText
      text: "↓" + root.fmtRate(root.rxRate) + "  ↑" + root.fmtRate(root.txRate)
      color: root.fg
      font.family: root.fam
      font.pixelSize: Style.font.bodySmall
      width: Style.space(96)
      anchors.left: spark.right
      anchors.leftMargin: Style.space(6)
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
