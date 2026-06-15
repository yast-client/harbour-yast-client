#include "platformapp.h"
#include "sailfishapp.h"

namespace {
    const QString THEME_ICON_PREFIX("image://theme/icon-m-");
}

QUrl PlatformApp::pathToChatFolderIcon(ChatFoldersModel::Icon icon) {
    auto pathToIcon = [](const QString &name) {
        return SailfishApp::pathTo("images/folders/icon-m-folder-" + name + ".svg");
    };

    // FIXME: decide if chat and like icons should use outline versions

    switch (icon) {
    case ChatFoldersModel::Icon::IconAll:
        return THEME_ICON_PREFIX + "outline-chat";
    case ChatFoldersModel::Icon::IconHome:
        return THEME_ICON_PREFIX + "home";
    case ChatFoldersModel::Icon::IconFavorite:
        return THEME_ICON_PREFIX + "favorite";
    case ChatFoldersModel::Icon::IconCustom:
        return THEME_ICON_PREFIX + "folder";
    case ChatFoldersModel::Icon::IconGame:
        return THEME_ICON_PREFIX + "game-controller";
    case ChatFoldersModel::Icon::IconLike:
        return THEME_ICON_PREFIX + "outline-like";
    case ChatFoldersModel::Icon::IconNote:
        return THEME_ICON_PREFIX + "media-songs";
    case ChatFoldersModel::Icon::IconWork:
        return THEME_ICON_PREFIX + "company";
    case ChatFoldersModel::Icon::IconTravel:
        return THEME_ICON_PREFIX + "airplane-mode";
    case ChatFoldersModel::Icon::IconPrivate:
        return THEME_ICON_PREFIX + "contact";
    case ChatFoldersModel::Icon::IconGroups:
        return THEME_ICON_PREFIX + "users";
    case ChatFoldersModel::Icon::IconUnmuted:
        return THEME_ICON_PREFIX + "browser-notifications";


    // possibly FIXME for these:
    case ChatFoldersModel::Icon::IconLight:
        return THEME_ICON_PREFIX + "flashlight";
    case ChatFoldersModel::Icon::IconMask:
        return THEME_ICON_PREFIX + "incognito";

    case ChatFoldersModel::Icon::IconBook:
        return pathToIcon("book");
    case ChatFoldersModel::Icon::IconLove:
        return pathToIcon("love");
    case ChatFoldersModel::Icon::IconBots:
        return pathToIcon("bots");
    case ChatFoldersModel::Icon::IconCat:
        return pathToIcon("cat");
    case ChatFoldersModel::Icon::IconChannels:
        return pathToIcon("channels");
    case ChatFoldersModel::Icon::IconCrown:
        return pathToIcon("crown");
    case ChatFoldersModel::Icon::IconFlower:
        return pathToIcon("flower");
    case ChatFoldersModel::Icon::IconAirplane:
        return pathToIcon("airplane");
    case ChatFoldersModel::Icon::IconMoney:
        return pathToIcon("money");
    case ChatFoldersModel::Icon::IconPalette:
        return pathToIcon("palette");
    case ChatFoldersModel::Icon::IconParty:
        return pathToIcon("party");
    case ChatFoldersModel::Icon::IconSetup:
        return pathToIcon("setup");
    case ChatFoldersModel::Icon::IconSport:
        return pathToIcon("sport");
    case ChatFoldersModel::Icon::IconStudy:
        return pathToIcon("study");
    case ChatFoldersModel::Icon::IconTrade:
        return pathToIcon("trade");
    case ChatFoldersModel::Icon::IconUnread:
        return pathToIcon("unread"); // or icon-m-notifications?
    }

    return QString();
}
