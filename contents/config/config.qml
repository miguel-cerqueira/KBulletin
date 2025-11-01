import QtQuick
import org.kde.plasma.configuration

ConfigModel 
{   
    ConfigCategory 
    {
        name: i18n("General")
        icon: "configure"
        source: "configGeneral.qml"
    }
    
    
    ConfigCategory 
    {
        name: i18n("Sources")
        icon: "rss"
        source: "configSources.qml"
    }


    ConfigCategory 
    {
        name: i18n("Topics")
        icon: "applications-network"
        source: "configTopics.qml"
    }


    ConfigCategory 
    {
        name: i18n("Ban Words")
        icon: "accessories-dictionary"
        source: "configBanned.qml"
    }
}