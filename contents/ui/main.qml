import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami


PlasmoidItem 
{
    id: main

    readonly property bool inPanel: 
    (
        plasmoid.location === PlasmaCore.Types.TopEdge    ||
        plasmoid.location === PlasmaCore.Types.RightEdge  ||
        plasmoid.location === PlasmaCore.Types.BottomEdge ||
        plasmoid.location === PlasmaCore.Types.LeftEdge
    )
    

    preferredRepresentation: inPanel ? plasmoid.compactRepresentation : plasmoid.fullRepresentation
    compactRepresentation:   CompactRepresentation {}
    fullRepresentation:      FullRepresentation {}
}