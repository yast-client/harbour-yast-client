#include "movieitem.h"

#include <QQmlFile>
#include <QSGSimpleTextureNode>
#include <QQuickWindow>

#define DEBUG_MODULE MovieItem
#include "debuglog.h"
#define LOG_(x) LOG(movie->fileName() << x)

MovieItem::MovieItem()
    : QQuickItem(),
      movie(new QMovie(this)),
      paused(false)
{
    setFlag(ItemHasContents, true);

    connect(movie, &QMovie::frameChanged, this, &MovieItem::update);
    connect(movie, &QMovie::frameChanged, this, &MovieItem::frameChanged);
    connect(movie, &QMovie::started, this, &MovieItem::updateSize);
    connect(movie, &QMovie::started, this, &MovieItem::frameChanged);
    connect(movie, &QMovie::stateChanged, this, &MovieItem::pausedChanged);
}

QUrl MovieItem::source() const {
    return movie->fileName();
}

void MovieItem::setSource(QUrl source) {
    const QString fileName = QQmlFile::urlToLocalFileOrQrc(source);

    if (movie->fileName() != fileName) {
        movie->setFileName(fileName);
        emit sourceChanged();

        if (movie->isValid()) {
            movie->start();
            movie->setPaused(paused);
            emit frameCountChanged();
            updateSize();
            update();
            LOG_(sourceSize() << movie->state());
        }
    }
}

void MovieItem::setPaused(bool paused) {
    if (this->paused != paused) {
        LOG_((paused ? "Pausing" : "Unpausing") << "previous state" << movie->state());
        this->paused = paused;
        emit pausedChanged();

        movie->setPaused(paused);
        LOG_(movie->state());
    }
}

QSize MovieItem::sourceSize() const {
    const QSize scaledSize = movie->scaledSize();
    return scaledSize.isValid() ? scaledSize : movie->currentImage().size();
}

void MovieItem::setSourceSize(QSize size) {
    if (movie->scaledSize() != size) {
        movie->setScaledSize(size);
        updateSize();
        LOG_("New source size" << sourceSize());
    }
}

int MovieItem::currentFrame() const {
    return movie->currentFrameNumber();
}

void MovieItem::setCurrentFrame(int frame) {
    movie->jumpToFrame(frame);
}

int MovieItem::frameCount() const {
    return movie->frameCount();
}

bool MovieItem::cache() const {
    return movie->cacheMode() == QMovie::CacheAll;
}

void MovieItem::setCache(bool cache) {
    QMovie::CacheMode mode = cache ? QMovie::CacheAll : QMovie::CacheNone;
    if (movie->cacheMode() != mode) {
        movie->setCacheMode(mode);
        emit cacheChanged();
    }
}

void MovieItem::updateSize() {
    const QSize size = sourceSize();
    if (size.isValid()) {
        setImplicitSize(size.width(), size.height());
        emit sourceSizeChanged();
    }
}

QSGNode *MovieItem::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData*) {
    QImage frame = movie->currentImage();

    if (frame.isNull()) {
        delete oldNode;
        return nullptr;
    }

    QSGSimpleTextureNode *textureNode = static_cast<QSGSimpleTextureNode *>(oldNode);
    if (!textureNode) {
        textureNode = new QSGSimpleTextureNode();
        textureNode->setOwnsTexture(true);
    }

    QQuickWindow *window = this->window();
    if (window) {
        QSGTexture *texture = window->createTextureFromImage(frame);
        textureNode->setTexture(texture);
        textureNode->setRect(boundingRect());
    }

    return textureNode;
}
