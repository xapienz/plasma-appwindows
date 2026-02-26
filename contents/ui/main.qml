import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    // Maximum number of rows to show
    readonly property int maxRows: 2
    // Width of each window button
    readonly property int buttonWidth: 160

    preferredRepresentation: fullRepresentation

    // -----------------------------------------------------------------------
    // Task model — all windows on the current activity, across all desktops
    // -----------------------------------------------------------------------
    TaskManager.TasksModel {
        id: tasksModel
        filterByActivity: true
        filterByVirtualDesktop: false
        filterMinimized: false
        groupMode: TaskManager.TasksModel.GroupDisabled
        sortMode: TaskManager.TasksModel.SortActivity
        activity: activityInfo.currentActivity
    }

    TaskManager.ActivityInfo {
        id: activityInfo
    }

    // -----------------------------------------------------------------------
    // Filtered list — only windows belonging to the currently active app
    // -----------------------------------------------------------------------
    ListModel {
        id: filteredModel
    }

    // The AppId of the app whose windows we are showing.
    // Kept on its last valid value so the widget doesn't go blank when
    // the user briefly focuses the desktop or a launcher.
    property string currentAppId: ""

    function updateCurrentApp() {
        if (!tasksModel.activeTask.valid) return
        var appId = tasksModel.data(tasksModel.activeTask,
                                    TaskManager.AbstractTasksModel.AppId) || ""
        if (appId && appId !== currentAppId) {
            currentAppId = appId
        }
    }

    function rebuildModel() {
        filteredModel.clear()
        if (!currentAppId) return

        for (var i = 0; i < tasksModel.rowCount(); i++) {
            var idx = tasksModel.index(i, 0)
            var appId = tasksModel.data(idx,
                            TaskManager.AbstractTasksModel.AppId) || ""
            if (appId !== currentAppId) continue

            filteredModel.append({
                "taskRow":            i,
                "windowTitle":        tasksModel.data(idx, TaskManager.AbstractTasksModel.Display) || "",
                "isActive":           tasksModel.data(idx, TaskManager.AbstractTasksModel.IsActive) || false,
                "isMinimized":        tasksModel.data(idx, TaskManager.AbstractTasksModel.IsMinimized) || false,
                "isDemandingAttention": tasksModel.data(idx, TaskManager.AbstractTasksModel.IsDemandingAttention) || false
            })
        }
    }

    Connections {
        target: tasksModel
        function onActiveTaskChanged() { updateCurrentApp(); rebuildModel() }
        function onDataChanged()       { rebuildModel() }
        function onRowsInserted()      { rebuildModel() }
        function onRowsRemoved()       { rebuildModel() }
        function onModelReset()        { updateCurrentApp(); rebuildModel() }
        function onLayoutChanged()     { rebuildModel() }
    }

    Component.onCompleted: { updateCurrentApp(); rebuildModel() }

    // -----------------------------------------------------------------------
    // Representation
    // -----------------------------------------------------------------------
    fullRepresentation: Item {
        id: container

        // Layout geometry
        readonly property int count:    filteredModel.count
        // Use 1 row when ≤ maxRows windows fit side-by-side, 2 rows otherwise
        readonly property int rows:     (count > 0 && count > root.maxRows) ? root.maxRows : (count > 0 ? 1 : 1)
        readonly property int cols:     count > 0 ? Math.ceil(count / rows) : 1
        readonly property int btnH:     height > 0 ? Math.floor(height / rows) : Kirigami.Units.gridUnit * 2
        // Icon-only with a single window → square button; otherwise full width
        readonly property int btnW:     (count === 1 && singleWindowMode === 1) ? btnH : root.buttonWidth

        // 0=Left  1=Right
        readonly property int alignment:        Plasmoid.configuration.alignment
        // 0=icon+text  1=icon only  2=hidden
        readonly property int singleWindowMode: Plasmoid.configuration.singleWindowMode

        // Hide the whole widget when there is exactly one window and mode is "do not show"
        visible:              !(count === 1 && singleWindowMode === 2)
        Layout.preferredWidth: (count === 1 && singleWindowMode === 2) ? 0 : cols * btnW

        // Left: compact (only as wide as the buttons).
        // Right: fill available panel space so there is room to align within.
        Layout.minimumWidth: btnW
        Layout.fillWidth:    alignment === 1

        implicitWidth:  Layout.preferredWidth
        implicitHeight: rows * Kirigami.Units.gridUnit * 2

        // Buttons — each delegate is positioned explicitly so incomplete
        // last rows can be shifted for center/right alignment.
        Item {
            id: windowGrid
            height: parent.height
            width:  container.cols * container.btnW

            // Shift the whole block within the container
            x: container.alignment === 1 ? Math.max(0, parent.width - width) : 0

            Repeater {
                model: filteredModel

                delegate: Item {
                    id: delegate

                    required property int     index   // Repeater index → used for position
                    required property int     taskRow
                    required property string  windowTitle
                    required property bool    isActive
                    required property bool    isMinimized
                    required property bool    isDemandingAttention

                    // ---- per-delegate position ----
                    readonly property int naturalRow: Math.floor(index / container.cols)
                    readonly property int naturalCol: index % container.cols

                    // Items that land in the last row
                    readonly property int lastRowCount:
                        filteredModel.count - (container.rows - 1) * container.cols

                    // Pixel x: full rows fill edge-to-edge; last row shifts right when right-aligned.
                    x: {
                        var base = naturalCol * container.btnW
                        if (naturalRow < container.rows - 1) return base   // full row — no shift
                        if (container.alignment !== 1) return base         // left — no shift
                        var gap = (container.cols - lastRowCount) * container.btnW
                        return gap + base                                   // right
                    }
                    y:      naturalRow * container.btnH
                    width:  container.btnW
                    height: container.btnH

                    HoverHandler { id: hoverHandler }

                    // Background — declared first so it renders beneath the content
                    Rectangle {
                        anchors {
                            fill:    parent
                            margins: 2
                        }
                        radius: Kirigami.Units.cornerRadius

                        color: {
                            if (delegate.isActive) {
                                return Qt.rgba(Kirigami.Theme.highlightColor.r,
                                               Kirigami.Theme.highlightColor.g,
                                               Kirigami.Theme.highlightColor.b, 0.25)
                            }
                            if (hoverHandler.hovered) {
                                return Qt.rgba(Kirigami.Theme.textColor.r,
                                               Kirigami.Theme.textColor.g,
                                               Kirigami.Theme.textColor.b, 0.08)
                            }
                            return "transparent"
                        }

                        border.color: delegate.isActive ? Kirigami.Theme.highlightColor : "transparent"
                        border.width: delegate.isActive ? 1 : 0
                    }

                    // Icon + label — declared after Rectangle so it renders on top
                    RowLayout {
                        readonly property bool iconOnly:
                            filteredModel.count === 1 && container.singleWindowMode === 1

                        // Icon-only: centre in the (square) button.
                        // Normal:    stretch left-to-right with side padding.
                        anchors.verticalCenter:   parent.verticalCenter
                        anchors.horizontalCenter: iconOnly ? parent.horizontalCenter : undefined
                        anchors.left:             iconOnly ? undefined : parent.left
                        anchors.right:            iconOnly ? undefined : parent.right
                        anchors.leftMargin:       Kirigami.Units.smallSpacing * 2
                        anchors.rightMargin:      Kirigami.Units.smallSpacing * 2
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            readonly property int maxSize: Math.max(8, delegate.height - Kirigami.Units.smallSpacing * 2)
                            Layout.preferredWidth:  Math.min(Kirigami.Units.iconSizes.small, maxSize)
                            Layout.preferredHeight: Math.min(Kirigami.Units.iconSizes.small, maxSize)
                            Layout.alignment:       Qt.AlignVCenter
                            animated:               false
                            opacity:                delegate.isMinimized ? 0.5 : 1.0
                            source: tasksModel.data(
                                tasksModel.index(delegate.taskRow, 0),
                                Qt.DecorationRole
                            )
                        }

                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            visible:          !(filteredModel.count === 1 && container.singleWindowMode === 1)
                            text:             delegate.windowTitle
                            elide:            Text.ElideRight
                            opacity:          delegate.isMinimized ? 0.6 : 1.0
                            color:            delegate.isActive
                                                  ? Kirigami.Theme.highlightColor
                                                  : Kirigami.Theme.textColor
                            font.weight:      delegate.isDemandingAttention ? Font.Bold : Font.Normal
                        }
                    }

                    // Click handler
                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: {
                            var modelIdx = tasksModel.index(delegate.taskRow, 0)
                            if (delegate.isActive && !delegate.isMinimized) {
                                tasksModel.requestToggleMinimized(modelIdx)
                            } else {
                                tasksModel.requestActivate(modelIdx)
                            }
                        }
                    }
                } // delegate
            } // Repeater
        } // Item (windowGrid)

        // Placeholder shown when no app is being tracked
        PlasmaComponents3.Label {
            anchors.centerIn: parent
            visible:  filteredModel.count === 0
            text:     i18n("No active app")
            opacity:  0.4
        }
    }
}
