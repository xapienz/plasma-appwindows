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
        readonly property int btnW:     root.buttonWidth

        // Tell the Plasma panel how much space we need via Layout attached props.
        // implicitWidth alone is not enough — the panel uses Qt Layouts.
        Layout.preferredWidth:  cols * btnW
        Layout.minimumWidth:    btnW
        Layout.fillWidth:       false

        implicitWidth:  Layout.preferredWidth
        implicitHeight: rows * Kirigami.Units.gridUnit * 2

        // Grid of window buttons
        Grid {
            anchors.fill: parent
            columns:      Math.max(1, container.cols)
            rowSpacing:   0
            columnSpacing: 0

            Repeater {
                model: filteredModel

                delegate: Item {
                    id: delegate

                    required property int     taskRow
                    required property string  windowTitle
                    required property bool    isActive
                    required property bool    isMinimized
                    required property bool    isDemandingAttention

                    width:  container.btnW
                    height: container.btnH

                    HoverHandler { id: hoverHandler }

                    // Tooltip with full window title
                    QQC2.ToolTip {
                        visible: hoverHandler.hovered
                        text:    delegate.windowTitle
                        delay:   700
                    }

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
                        anchors {
                            left:           parent.left
                            right:          parent.right
                            leftMargin:     Kirigami.Units.smallSpacing * 2
                            rightMargin:    Kirigami.Units.smallSpacing * 2
                            verticalCenter: parent.verticalCenter
                        }
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
        } // Grid

        // Placeholder shown when no app is being tracked
        PlasmaComponents3.Label {
            anchors.centerIn: parent
            visible:  filteredModel.count === 0
            text:     i18n("No active app")
            opacity:  0.4
        }
    }
}
