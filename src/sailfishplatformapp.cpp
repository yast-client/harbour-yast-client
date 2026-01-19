#include "platformapp.h"
#include "sailfishapp.h"

QUrl PlatformApp::pathTo(const QString &filename) {
    return SailfishApp::pathTo(filename);
}
