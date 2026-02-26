import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Kirigami.FormLayout {
    // Plasma config pages use cfg_<entryName> as the binding property name
    property alias cfg_alignment:        alignmentCombo.currentIndex
    property alias cfg_singleWindowMode: singleWindowCombo.currentIndex

    PlasmaComponents3.ComboBox {
        id: alignmentCombo
        Kirigami.FormData.label: i18n("Button alignment:")
        model: [i18n("Left"), i18n("Right")]
    }

    PlasmaComponents3.ComboBox {
        id: singleWindowCombo
        Kirigami.FormData.label: i18n("When one window is available:")
        model: [i18n("Show icon and text"), i18n("Show icon only"), i18n("Do not show")]
    }
}
